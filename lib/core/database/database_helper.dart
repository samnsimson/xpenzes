import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import '../../features/auth/models/user_model.dart';
import '../../features/transactions/models/transaction_model.dart';
import '../../features/transactions/utils/recurrence.dart';
import '../../features/budgets/models/budget_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'xpenzes.db');
    return openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        currency TEXT NOT NULL DEFAULT 'USD',
        is_onboarded INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await _createTransactionsTable(db);
    await _createBudgetsTable(db);
  }

  Future<void> _createBudgetsTable(Database db) async {
    await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        category TEXT NOT NULL,
        monthly_limit REAL NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        UNIQUE(user_id, category)
      )
    ''');
  }

  Future<void> _createTransactionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        notes TEXT,
        is_recurring INTEGER NOT NULL DEFAULT 0,
        recurrence_frequency TEXT,
        recurring_group_id TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Legacy tables from v1, kept intact for reference; data below is copied
      // into the new unified `transactions` table.
      await db.execute('''
        CREATE TABLE IF NOT EXISTS incomes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          source TEXT NOT NULL,
          amount REAL NOT NULL,
          frequency TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS expenses (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          title TEXT NOT NULL,
          amount REAL NOT NULL,
          category TEXT NOT NULL,
          date TEXT NOT NULL,
          notes TEXT,
          created_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        )
      ''');

      await _createTransactionsTable(db);
      await _migrateLegacyDataToTransactions(db);
    }
    if (oldVersion < 3) {
      await _createBudgetsTable(db);
    }
  }

  Future<void> _migrateLegacyDataToTransactions(Database db) async {
    const uuid = Uuid();
    final now = DateTime.now();
    final rows = <Map<String, dynamic>>[];

    final expenseRows = await db.query('expenses');
    for (final e in expenseRows) {
      rows.add({
        'user_id': e['user_id'],
        'type': 'expense',
        'title': e['title'],
        'amount': e['amount'],
        'category': e['category'],
        'date': e['date'],
        'notes': e['notes'],
        'is_recurring': 0,
        'recurrence_frequency': null,
        'recurring_group_id': null,
        'created_at': e['created_at'],
      });
    }

    final incomeRows = await db.query('incomes');
    for (final i in incomeRows) {
      final frequency = i['frequency'] as String;
      final groupId = uuid.v4();
      var date = DateTime.parse(i['created_at'] as String);

      rows.add({
        'user_id': i['user_id'],
        'type': 'income',
        'title': i['source'],
        'amount': i['amount'],
        'category': i['source'],
        'date': date.toIso8601String(),
        'notes': null,
        'is_recurring': 1,
        'recurrence_frequency': frequency,
        'recurring_group_id': groupId,
        'created_at': i['created_at'],
      });

      // Generate future occurrences up to 12 months ahead of today so
      // recurring income keeps appearing without the user re-entering it.
      final horizon = DateTime(now.year, now.month + 12, now.day);
      date = nextRecurrenceDate(date, frequency);
      while (date.isBefore(horizon)) {
        rows.add({
          'user_id': i['user_id'],
          'type': 'income',
          'title': i['source'],
          'amount': i['amount'],
          'category': i['source'],
          'date': date.toIso8601String(),
          'notes': null,
          'is_recurring': 1,
          'recurrence_frequency': frequency,
          'recurring_group_id': groupId,
          'created_at': i['created_at'],
        });
        date = nextRecurrenceDate(date, frequency);
      }
    }

    final batch = db.batch();
    for (final row in rows) {
      batch.insert('transactions', row);
    }
    await batch.commit(noResult: true);
  }

  // ── User ────────────────────────────────────────────────────────────────────

  Future<int> insertUser(UserModel user) async {
    final db = await database;
    return db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserModel?> getUserByEmail(String email) async {
    final db = await database;
    final rows = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    return rows.isEmpty ? null : UserModel.fromMap(rows.first);
  }

  Future<UserModel?> getLastUser() async {
    final db = await database;
    final rows = await db.query('users', orderBy: 'created_at DESC', limit: 1);
    return rows.isEmpty ? null : UserModel.fromMap(rows.first);
  }

  Future<void> updateUser(UserModel user) async {
    final db = await database;
    await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // ── Transactions ────────────────────────────────────────────────────────────

  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await database;
    return db.insert('transactions', transaction.toMap());
  }

  Future<List<int>> insertTransactions(
    List<TransactionModel> transactions,
  ) async {
    final db = await database;
    final ids = <int>[];
    await db.transaction((txn) async {
      for (final t in transactions) {
        ids.add(await txn.insert('transactions', t.toMap()));
      }
    });
    return ids;
  }

  Future<List<TransactionModel>> getTransactionsByUserId(int userId) async {
    final db = await database;
    final rows = await db.query(
      'transactions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
    return rows.map(TransactionModel.fromMap).toList();
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    final db = await database;
    await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<void> deleteTransaction(int id) async {
    final db = await database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // ── Budgets ─────────────────────────────────────────────────────────────────

  Future<void> upsertBudget(BudgetModel budget) async {
    final db = await database;
    await db.insert(
      'budgets',
      budget.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<BudgetModel>> getBudgetsByUserId(int userId) async {
    final db = await database;
    final rows = await db.query(
      'budgets',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return rows.map(BudgetModel.fromMap).toList();
  }

  Future<void> deleteBudget(int id) async {
    final db = await database;
    await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }
}
