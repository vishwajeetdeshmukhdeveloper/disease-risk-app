// lib/screens/input_screen.dart
// Patient health data input form with validation and prediction trigger

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/patient_input.dart';
import '../services/prediction_provider.dart';
import '../services/history_provider.dart';
import '../services/theme_provider.dart';
import '../widgets/input_field.dart';
import 'result_screen.dart';
import 'history_screen.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  // ─── Form key for validation ──────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();

  // ─── Controllers for each numeric field ──────────────────────────────────
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _bmiController = TextEditingController();
  final _bpController = TextEditingController();
  final _cholesterolController = TextEditingController();
  final _glucoseController = TextEditingController();
  final _heartRateController = TextEditingController();

  // ─── Dropdown values ──────────────────────────────────────────────────────
  String _selectedGender = 'male';
  bool _isSmoker = false;

  @override
  void dispose() {
    // Dispose all controllers to avoid memory leaks
    _nameController.dispose();
    _ageController.dispose();
    _bmiController.dispose();
    _bpController.dispose();
    _cholesterolController.dispose();
    _glucoseController.dispose();
    _heartRateController.dispose();
    super.dispose();
  }

  // ─── Validation helpers ───────────────────────────────────────────────────
  String? _requiredNumber(String? val, String fieldName) {
    if (val == null || val.isEmpty) return '$fieldName is required';
    if (double.tryParse(val) == null) return 'Enter a valid number';
    return null;
  }

  // ─── Build Patient Input from form ───────────────────────────────────────
  PatientInput _buildInput() {
    return PatientInput(
      name: _nameController.text.trim().isEmpty
          ? 'No Name Entered'
          : _nameController.text.trim(),
      age: int.parse(_ageController.text),
      gender: _selectedGender,
      bmi: double.parse(_bmiController.text),
      bloodPressure: int.parse(_bpController.text),
      cholesterol: int.parse(_cholesterolController.text),
      glucose: int.parse(_glucoseController.text),
      heartRate: int.parse(_heartRateController.text),
      smoking: _isSmoker,
    );
  }

  // ─── Submit handler ───────────────────────────────────────────────────────
  Future<void> _onPredictPressed() async {
    // Validate all form fields
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<PredictionProvider>();
    final input = _buildInput();

    // Call predict on the provider
    await provider.predict(input);

    if (!mounted) return;

    if (provider.hasError) {
      // Show error dialog if API call failed
      _showErrorDialog(provider.errorMessage!);
    } else if (provider.hasResult) {
      // Save successfully fetched result to history locally
      if (provider.result != null) {
        context.read<HistoryProvider>().savePrediction(input, provider.result!);
      }

      // Navigate to result screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ResultScreen(),
        ),
      );
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.error_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Prediction Failed'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to loading state from provider
    final isLoading = context.watch<PredictionProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Health Data'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            icon: Icon(context.watch<ThemeProvider>().isDarkMode
                ? Icons.light_mode_rounded
                : Icons.dark_mode_rounded),
            onPressed: () {
              context.read<ThemeProvider>().toggleTheme();
            },
            tooltip: 'Toggle Theme',
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
            tooltip: 'Past Assessments',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Info Banner ─────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.15),
                      Theme.of(context).colorScheme.secondary.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.insights_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Risk Analysis',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Fill in the patient\'s health parameters below to generate a comprehensive risk prediction.',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color
                                  ?.withOpacity(0.8),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ─── Demographics ─────────────────────────────────────────────
              const SectionHeader(
                title: 'DEMOGRAPHICS',
                icon: Icons.person_rounded,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Patient Name (Optional)',
                  hintText: 'Full Name',
                  prefixIcon: const Icon(Icons.badge_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: NumericInputField(
                      label: 'Age',
                      hint: '45',
                      unit: 'yrs',
                      controller: _ageController,
                      validator: (v) => _requiredNumber(v, 'Age'),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Gender dropdown
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: InputDecoration(
                        labelText: 'Gender',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'male', child: Text('Male')),
                        DropdownMenuItem(
                            value: 'female', child: Text('Female')),
                      ],
                      onChanged: (val) {
                        setState(() => _selectedGender = val!);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ─── Body Metrics ──────────────────────────────────────────────
              const SectionHeader(
                title: 'BODY METRICS',
                icon: Icons.monitor_weight_rounded,
              ),
              const SizedBox(height: 12),
              NumericInputField(
                label: 'BMI (Body Mass Index)',
                hint: '28.5',
                unit: 'kg/m²',
                controller: _bmiController,
                allowDecimal: true,
                validator: (v) => _requiredNumber(v, 'BMI'),
              ),
              const SizedBox(height: 14),
              NumericInputField(
                label: 'Blood Pressure',
                hint: '120',
                unit: 'mmHg',
                controller: _bpController,
                validator: (v) => _requiredNumber(v, 'Blood Pressure'),
              ),
              const SizedBox(height: 14),
              NumericInputField(
                label: 'Heart Rate',
                hint: '72',
                unit: 'bpm',
                controller: _heartRateController,
                validator: (v) => _requiredNumber(v, 'Heart Rate'),
              ),
              const SizedBox(height: 24),

              // ─── Lab Results ───────────────────────────────────────────────
              const SectionHeader(
                title: 'LAB RESULTS',
                icon: Icons.science_rounded,
              ),
              const SizedBox(height: 12),
              NumericInputField(
                label: 'Cholesterol Level',
                hint: '200',
                unit: 'mg/dL',
                controller: _cholesterolController,
                validator: (v) => _requiredNumber(v, 'Cholesterol'),
              ),
              const SizedBox(height: 14),
              NumericInputField(
                label: 'Glucose Level',
                hint: '100',
                unit: 'mg/dL',
                controller: _glucoseController,
                validator: (v) => _requiredNumber(v, 'Glucose'),
              ),
              const SizedBox(height: 24),

              // ─── Lifestyle ─────────────────────────────────────────────────
              const SectionHeader(
                title: 'LIFESTYLE',
                icon: Icons.self_improvement_rounded,
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SwitchListTile(
                  title: const Text(
                    'Smoking Habit',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    _isSmoker ? 'Yes – Current Smoker' : 'No – Non-Smoker',
                    style: TextStyle(
                      color: _isSmoker ? Colors.red[400] : Colors.green[400],
                      fontSize: 12,
                    ),
                  ),
                  secondary: Icon(
                    Icons.smoking_rooms_rounded,
                    color: _isSmoker ? Colors.red[400] : Colors.grey,
                  ),
                  value: _isSmoker,
                  onChanged: (val) => setState(() => _isSmoker = val),
                  activeColor: Colors.red[400],
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                height: 56,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        const Color(0xFF1565C0), // Darker blue
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _onPredictPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: isLoading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Analyzing...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.analytics_rounded, size: 22),
                              SizedBox(width: 10),
                              Text(
                                'Predict Disease Risk',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Disclaimer
              Center(
                child: Text(
                  '⚠️  For educational and demo purposes only.\nNot a substitute for professional medical advice.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
