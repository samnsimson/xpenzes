import 'package:flutter/material.dart';

class AppConstants {
  static const Map<String, String> currencies = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'INR': '₹',
    'JPY': '¥',
    'CAD': 'CA\$',
    'AUD': 'A\$',
    'CHF': 'Fr',
    'SGD': 'S\$',
    'AED': 'د.إ',
  };

  static const List<String> incomeSources = [
    'Salary',
    'Freelance',
    'Business',
    'Investment',
    'Rental',
    'Side Hustle',
    'Other',
  ];

  static const List<String> recurrenceFrequencies = [
    'Weekly',
    'Bi-weekly',
    'Monthly',
    'Quarterly',
    'Yearly',
  ];

  static const List<String> expenseCategories = [
    'Food & Dining',
    'Transport',
    'Shopping',
    'Entertainment',
    'Health',
    'Housing',
    'Education',
    'Travel',
    'Utilities',
    'Personal Care',
    'Other',
  ];

  static const Map<String, Color> categoryColors = {
    'Food & Dining': Color(0xFFF97316),
    'Transport': Color(0xFF3B82F6),
    'Shopping': Color(0xFF8B5CF6),
    'Entertainment': Color(0xFFEC4899),
    'Health': Color(0xFF10B981),
    'Housing': Color(0xFF78716C),
    'Education': Color(0xFF06B6D4),
    'Travel': Color(0xFF0EA5E9),
    'Utilities': Color(0xFFF59E0B),
    'Personal Care': Color(0xFFD946EF),
    'Other': Color(0xFF94A3B8),
  };

  static const Map<String, IconData> categoryIcons = {
    'Food & Dining': Icons.restaurant_rounded,
    'Transport': Icons.directions_car_rounded,
    'Shopping': Icons.shopping_bag_rounded,
    'Entertainment': Icons.movie_rounded,
    'Health': Icons.favorite_rounded,
    'Housing': Icons.home_rounded,
    'Education': Icons.school_rounded,
    'Travel': Icons.flight_rounded,
    'Utilities': Icons.bolt_rounded,
    'Personal Care': Icons.spa_rounded,
    'Other': Icons.more_horiz_rounded,
  };
}
