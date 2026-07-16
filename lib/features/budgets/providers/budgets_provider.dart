import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/budget_model.dart';
import '../../../core/database/database_helper.dart';
import '../../auth/providers/auth_provider.dart';

final budgetsProvider =
    AsyncNotifierProvider<BudgetsNotifier, List<BudgetModel>>(
      BudgetsNotifier.new,
    );

class BudgetsNotifier extends AsyncNotifier<List<BudgetModel>> {
  @override
  Future<List<BudgetModel>> build() async {
    final user = await ref.watch(authProvider.future);
    if (user?.id == null) return [];
    return DatabaseHelper().getBudgetsByUserId(user!.id!);
  }

  Future<void> setBudget(BudgetModel budget) async {
    await DatabaseHelper().upsertBudget(budget);
    final user = await ref.read(authProvider.future);
    if (user?.id == null) return;
    state = AsyncData(await DatabaseHelper().getBudgetsByUserId(user!.id!));
  }

  Future<void> deleteBudget(int id) async {
    await DatabaseHelper().deleteBudget(id);
    state = AsyncData(state.value?.where((b) => b.id != id).toList() ?? []);
  }
}
