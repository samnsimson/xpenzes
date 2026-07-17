/// Shared form-field validation used across auth and transaction forms.
/// Plain functions rather than a class — none of this needs state.
library;

final _emailPattern = RegExp(r'^[^@]+@[^@]+\.[^@]+');

bool isValidEmail(String email) => _emailPattern.hasMatch(email.trim());

/// A non-empty title, trimmed. Returns the error message to show, or
/// null if valid.
String? validateTransactionTitle(String title) {
  if (title.trim().isEmpty) return 'Please enter a title.';
  return null;
}

/// A parseable, positive amount. Returns the error message to show, or
/// null if valid.
String? validateTransactionAmount(String amountText) {
  final amount = double.tryParse(amountText.trim());
  if (amount == null || amount <= 0) return 'Please enter a valid amount.';
  return null;
}
