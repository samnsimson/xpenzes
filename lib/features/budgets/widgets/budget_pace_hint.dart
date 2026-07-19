import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/budget_model.dart';
import '../utils/budget_pace_message.dart';

/// Single-line pace coaching hint shown under a budget's spent/limit
/// line. Renders nothing when the category has no budget set.
class BudgetPaceHint extends StatelessWidget {
  final BudgetModel budget;
  final String symbol;

  const BudgetPaceHint({super.key, required this.budget, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final message = BudgetPaceMessage.forBudget(budget, symbol);
    if (message.isEmpty) {
      return const SizedBox.shrink();
    }

    return Text(
      message,
      style: GoogleFonts.inter(
        fontSize: 11,
        color: BudgetPaceMessage.colorFor(budget.pace.paceStatus),
      ),
    );
  }
}
