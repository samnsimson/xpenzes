import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/transaction_model.dart';
import '../providers/transactions_provider.dart';

class AddTransactionSheet extends ConsumerStatefulWidget {
  final TransactionModel? existing;
  final TransactionType initialType;

  const AddTransactionSheet({
    super.key,
    this.existing,
    this.initialType = TransactionType.expense,
  });

  @override
  ConsumerState<AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  late final _titleCtrl = TextEditingController(text: widget.existing?.title);
  late final _amountCtrl = TextEditingController(
    text: widget.existing != null
        ? widget.existing!.amount.toStringAsFixed(2)
        : '',
  );
  late final _notesCtrl =
      TextEditingController(text: widget.existing?.notes ?? '');

  late TransactionType _type = widget.existing?.type ?? widget.initialType;
  late String _category = widget.existing?.category ?? _categoriesFor(_type).first;
  late DateTime _date = widget.existing?.date ?? DateTime.now();
  late bool _isRecurring = widget.existing?.isRecurring ?? false;
  late String _frequency = widget.existing?.recurrenceFrequency ??
      AppConstants.recurrenceFrequencies[2];
  bool _isSaving = false;

  bool get _isEditing => widget.existing != null;

  static List<String> _categoriesFor(TransactionType type) =>
      type == TransactionType.income
          ? AppConstants.incomeSources
          : AppConstants.expenseCategories;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _setType(TransactionType type) {
    setState(() {
      _type = type;
      final categories = _categoriesFor(type);
      if (!categories.contains(_category)) _category = categories.first;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx)
              .colorScheme
              .copyWith(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.trim());

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(_snackBar('Please enter a title.'));
      return;
    }
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(_snackBar('Please enter a valid amount.'));
      return;
    }

    setState(() => _isSaving = true);

    final transaction = TransactionModel(
      id: widget.existing?.id,
      type: _type,
      title: title,
      amount: amount,
      category: _category,
      date: _date,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      isRecurring: _isRecurring,
      recurrenceFrequency: _isRecurring ? _frequency : null,
      recurringGroupId: widget.existing?.recurringGroupId,
    );

    if (_isEditing) {
      await ref.read(transactionsProvider.notifier).updateTransaction(transaction);
    } else {
      await ref.read(transactionsProvider.notifier).addTransaction(transaction);
    }

    if (mounted) Navigator.pop(context);
  }

  SnackBar _snackBar(String msg) => SnackBar(
        content: Text(msg, style: GoogleFonts.inter()),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      );

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;
    final symbol = AppConstants.currencies[user?.currency ?? 'USD'] ?? '\$';
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final categories = _categoriesFor(_type);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
              _isEditing
                  ? 'Edit Transaction'
                  : 'Add Transaction',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            // Type toggle
            Row(
              children: [
                Expanded(
                  child: _TypeToggleButton(
                    label: 'Expense',
                    icon: Icons.trending_down_rounded,
                    isSelected: _type == TransactionType.expense,
                    color: AppColors.secondary,
                    onTap: () => _setType(TransactionType.expense),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TypeToggleButton(
                    label: 'Income',
                    icon: Icons.trending_up_rounded,
                    isSelected: _type == TransactionType.income,
                    color: AppColors.success,
                    onTap: () => _setType(TransactionType.income),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Title',
                prefixIcon: Icon(Icons.receipt_long_rounded,
                    color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: '0.00',
                prefixIcon: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    symbol,
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
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        color: AppColors.textSecondary, size: 18),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('MMMM d, yyyy').format(_date),
                      style: GoogleFonts.inter(
                          fontSize: 14, color: AppColors.textPrimary),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textSecondary, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _type == TransactionType.income ? 'Source' : 'Category',
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  final cat = categories[i];
                  final color = _type == TransactionType.income
                      ? AppColors.success
                      : AppConstants.categoryColors[cat] ?? AppColors.primary;
                  final isSelected = cat == _category;
                  return GestureDetector(
                    onTap: () => setState(() => _category = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? color : color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        cat,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : color,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            // Recurring toggle
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Repeats',
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                  ),
                ),
                Switch(
                  value: _isRecurring,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _isRecurring = v),
                ),
              ],
            ),
            if (_isRecurring) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.recurrenceFrequencies.map((f) {
                  final isSelected = f == _frequency;
                  return GestureDetector(
                    onTap: () => setState(() => _frequency = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: Text(f,
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary)),
                    ),
                  );
                }).toList(),
              ),
              if (!_isEditing) ...[
                const SizedBox(height: 8),
                Text(
                  'Creates the next 12 occurrences.',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ],
            const SizedBox(height: 14),
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Notes (optional)',
                prefixIcon: Icon(Icons.notes_rounded,
                    color: AppColors.textSecondary),
                alignLabelWithHint: true,
              ),
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
                    : Text(_isEditing ? 'Update Transaction' : 'Save Transaction'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeToggleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _TypeToggleButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isSelected ? color : AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? color : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
