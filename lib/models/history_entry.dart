import 'dart:convert';
import 'patient_input.dart';
import 'prediction_result.dart';

class HistoryEntry {
  final DateTime timestamp;
  final PatientInput input;
  final PredictionResult result;

  HistoryEntry({
    required this.timestamp,
    required this.input,
    required this.result,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'input': input.toJson(),
      'result': result.toJson(),
    };
  }

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      timestamp: DateTime.parse(json['timestamp']),
      input: PatientInput.fromJson(json['input']),
      result: PredictionResult.fromJson(json['result']),
    );
  }
}
