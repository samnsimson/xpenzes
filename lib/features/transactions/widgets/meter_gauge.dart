import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A compact donut-style meter gauge showing [value] as a percentage of
/// [max], used for the Income / Spent / Balance stats on the dashboard.
class MeterGauge extends StatelessWidget {
  final String label;
  final String valueText;
  final double value;
  final double max;
  final Color color;
  final bool highlight;

  const MeterGauge({
    super.key,
    required this.label,
    required this.valueText,
    required this.value,
    required this.max,
    required this.color,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final percent = max <= 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
    const size = 46.0;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: highlight
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: highlight
              ? Border.all(color: Colors.white.withValues(alpha: 0.3))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      startDegreeOffset: -90,
                      sectionsSpace: 0,
                      centerSpaceRadius: size / 2 - 7,
                      sections: [
                        PieChartSectionData(
                          value: percent * 100,
                          color: color,
                          radius: 7,
                          showTitle: false,
                        ),
                        PieChartSectionData(
                          value: (1 - percent) * 100,
                          color: Colors.white.withValues(alpha: 0.18),
                          radius: 7,
                          showTitle: false,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${(percent * 100).round()}%',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              valueText,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color == Colors.white ? Colors.white : color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
