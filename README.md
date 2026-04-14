# 🏥 Personalized Disease Risk Predictor

**BTech Final Year Project**  
*Interpretable Machine Learning for Personalized Disease Risk Stratification*

---

## 📱 App Overview

A Flutter mobile application that predicts disease risk (Heart Disease / Diabetes) based on patient health inputs and explains the prediction using interpretable ML techniques (SHAP-style feature importance).

---

## 🗂️ Project Structure

```
disease_risk_app/
├── lib/
│   ├── main.dart                    # App entry point, theme, Provider setup
│   ├── screens/
│   │   ├── home_screen.dart         # Welcome/landing screen
│   │   ├── input_screen.dart        # Patient health data form
│   │   └── result_screen.dart       # Prediction results + charts
│   ├── models/
│   │   ├── patient_input.dart       # Patient data model + toJson()
│   │   └── prediction_result.dart   # API response model + helpers
│   ├── services/
│   │   ├── api_service.dart         # HTTP API calls + mock mode
│   │   └── prediction_provider.dart # ChangeNotifier state manager
│   └── widgets/
│       ├── input_field.dart         # Reusable form widgets
│       ├── feature_chart.dart       # fl_chart bar chart widget
│       └── risk_gauge.dart          # Animated circular gauge
├── backend/
│   ├── app.py                       # Flask API server
│   └── requirements.txt             # Python dependencies
├── pubspec.yaml                     # Flutter dependencies
└── README.md
```

---

## 🚀 Getting Started

### Flutter App

1. **Install Flutter** (>= 3.0): https://docs.flutter.dev/get-started/install

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run on emulator or device:**
   ```bash
   flutter run
   ```

> ⚠️ The app runs in **mock mode** by default (no backend needed).  
> To use a real backend, set `useMockApi = false` in `prediction_provider.dart`.

---

### Flask Backend (Optional)

1. **Install Python dependencies:**
   ```bash
   cd backend
   pip install -r requirements.txt
   ```

2. **Run the server:**
   ```bash
   python app.py
   ```

3. **Test the endpoint:**
   ```bash
   curl -X POST http://localhost:5000/predict \
     -H "Content-Type: application/json" \
     -d '{"age":45,"gender":"male","bmi":28.5,"blood_pressure":140,"cholesterol":220,"glucose":160,"heart_rate":95,"smoking":true}'
   ```

---

## 📦 Flutter Packages Used

| Package | Purpose |
|---------|---------|
| `http` | REST API calls |
| `provider` | State management (ChangeNotifier) |
| `fl_chart` | Feature importance bar chart |

---

## 🔌 API Contract

**POST** `/predict`

**Request:**
```json
{
  "age": 45,
  "gender": "male",
  "bmi": 28.5,
  "blood_pressure": 140,
  "cholesterol": 220,
  "glucose": 160,
  "heart_rate": 95,
  "smoking": true
}
```

**Response:**
```json
{
  "risk_score": 0.78,
  "prediction": "High Risk",
  "explanation": {
    "glucose": "major contributor",
    "bmi": "moderate contributor",
    "age": "minor contributor"
  }
}
```

---

## 🧠 Architecture

- **MVVM-like**: Models → Services → Provider → Screens
- **State**: `PredictionProvider` (ChangeNotifier) manages loading, result, and error
- **API**: `ApiService` handles HTTP + mock fallback
- **Mock Mode**: Works offline for demo without a running backend

---

## 📸 Screens

1. **Home Screen** — App intro with gradient branding
2. **Input Screen** — Validated form for 8 health parameters
3. **Result Screen** — Risk gauge, contributing factors, bar chart, recommendations

---

## ⚠️ Disclaimer

> This app is for **educational and demo purposes only**.  
> It is **not** a substitute for professional medical advice, diagnosis, or treatment.
