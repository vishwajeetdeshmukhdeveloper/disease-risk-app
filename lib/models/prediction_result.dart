// lib/models/prediction_result.dart
// Model class representing the API response for disease risk prediction

class PredictionResult {
  final double riskScore;       // Risk score between 0.0 and 1.0
  final String prediction;      // e.g. "High Risk", "Medium Risk", "Low Risk"
  final Map<String, String> explanation; // Feature → contribution label

  PredictionResult({
    required this.riskScore,
    required this.prediction,
    required this.explanation,
  });

  /// Factory constructor to parse JSON response from the API
  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    return PredictionResult(
      riskScore: (json['risk_score'] as num).toDouble(),
      prediction: json['prediction'] as String,
      explanation: Map<String, String>.from(json['explanation'] as Map),
    );
  }

  /// Converts risk score (0.0–1.0) to a percentage string
  String get riskPercentage => '${(riskScore * 100).toStringAsFixed(0)}%';

  /// Returns a numeric weight for a contribution label (used for sorting/charting)
  static double contributionWeight(String label) {
    switch (label.toLowerCase()) {
      case 'major contributor':
        return 1.0;
      case 'moderate contributor':
        return 0.6;
      case 'minor contributor':
        return 0.3;
      default:
        return 0.1;
    }
  }

  /// Returns sorted entries by contribution weight (highest first)
  List<MapEntry<String, String>> get sortedExplanation {
    final entries = explanation.entries.toList();
    entries.sort((a, b) =>
        contributionWeight(b.value).compareTo(contributionWeight(a.value)));
    return entries;
  }

  Map<String, dynamic> toJson() {
    return {
      'risk_score': riskScore,
      'prediction': prediction,
      'explanation': explanation,
    };
  }
}
