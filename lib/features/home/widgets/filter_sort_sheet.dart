import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../transactions/models/transaction_filter.dart';
import '../../transactions/models/transaction_model.dart';
import '../../transactions/providers/transaction_filter_provider.dart';

class FilterSortSheet extends ConsumerStatefulWidget {
  const FilterSortSheet({super.key});

  @override
  ConsumerState<FilterSortSheet> createState() => _FilterSortSheetState();
}

class _FilterSortSheetState extends ConsumerState<FilterSortSheet> {
  late TransactionType? _type;
  late String? _category;
  late bool? _isRecurring;
  late TransactionSortField _sortBy;
  late SortOrder _sortOrder;
  late final TextEditingController _minCtrl;
  late final TextEditingController _maxCtrl;

  @override
  void initState() {
    super.initState();
    final filter = ref.read(transactionFilterProvider);
    _type = filter.type;
    _category = filter.category;
    _isRecurring = filter.isRecurring;
    _sortBy = filter.sortBy;
    _sortOrder = filter.sortOrder;
    _minCtrl = TextEditingController(
      text: filter.minAmount?.toStringAsFixed(2) ?? '',
    );
    _maxCtrl = TextEditingController(
      text: filter.maxAmount?.toStringAsFixed(2) ?? '',
    );
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  void _setType(TransactionType? type) {
    setState(() {
      _type = type;
      _category = null;
    });
  }

  void _toggleCategory(String category) {
    setState(() => _category = _category == category ? null : category);
  }

  void _apply() {
    final filter = TransactionFilter(
      type: _type,
      category: _category,
      minAmount: double.tryParse(_minCtrl.text.trim()),
      maxAmount: double.tryParse(_maxCtrl.text.trim()),
      isRecurring: _isRecurring,
      sortBy: _sortBy,
      sortOrder: _sortOrder,
    );
    ref.read(transactionFilterProvider.notifier).state = filter;
    Navigator.pop(context);
  }

  void _reset() {
    ref.read(transactionFilterProvider.notifier).state =
        const TransactionFilter();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final symbol = ref.watch(currencySymbolProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

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
              'Filter & Sort',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            _Label('Type'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _Chip(
                    label: 'All',
                    isSelected: _type == null,
                    onTap: () => _setType(null),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Chip(
                    label: 'Expense',
                    isSelected: _type == TransactionType.expense,
                    onTap: () => _setType(TransactionType.expense),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Chip(
                    label: 'Income',
                    isSelected: _type == TransactionType.income,
                    onTap: () => _setType(TransactionType.income),
                  ),
                ),
              ],
            ),
            if (_type != null) ...[
              const SizedBox(height: 18),
              _Label('Category'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _type!.categories
                    .map(
                      (c) => _Chip(
                        label: c,
                        isSelected: _category == c,
                        onTap: () => _toggleCategory(c),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 18),
            _Label('Amount range'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Min',
                      prefixText: symbol,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _maxCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Max',
                      prefixText: symbol,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Recurring only',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Switch(
                  value: _isRecurring ?? false,
                  activeThumbColor: AppColors.primary,
                  onChanged: (v) =>
                      setState(() => _isRecurring = v ? true : null),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _Label('Sort by'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TransactionSortField.values
                  .map(
                    (f) => _Chip(
                      label: _sortFieldLabel(f),
                      isSelected: _sortBy == f,
                      onTap: () => setState(() => _sortBy = f),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 18),
            _Label('Order'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _Chip(
                    label: 'Descending',
                    isSelected: _sortOrder == SortOrder.desc,
                    onTap: () => setState(() => _sortOrder = SortOrder.desc),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Chip(
                    label: 'Ascending',
                    isSelected: _sortOrder == SortOrder.asc,
                    onTap: () => setState(() => _sortOrder = SortOrder.asc),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _apply,
                child: const Text('Apply'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _reset,
                child: Text(
                  'Reset',
                  style: GoogleFonts.inter(color: AppColors.error),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _sortFieldLabel(TransactionSortField field) => switch (field) {
    TransactionSortField.date => 'Date',
    TransactionSortField.amount => 'Amount',
    TransactionSortField.title => 'Title',
    TransactionSortField.category => 'Category',
  };
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
