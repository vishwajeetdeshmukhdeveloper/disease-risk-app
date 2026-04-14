// lib/services/prediction_provider.dart
// ChangeNotifier that manages app state: loading, result, and errors.

import 'package:flutter/foundation.dart';
import '../models/patient_input.dart';
import '../models/prediction_result.dart';
import 'api_service.dart';

class PredictionProvider extends ChangeNotifier {
  bool _isLoading = false;
  PredictionResult? _result;
  PatientInput? _lastInput;
  String? _errorMessage;

  // ── Set to false to use the REAL Flask backend ──
  bool useMockApi = false;

  bool get isLoading => _isLoading;
  PredictionResult? get result => _result;
  PatientInput? get lastInput => _lastInput;
  String? get errorMessage => _errorMessage;
  bool get hasResult => _result != null;
  bool get hasError => _errorMessage != null;

  Future<void> predict(PatientInput input) async {
    _isLoading = true;
    _errorMessage = null;
    _result = null;
    _lastInput = input;
    notifyListeners();

    try {
      if (useMockApi) {
        _result = await ApiService.mockPredictRisk(input);
      } else {
        _result = await ApiService.predictRisk(input);
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Unexpected error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _result = null;
    _lastInput = null;
    _errorMessage = null;
    notifyListeners();
  }
}
