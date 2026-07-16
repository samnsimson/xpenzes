import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/budget_model.dart';
import '../providers/budgets_provider.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    final budgetsAsync = ref.watch(budgetsProvider);
    final symbol = AppConstants.currencies[user?.currency ?? 'USD'] ?? '\$';

    final budgets = budgetsAsync.value ?? [];
    final budgetByCategory = {for (final b in budgets) b.category: b};

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Budgets')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'Set a monthly limit per category to get an early warning '
            'before you overspend.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ...AppConstants.expenseCategories.map((category) {
            final budget = budgetByCategory[category];
            return _BudgetRow(
              category: category,
              spent: budget?.spent ?? 0,
              budget: budget,
              symbol: symbol,
              onTap: () => _showEditSheet(context, category, budget, symbol),
            );
          }),
        ],
      ),
    );
  }

  void _showEditSheet(
    BuildContext context,
    String category,
    BudgetModel? existing,
    String symbol,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BudgetEditSheet(
        category: category,
        existing: existing,
        symbol: symbol,
      ),
    );
  }
}

class _BudgetRow extends StatelessWidget {
  final String category;
  final double spent;
  final BudgetModel? budget;
  final String symbol;
  final VoidCallback onTap;

  const _BudgetRow({
    required this.category,
    required this.spent,
    required this.budget,
    required this.symbol,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppConstants.categoryColors[category] ?? AppColors.primary;
    final icon = AppConstants.categoryIcons[category] ?? Icons.more_horiz;
    final hasBudget = budget != null;
    final progress = hasBudget
        ? (spent / budget!.monthlyLimit).clamp(0.0, 1.0)
        : 0.0;
    final progressColor = !hasBudget
        ? AppColors.textSecondary
        : progress >= 1.0
        ? AppColors.error
        : progress >= 0.8
        ? AppColors.warning
        : AppColors.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (hasBudget) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: AppColors.border,
                            color: progressColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$symbol${spent.toStringAsFixed(2)} of '
                          '$symbol${budget!.monthlyLimit.toStringAsFixed(2)}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ] else
                        Text(
                          'No budget set · Tap to add',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Budget edit bottom sheet ──────────────────────────────────────────────────

class _BudgetEditSheet extends ConsumerStatefulWidget {
  final String category;
  final BudgetModel? existing;
  final String symbol;

  const _BudgetEditSheet({
    required this.category,
    required this.existing,
    required this.symbol,
  });

  @override
  ConsumerState<_BudgetEditSheet> createState() => _BudgetEditSheetState();
}

class _BudgetEditSheetState extends ConsumerState<_BudgetEditSheet> {
  static const _defaultMax = 2000.0;

  late double _amount;
  late final TextEditingController _amountCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _amount = widget.existing?.monthlyLimit ?? 100.0;
    _amountCtrl = TextEditingController(text: _amount.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  double get _sliderMax => _amount > _defaultMax ? _amount * 1.2 : _defaultMax;

  void _onSliderChanged(double value) {
    setState(() {
      _amount = value;
      _amountCtrl.text = value.toStringAsFixed(2);
      _amountCtrl.selection = TextSelection.collapsed(
        offset: _amountCtrl.text.length,
      );
    });
  }

  void _onTextChanged(String text) {
    final parsed = double.tryParse(text.trim());
    if (parsed != null && parsed >= 0) {
      setState(() => _amount = parsed);
    }
  }

  Future<void> _save() async {
    if (_amount <= 0 || _isSaving) return;
    setState(() => _isSaving = true);
    await ref.read(budgetsProvider.notifier).setBudget(widget.category, _amount);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _remove() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    await ref.read(budgetsProvider.notifier).deleteBudget(widget.existing!.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final sliderMax = _sliderMax;
    final sliderValue = _amount.clamp(0.0, sliderMax);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              '${widget.category} Budget',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Monthly limit',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: _onTextChanged,
              decoration: InputDecoration(
                hintText: '0.00',
                prefixIcon: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    widget.symbol,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 0),
              ),
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.border,
                thumbColor: AppColors.primary,
                overlayColor: AppColors.primary.withOpacity(0.15),
              ),
              child: Slider(
                value: sliderValue,
                min: 0,
                max: sliderMax,
                divisions: sliderMax.round().clamp(1, 1000000),
                onChanged: _onSliderChanged,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${widget.symbol}0',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '${widget.symbol}${sliderMax.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Save Budget'),
              ),
            ),
            if (widget.existing != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _isSaving ? null : _remove,
                  child: Text(
                    'Remove Budget',
                    style: GoogleFonts.inter(color: AppColors.error),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
