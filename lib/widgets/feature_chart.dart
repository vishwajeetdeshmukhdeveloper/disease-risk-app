// lib/widgets/feature_chart.dart
// Bar chart widget displaying feature importance (explanation) from the ML model
// Uses fl_chart package for rendering

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/prediction_result.dart';

class FeatureImportanceChart extends StatelessWidget {
  final PredictionResult result;

  const FeatureImportanceChart({super.key, required this.result});

  // ─── Color mapping ────────────────────────────────────────────────────────
  Color _barColor(String label) {
    switch (label.toLowerCase()) {
      case 'major contributor':
        return const Color(0xFFE53935); // Red for high impact
      case 'moderate contributor':
        return const Color(0xFFFB8C00); // Orange for medium
      case 'minor contributor':
        return const Color(0xFF43A047); // Green for low
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sorted = result.sortedExplanation;

    if (sorted.isEmpty) {
      return const Center(child: Text('No feature data available'));
    }

    // Build bar groups for fl_chart
    final barGroups = sorted.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final weight = PredictionResult.contributionWeight(item.value);

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: weight,
            color: _barColor(item.value),
            width: 28,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chart title
        Text(
          'Feature Importance',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Higher bars indicate stronger influence on prediction',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 16),

        // ─── Bar Chart ─────────────────────────────────────────────────────
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              maxY: 1.1,
              barGroups: barGroups,
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                horizontalInterval: 0.25,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.withOpacity(0.2),
                  strokeWidth: 1,
                ),
                drawVerticalLine: false,
              ),
              titlesData: FlTitlesData(
                // X-axis: feature names (rotated)
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 52,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= sorted.length) {
                        return const SizedBox.shrink();
                      }
                      // Capitalize first letter of feature name
                      final name = sorted[idx].key;
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: RotatedBox(
                          quarterTurns: 1,
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Y-axis: contribution level labels
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    interval: 0.25,
                    getTitlesWidget: (value, meta) {
                      String label;
                      if (value == 0) label = '0';
                      else if (value == 0.25) label = '25%';
                      else if (value == 0.5) label = '50%';
                      else if (value == 0.75) label = '75%';
                      else if (value == 1.0) label = '100%';
                      else return const SizedBox.shrink();
                      return Text(
                        label,
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final item = sorted[group.x];
                    return BarTooltipItem(
                      '${item.key}\n${item.value}',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),
        // ─── Legend ──────────────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legendItem(const Color(0xFFE53935), 'Major'),
            const SizedBox(width: 16),
            _legendItem(const Color(0xFFFB8C00), 'Moderate'),
            const SizedBox(width: 16),
            _legendItem(const Color(0xFF43A047), 'Minor'),
          ],
        ),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
