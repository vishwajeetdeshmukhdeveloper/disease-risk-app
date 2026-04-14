// lib/screens/result_screen.dart
// Displays the prediction result, risk gauge, factor list, and bar chart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/prediction_result.dart';
import '../services/prediction_provider.dart';
import '../widgets/risk_gauge.dart';
import '../widgets/feature_chart.dart';
import '../widgets/input_field.dart';
import '../services/report_generator.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  // ─── Map contribution label to icon ──────────────────────────────────────
  IconData _iconFor(String label) {
    switch (label.toLowerCase()) {
      case 'major contributor':
        return Icons.arrow_upward_rounded;
      case 'moderate contributor':
        return Icons.trending_up_rounded;
      default:
        return Icons.remove_rounded;
    }
  }

  Color _colorFor(String label) {
    switch (label.toLowerCase()) {
      case 'major contributor':
        return const Color(0xFFE53935);
      case 'moderate contributor':
        return const Color(0xFFFB8C00);
      default:
        return const Color(0xFF43A047);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access prediction result from provider (read-only here)
    final provider = context.watch<PredictionProvider>();
    final result = provider.result;
    final input = provider.lastInput;

    // Safety check — should never be null at this point
    if (result == null) {
      return const Scaffold(
        body: Center(child: Text('No result available')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prediction Result'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.black87),
            tooltip: 'Generate Report',
            onPressed: () async {
              final provider = context.read<PredictionProvider>();
              final r = provider.result;
              final i = provider.lastInput;
              if (r != null && i != null) {
                 final recs = _getRecommendations(r);
                 await ReportGenerator.generateAndPreviewPdf(i, r, recs);
              } else {
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text('Data not available for report.')),
                 );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Risk Score Card ────────────────────────────────────────────
            _Card(
              child: Column(
                children: [
                   Text(
                     input?.name != null && input!.name.isNotEmpty 
                        ? 'Risk Assessment: ${input.name}' 
                        : 'Overall Risk Assessment',
                     style: Theme.of(context).textTheme.titleMedium?.copyWith(
                           fontWeight: FontWeight.bold,
                         ),
                   ),
                   const SizedBox(height: 20),
                  // Animated circular gauge
                  RiskGauge(riskScore: result.riskScore),
                  const SizedBox(height: 20),
                  // Risk badge
                  RiskBadge(prediction: result.prediction),
                  const SizedBox(height: 8),
                  Text(
                    _getRiskDescription(result.prediction),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ─── Top Contributing Factors ──────────────────────────────────
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.medical_information_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Top Contributing Factors',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'These health parameters most influenced the prediction',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 16),
                  // List each factor from sortedExplanation
                  ...result.sortedExplanation.map(
                    (entry) => _FactorTile(
                      name: entry.key,
                      label: entry.value,
                      icon: _iconFor(entry.value),
                      color: _colorFor(entry.value),
                    ),
                  ).toList(),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ─── Bar Chart ─────────────────────────────────────────────────
            _Card(
              child: FeatureImportanceChart(result: result),
            ),
            const SizedBox(height: 16),

            // ─── Recommendations ────────────────────────────────────────────
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.tips_and_updates_rounded,
                        color: Theme.of(context).colorScheme.tertiary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Recommendations',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DailyActionChecklist(
                    recommendations: _getRecommendations(result),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ─── Action Buttons ─────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Reset and go back to input
                      context.read<PredictionProvider>().reset();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('New Prediction'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                    icon: const Icon(Icons.home_rounded),
                    label: const Text('Home'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ─── Helper: risk description ────────────────────────────────────────────
  String _getRiskDescription(String prediction) {
    if (prediction.toLowerCase().contains('high')) {
      return 'This patient shows significant risk factors.\nImmediate medical consultation is strongly recommended.';
    } else if (prediction.toLowerCase().contains('medium')) {
      return 'Moderate risk detected. Lifestyle improvements\nand regular monitoring are advised.';
    } else {
      return 'Low risk indicators. Maintain current healthy\nhabits and continue routine check-ups.';
    }
  }

  // ─── Helper: recommendations based on result ─────────────────────────────
  List<String> _getRecommendations(PredictionResult result) {
    final recs = <String>[];
    final explanations = result.explanation;

    if (explanations.containsKey('Glucose') || explanations.containsKey('glucose')) {
      recs.add('Monitor blood glucose levels regularly and consider a low-glycemic diet.');
    }
    if (explanations.containsKey('BMI') || explanations.containsKey('bmi')) {
      recs.add('Work towards maintaining a healthy BMI through balanced nutrition and exercise.');
    }
    if (explanations.containsKey('Blood Pressure') ||
        explanations.containsKey('blood_pressure')) {
      recs.add('Reduce sodium intake, manage stress, and monitor blood pressure frequently.');
    }
    if (explanations.containsKey('Cholesterol') ||
        explanations.containsKey('cholesterol')) {
      recs.add('Follow a heart-healthy diet low in saturated fats to manage cholesterol.');
    }
    if (explanations.containsKey('Smoking') || explanations.containsKey('smoking')) {
      recs.add('Quitting smoking significantly reduces cardiovascular and metabolic risk.');
    }

    // Default recommendation always shown
    recs.add('Schedule a consultation with a healthcare professional for a full evaluation.');

    return recs;
  }
}

// ─── Reusable Card Container ─────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─── Factor Tile Widget ───────────────────────────────────────────────────────
class _FactorTile extends StatelessWidget {
  final String name;
  final String label;
  final IconData icon;
  final Color color;

  const _FactorTile({
    required this.name,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Gamified Action Checklist ────────────────────────────────────────────────

class DailyActionChecklist extends StatefulWidget {
  final List<String> recommendations;

  const DailyActionChecklist({super.key, required this.recommendations});

  @override
  State<DailyActionChecklist> createState() => _DailyActionChecklistState();
}

class _DailyActionChecklistState extends State<DailyActionChecklist> {
  final Set<int> _completed = {};

  @override
  Widget build(BuildContext context) {
    if (widget.recommendations.isEmpty) return const SizedBox.shrink();

    final progress = _completed.length / widget.recommendations.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_completed.length} of ${widget.recommendations.length} goals met',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: Colors.grey.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...widget.recommendations.asMap().entries.map((entry) {
          final index = entry.key;
          final rec = entry.value;
          final isDone = _completed.contains(index);

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isDone 
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.05) 
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDone 
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.2),
              ),
            ),
            child: CheckboxListTile(
              value: isDone,
              dense: true,
              activeColor: Theme.of(context).colorScheme.primary,
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    _completed.add(index);
                  } else {
                    _completed.remove(index);
                  }
                });
              },
              title: Text(
                rec,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.3,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                  color: isDone ? Colors.grey[600] : null,
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          );
        }).toList(),
      ],
    );
  }
}
