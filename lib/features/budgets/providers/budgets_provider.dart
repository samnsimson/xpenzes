import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/budget_model.dart';
import '../../../core/network/api_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../../transactions/providers/transactions_provider.dart';

final budgetsProvider =
    AsyncNotifierProvider<BudgetsNotifier, List<BudgetModel>>(
      BudgetsNotifier.new,
    );

class BudgetsNotifier extends AsyncNotifier<List<BudgetModel>> {
  Future<List<BudgetModel>> _fetch() async {
    final json = await apiClient.get('/budgets') as List<dynamic>;
    return json
        .map((e) => BudgetModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<BudgetModel>> build() async {
    final user = await ref.watch(authProvider.future);
    if (user == null) return [];
    // "spent"/"status" per budget are computed server-side from
    // transactions, so re-fetch whenever the transaction list changes.
    ref.watch(transactionsProvider);
    return _fetch();
  }

  Future<void> setBudget(String category, double monthlyLimit) async {
    await apiClient.put(
      '/budgets/$category',
      body: {'monthly_limit': monthlyLimit},
    );
    state = AsyncData(await _fetch());
  }

  Future<void> deleteBudget(String id) async {
    await apiClient.delete('/budgets/$id');
    state = AsyncData(state.value?.where((b) => b.id != id).toList() ?? []);
  }
}
