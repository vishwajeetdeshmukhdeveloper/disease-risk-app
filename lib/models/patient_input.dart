// lib/models/patient_input.dart
// Model class representing the patient health data collected from the form

class PatientInput {
  final String name;
  final int age;
  final String gender;       // "male" or "female"
  final double bmi;
  final int bloodPressure;
  final int cholesterol;
  final int glucose;
  final int heartRate;
  final bool smoking;

  PatientInput({
    required this.name,
    required this.age,
    required this.gender,
    required this.bmi,
    required this.bloodPressure,
    required this.cholesterol,
    required this.glucose,
    required this.heartRate,
    required this.smoking,
  });

  /// Converts the patient input to a JSON map for the API POST body and local storage
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'gender': gender,
      'bmi': bmi,
      'blood_pressure': bloodPressure,
      'cholesterol': cholesterol,
      'glucose': glucose,
      'heart_rate': heartRate,
      'smoking': smoking,
    };
  }

  factory PatientInput.fromJson(Map<String, dynamic> json) {
    return PatientInput(
      name: json['name'] ?? '',
      age: json['age'] as int,
      gender: json['gender'] as String,
      bmi: (json['bmi'] as num).toDouble(),
      bloodPressure: json['blood_pressure'] as int,
      cholesterol: json['cholesterol'] as int,
      glucose: json['glucose'] as int,
      heartRate: json['heart_rate'] as int,
      smoking: json['smoking'] as bool,
    );
  }
}
