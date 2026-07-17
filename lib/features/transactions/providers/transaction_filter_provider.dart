import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_filter.dart';

/// The active filter/sort applied to the home screen's transaction list.
/// Persists across month navigation until explicitly changed or cleared.
final transactionFilterProvider = StateProvider<TransactionFilter>(
  (ref) => const TransactionFilter(),
);
