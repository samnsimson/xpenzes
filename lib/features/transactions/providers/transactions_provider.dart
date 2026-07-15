import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction_model.dart';
import '../utils/recurrence.dart';
import '../../../core/database/database_helper.dart';
import '../../auth/providers/auth_provider.dart';

final transactionsProvider =
    AsyncNotifierProvider<TransactionsNotifier, List<TransactionModel>>(
  TransactionsNotifier.new,
);

/// Whether recurring income entries are hidden from the transaction list.
/// Off by default — recurring income is shown like any other transaction.
final hideRecurringIncomeProvider = StateProvider<bool>((ref) => false);

class TransactionsNotifier extends AsyncNotifier<List<TransactionModel>> {
  static const _uuid = Uuid();

  @override
  Future<List<TransactionModel>> build() async {
    final user = await ref.watch(authProvider.future);
    if (user?.id == null) return [];
    return DatabaseHelper().getTransactionsByUserId(user!.id!);
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    if (transaction.isRecurring && transaction.recurrenceFrequency != null) {
      final groupId = _uuid.v4();
      final occurrences = <TransactionModel>[];
      var date = transaction.date;
      for (var i = 0; i < kRecurringOccurrenceCount; i++) {
        occurrences.add(transaction.copyWith(
          date: date,
          recurringGroupId: groupId,
        ));
        date = nextRecurrenceDate(date, transaction.recurrenceFrequency!);
      }
      final ids = await DatabaseHelper().insertTransactions(occurrences);
      final inserted = [
        for (var i = 0; i < occurrences.length; i++)
          occurrences[i].copyWith(id: ids[i]),
      ];
      state = AsyncData([...inserted, ...?state.value]);
    } else {
      final id = await DatabaseHelper().insertTransaction(transaction);
      state = AsyncData([transaction.copyWith(id: id), ...?state.value]);
    }
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    await DatabaseHelper().updateTransaction(transaction);
    state = AsyncData(
      state.value?.map((t) => t.id == transaction.id ? transaction : t).toList() ??
          [],
    );
  }

  Future<void> deleteTransaction(int id) async {
    await DatabaseHelper().deleteTransaction(id);
    state = AsyncData(
      state.value?.where((t) => t.id != id).toList() ?? [],
    );
  }
}
