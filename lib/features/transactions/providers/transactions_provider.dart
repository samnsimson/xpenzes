import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';
import '../../../core/network/api_client.dart';
import '../../auth/providers/auth_provider.dart';

final transactionsProvider =
    AsyncNotifierProvider<TransactionsNotifier, List<TransactionModel>>(
      TransactionsNotifier.new,
    );

/// Whether recurring income entries are hidden from the transaction list.
/// Off by default — recurring income is shown like any other transaction.
final hideRecurringIncomeProvider = StateProvider<bool>((ref) => false);

class TransactionsNotifier extends AsyncNotifier<List<TransactionModel>> {
  @override
  Future<List<TransactionModel>> build() async {
    final user = await ref.watch(authProvider.future);
    if (user == null) return [];
    final json = await apiClient.get('/transactions') as List<dynamic>;
    return json
        .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Adds a transaction. If it's recurring, the server expands it into
  /// its future occurrences and returns every created row.
  Future<void> addTransaction(TransactionModel transaction) async {
    final json =
        await apiClient.post('/transactions', body: transaction.toCreateJson())
            as List<dynamic>;
    final inserted = json
        .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
    state = AsyncData([...inserted, ...?state.value]);
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    final json =
        await apiClient.patch(
              '/transactions/${transaction.id}',
              body: {
                'title': transaction.title,
                'amount': transaction.amount,
                'category': transaction.category,
                'date': transaction.date.toIso8601String(),
                'notes': transaction.notes,
              },
            )
            as Map<String, dynamic>;
    final updated = TransactionModel.fromJson(json);
    state = AsyncData(
      state.value?.map((t) => t.id == updated.id ? updated : t).toList() ?? [],
    );
  }

  Future<void> deleteTransaction(String id) async {
    await apiClient.delete('/transactions/$id');
    state = AsyncData(state.value?.where((t) => t.id != id).toList() ?? []);
  }
}
