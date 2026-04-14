// lib/services/api_service.dart
// Handles all HTTP communication with the Flask ML backend
// Supports both local development and Render deployment

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/patient_input.dart';
import '../models/prediction_result.dart';
import '../models/history_entry.dart';

class ApiService {
  // ─── Configuration ───────────────────────────────────────────────────────────
  // 🔄 SWITCH BETWEEN LOCAL AND RENDER DEPLOYMENT:
  //
  // LOCAL DEV (Flask on your machine):
  //   - iOS Simulator:      'http://localhost:5000'
  //   - Android Emulator:   'http://10.0.2.2:5000'
  //   - Physical device:    'http://<YOUR_LOCAL_IP>:5000'
  //
  // RENDER DEPLOYMENT (after deploying):
  //   - Replace with your Render URL, e.g.:
  //     'https://disease-risk-api.onrender.com'
  //
  static const String _baseUrl = 'https://disease-risk-api.onrender.com';

  // ─── Predict Disease Risk ─────────────────────────────────────────────────────
  static Future<PredictionResult> predictRisk(PatientInput input) async {
    final url = Uri.parse('$_baseUrl/predict');

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(input.toJson()),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw ApiException(
                'Request timed out. The server may be starting up (free tier can take ~30s on first request).\n\nPlease try again.'),
          );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return PredictionResult.fromJson(data);
      } else {
        throw ApiException(
          'Server error (${response.statusCode}): ${response.body}',
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
          'Cannot connect to server at $_baseUrl\n\n'
          'If running locally, make sure you ran:\n'
          '  1. python train_model.py\n'
          '  2. python app.py\n\n'
          'If using Render, the server may be sleeping (free tier).\n'
          'Wait ~30 seconds and try again.\n\n'
          'Details: $e');
    }
  }

  // ─── Fetch Prediction History from Database ──────────────────────────────────
  static Future<List<HistoryEntry>> fetchHistory({String? nameFilter}) async {
    String urlStr = '$_baseUrl/history';
    if (nameFilter != null && nameFilter.isNotEmpty) {
      urlStr += '?name=${Uri.encodeComponent(nameFilter)}';
    }
    final url = Uri.parse(urlStr);

    try {
      final response = await http
          .get(
            url,
            headers: {'Accept': 'application/json'},
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw ApiException(
                'History request timed out. Server may be starting up.'),
          );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> historyJson = data['history'] ?? [];

        return historyJson.map((item) {
          // Convert the DB format to HistoryEntry format
          return HistoryEntry(
            timestamp: DateTime.parse(item['created_at']),
            input: PatientInput(
              name: item['patient_name'] ?? 'Unknown',
              age: item['age'] as int,
              gender: item['gender'] as String,
              bmi: (item['bmi'] as num).toDouble(),
              bloodPressure: item['blood_pressure'] as int,
              cholesterol: item['cholesterol'] as int,
              glucose: item['glucose'] as int,
              heartRate: item['heart_rate'] as int,
              smoking: item['smoking'] as bool,
            ),
            result: PredictionResult(
              riskScore: (item['risk_score'] as num).toDouble(),
              prediction: item['prediction'] as String,
              explanation: Map<String, String>.from(item['explanation'] as Map),
            ),
          );
        }).toList();
      } else if (response.statusCode == 503) {
        throw ApiException('Database not configured on the server.');
      } else {
        throw ApiException(
          'Failed to fetch history (${response.statusCode}): ${response.body}',
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Could not load history from server.\n\nDetails: $e');
    }
  }

  // ─── Mock Response (fallback for offline demo) ────────────────────────────────
  static Future<PredictionResult> mockPredictRisk(PatientInput input) async {
    await Future.delayed(const Duration(seconds: 2));

    double score = 0.0;
    if (input.age > 50) score += 0.15;
    if (input.bmi > 30) score += 0.15;
    if (input.bloodPressure > 130) score += 0.15;
    if (input.cholesterol > 200) score += 0.1;
    if (input.glucose > 126) score += 0.25;
    if (input.heartRate > 100) score += 0.1;
    if (input.smoking) score += 0.1;
    score = score.clamp(0.0, 1.0);

    String prediction;
    if (score >= 0.65) prediction = 'High Risk';
    else if (score >= 0.35) prediction = 'Medium Risk';
    else prediction = 'Low Risk';

    final Map<String, String> explanation = {};
    if (input.glucose > 126) explanation['Glucose'] = 'major contributor';
    if (input.bmi > 30) explanation['BMI'] = 'major contributor';
    if (input.bloodPressure > 130) explanation['Blood Pressure'] = 'moderate contributor';
    if (input.cholesterol > 200) explanation['Cholesterol'] = 'moderate contributor';
    if (input.age > 50) explanation['Age'] = 'minor contributor';
    if (input.smoking) explanation['Smoking'] = 'minor contributor';
    if (explanation.isEmpty) explanation['BMI'] = 'minor contributor';

    return PredictionResult(
      riskScore: score,
      prediction: prediction,
      explanation: explanation,
    );
  }
}

// ─── Custom Exception ─────────────────────────────────────────────────────────
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}
