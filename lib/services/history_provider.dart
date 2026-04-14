import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/history_entry.dart';
import '../models/patient_input.dart';
import '../models/prediction_result.dart';
import 'api_service.dart';

class HistoryProvider with ChangeNotifier {
  List<HistoryEntry> _history = [];
  bool _isLoading = true;
  String? _error;

  List<HistoryEntry> get history => _history;
  bool get isLoading => _isLoading;
  String? get error => _error;

  HistoryProvider() {
    loadHistory();
  }

  /// Load history — tries remote database first, falls back to local storage
  Future<void> loadHistory() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Try fetching from remote database (Render server)
      final remoteHistory = await ApiService.fetchHistory();
      _history = remoteHistory;
      debugPrint('HISTORY: Loaded ${_history.length} entries from database');
    } catch (e) {
      debugPrint('HISTORY: Remote fetch failed ($e), falling back to local');
      // Fall back to local SharedPreferences
      await _loadLocalHistory();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load history from local SharedPreferences (offline fallback)
  Future<void> _loadLocalHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? historyJson = prefs.getString('prediction_history');
      if (historyJson != null) {
        final List<dynamic> decoded = jsonDecode(historyJson);
        _history = decoded.map((item) => HistoryEntry.fromJson(item)).toList();
        debugPrint('HISTORY: Loaded ${_history.length} entries from local storage');
      }
    } catch (e) {
      debugPrint('HISTORY: Local load failed: $e');
      _error = 'Could not load history';
    }
  }

  /// Save a prediction — the backend already saves to DB,
  /// but we also save locally for offline access
  Future<void> savePrediction(PatientInput input, PredictionResult result) async {
    final newEntry = HistoryEntry(
      timestamp: DateTime.now(),
      input: input,
      result: result,
    );
    
    _history.insert(0, newEntry); // Add to top (newest first)
    debugPrint('HISTORY: Added entry for ${input.name}. Total entries: ${_history.length}');
    notifyListeners();

    // Persist to SharedPreferences (local backup)
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_history.map((e) => e.toJson()).toList());
    await prefs.setString('prediction_history', encoded);
    debugPrint('HISTORY: Persisted to SharedPreferences');
  }

  /// Refresh history from the remote database
  Future<void> refreshFromDatabase() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final remoteHistory = await ApiService.fetchHistory();
      _history = remoteHistory;
      debugPrint('HISTORY: Refreshed ${_history.length} entries from database');
    } catch (e) {
      _error = 'Could not refresh from database: $e';
      debugPrint('HISTORY: Refresh failed: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _history.clear();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('prediction_history');
  }
}
