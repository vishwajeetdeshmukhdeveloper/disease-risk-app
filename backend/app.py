# app.py
# Flask REST API for Disease Risk Prediction using a real trained ML model
# Includes PostgreSQL database integration for storing predictions
# Run locally: python app.py
# On Render: gunicorn app:app --bind 0.0.0.0:$PORT

from flask import Flask, request, jsonify
from flask_cors import CORS
import joblib
import numpy as np
import json
import os
import psycopg2
import psycopg2.extras
from datetime import datetime

app = Flask(__name__)
CORS(app)   # Allow cross-origin requests from Flutter app

# ─── Load Model & Scaler at Startup ──────────────────────────────────────────
MODEL_PATH  = "model/disease_risk_model.pkl"
SCALER_PATH = "model/scaler.pkl"

if not os.path.exists(MODEL_PATH):
    raise FileNotFoundError(
        "Model not found! Please run: python train_model.py"
    )

print("Loading model...")
model  = joblib.load(MODEL_PATH)
scaler = joblib.load(SCALER_PATH)

# Feature order MUST match training order
FEATURE_COLS = ['age', 'gender', 'bmi', 'blood_pressure',
                'cholesterol', 'glucose', 'heart_rate', 'smoking']

RISK_LABELS = {0: 'Low Risk', 1: 'Medium Risk', 2: 'High Risk'}

print("✅ Model loaded successfully!")


# ─── Database Setup ───────────────────────────────────────────────────────────
DATABASE_URL = os.environ.get("DATABASE_URL")

def get_db_connection():
    """Get a database connection. Returns None if DATABASE_URL is not set."""
    if not DATABASE_URL:
        return None
    try:
        conn = psycopg2.connect(DATABASE_URL, sslmode='require')
        return conn
    except Exception as e:
        print(f"[DB ERROR] Could not connect: {e}")
        return None


def init_db():
    """Create the predictions table if it doesn't exist."""
    conn = get_db_connection()
    if not conn:
        print("⚠️  No DATABASE_URL set — running without database (local dev mode)")
        return

    try:
        cur = conn.cursor()
        cur.execute("""
            CREATE TABLE IF NOT EXISTS predictions (
                id SERIAL PRIMARY KEY,
                created_at TIMESTAMPTZ DEFAULT NOW(),
                patient_name TEXT,
                age INTEGER NOT NULL,
                gender TEXT NOT NULL,
                bmi FLOAT NOT NULL,
                blood_pressure INTEGER NOT NULL,
                cholesterol INTEGER NOT NULL,
                glucose INTEGER NOT NULL,
                heart_rate INTEGER NOT NULL,
                smoking BOOLEAN NOT NULL,
                risk_score FLOAT NOT NULL,
                prediction TEXT NOT NULL,
                explanation JSONB NOT NULL
            );
        """)
        conn.commit()
        cur.close()
        conn.close()
        print("✅ Database initialized — predictions table ready!")
    except Exception as e:
        print(f"[DB ERROR] Table creation failed: {e}")
        conn.close()


def save_prediction_to_db(patient_data, risk_score, prediction, explanation):
    """Insert a prediction record into the database."""
    conn = get_db_connection()
    if not conn:
        return None

    try:
        cur = conn.cursor()
        cur.execute("""
            INSERT INTO predictions 
                (patient_name, age, gender, bmi, blood_pressure, 
                 cholesterol, glucose, heart_rate, smoking,
                 risk_score, prediction, explanation)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING id, created_at;
        """, (
            patient_data.get('name', 'Unknown'),
            int(patient_data['age']),
            patient_data['gender'],
            float(patient_data['bmi']),
            int(patient_data['blood_pressure']),
            int(patient_data['cholesterol']),
            int(patient_data['glucose']),
            int(patient_data['heart_rate']),
            bool(patient_data.get('smoking', False)),
            float(risk_score),
            prediction,
            json.dumps(explanation)
        ))
        result = cur.fetchone()
        conn.commit()
        cur.close()
        conn.close()
        print(f"[DB] Saved prediction #{result[0]} at {result[1]}")
        return result[0]  # Return the ID
    except Exception as e:
        print(f"[DB ERROR] Failed to save: {e}")
        conn.close()
        return None


# Initialize database on startup
init_db()


# ─── Helper: Generate SHAP-style explanation ─────────────────────────────────
def generate_explanation(input_values: dict, risk_class: int) -> dict:
    """
    Generates feature-level explanation using feature importances
    from the trained Gradient Boosting model, weighted by how
    far each patient value deviates from the healthy reference range.
    """
    # Healthy reference ranges (midpoints)
    reference = {
        'age':            40,
        'gender':          0,
        'bmi':            22,
        'blood_pressure': 110,
        'cholesterol':    170,
        'glucose':         90,
        'heart_rate':      70,
        'smoking':          0,
    }

    # How much each feature deviates (normalized 0–1)
    deviation_scores = {}
    for feat in FEATURE_COLS:
        val = input_values.get(feat, 0)
        ref = reference[feat]
        if feat in ['gender', 'smoking']:
            # Binary features
            deviation_scores[feat] = abs(val - ref)
        else:
            # Continuous — normalize by a typical range
            ranges = {
                'age': 50, 'bmi': 15, 'blood_pressure': 60,
                'cholesterol': 100, 'glucose': 120, 'heart_rate': 50
            }
            deviation_scores[feat] = min(abs(val - ref) / ranges[feat], 1.0)

    # Multiply model's global feature importance × patient's deviation
    importances = model.feature_importances_
    weighted = {}
    for i, feat in enumerate(FEATURE_COLS):
        weighted[feat] = importances[i] * deviation_scores[feat]

    # Rank and label the top contributors
    sorted_feats = sorted(weighted.items(), key=lambda x: -x[1])

    explanation = {}
    for i, (feat, score) in enumerate(sorted_feats):
        if score < 0.01:
            continue  # Skip negligible contributors
        if i == 0 and score > 0.08:
            label = "major contributor"
        elif i <= 2 and score > 0.04:
            label = "moderate contributor"
        else:
            label = "minor contributor"

        # Convert snake_case to human-readable name
        display_name = feat.replace('_', ' ').title()
        explanation[display_name] = label

    # Always include at least 2 factors
    if len(explanation) < 2:
        for feat, score in sorted_feats[:2]:
            display_name = feat.replace('_', ' ').title()
            if display_name not in explanation:
                explanation[display_name] = "minor contributor"

    return explanation


# ─── POST /predict ────────────────────────────────────────────────────────────
@app.route("/predict", methods=["POST"])
def predict():
    """
    Accepts patient health data JSON and returns:
    - risk_score (0.0 – 1.0)
    - prediction ("Low Risk" / "Medium Risk" / "High Risk")
    - explanation (feature → contribution label)
    Also saves the prediction to the database.
    """
    try:
        data = request.get_json(force=True)
        if not data:
            return jsonify({"error": "Empty request body"}), 400

        # ── Validate required fields ─────────────────────────────────────────
        required = ['age', 'gender', 'bmi', 'blood_pressure',
                    'cholesterol', 'glucose', 'heart_rate', 'smoking']
        missing = [f for f in required if f not in data]
        if missing:
            return jsonify({"error": f"Missing fields: {missing}"}), 400

        # ── Encode gender string → numeric ───────────────────────────────────
        gender_raw = data['gender']
        if isinstance(gender_raw, str):
            gender_val = 1 if gender_raw.lower() == 'male' else 0
        else:
            gender_val = int(gender_raw)

        # ── Encode smoking bool/string → numeric ─────────────────────────────
        smoking_raw = data['smoking']
        if isinstance(smoking_raw, bool):
            smoking_val = 1 if smoking_raw else 0
        elif isinstance(smoking_raw, str):
            smoking_val = 1 if smoking_raw.lower() in ['yes', 'true', '1'] else 0
        else:
            smoking_val = int(smoking_raw)

        # ── Build input dict for explanation ─────────────────────────────────
        input_values = {
            'age':            float(data['age']),
            'gender':         float(gender_val),
            'bmi':            float(data['bmi']),
            'blood_pressure': float(data['blood_pressure']),
            'cholesterol':    float(data['cholesterol']),
            'glucose':        float(data['glucose']),
            'heart_rate':     float(data['heart_rate']),
            'smoking':        float(smoking_val),
        }

        # ── Build feature vector in correct order ─────────────────────────────
        feature_vector = np.array([[
            input_values['age'],
            input_values['gender'],
            input_values['bmi'],
            input_values['blood_pressure'],
            input_values['cholesterol'],
            input_values['glucose'],
            input_values['heart_rate'],
            input_values['smoking'],
        ]])

        # ── Scale & Predict ───────────────────────────────────────────────────
        feature_vector_scaled = scaler.transform(feature_vector)
        predicted_class = int(model.predict(feature_vector_scaled)[0])
        probabilities   = model.predict_proba(feature_vector_scaled)[0]

        # Risk score = weighted sum (Low=0, Med=0.5, High=1.0) using probabilities
        risk_score = round(
            float(probabilities[0] * 0.15 +
                  probabilities[1] * 0.55 +
                  probabilities[2] * 1.00),
            3
        )
        risk_score = min(risk_score, 1.0)

        prediction  = RISK_LABELS[predicted_class]
        explanation = generate_explanation(input_values, predicted_class)

        # ── Save to Database ──────────────────────────────────────────────────
        db_id = save_prediction_to_db(data, risk_score, prediction, explanation)

        # ── Build response ────────────────────────────────────────────────────
        response = {
            "risk_score":  risk_score,
            "prediction":  prediction,
            "explanation": explanation,
            # Optional: include raw probabilities for debugging
            "probabilities": {
                "low_risk":    round(float(probabilities[0]), 3),
                "medium_risk": round(float(probabilities[1]), 3),
                "high_risk":   round(float(probabilities[2]), 3),
            }
        }

        # Include DB record ID if saved successfully
        if db_id is not None:
            response["db_id"] = db_id

        print(f"[PREDICT] Input: age={data['age']}, bmi={data['bmi']}, "
              f"glucose={data['glucose']} → {prediction} ({risk_score:.2f})")

        return jsonify(response), 200

    except Exception as e:
        print(f"[ERROR] {e}")
        return jsonify({"error": str(e)}), 500


# ─── GET /history ─────────────────────────────────────────────────────────────
@app.route("/history", methods=["GET"])
def get_history():
    """
    Fetch all past predictions from the database.
    Optional query parameter: ?name=John to filter by patient name.
    Returns array of prediction records, newest first.
    """
    conn = get_db_connection()
    if not conn:
        return jsonify({"error": "Database not configured"}), 503

    try:
        cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        
        name_filter = request.args.get('name')
        
        if name_filter:
            cur.execute("""
                SELECT id, created_at, patient_name, age, gender, bmi,
                       blood_pressure, cholesterol, glucose, heart_rate,
                       smoking, risk_score, prediction, explanation
                FROM predictions
                WHERE patient_name ILIKE %s
                ORDER BY created_at DESC
                LIMIT 100;
            """, (f"%{name_filter}%",))
        else:
            cur.execute("""
                SELECT id, created_at, patient_name, age, gender, bmi,
                       blood_pressure, cholesterol, glucose, heart_rate,
                       smoking, risk_score, prediction, explanation
                FROM predictions
                ORDER BY created_at DESC
                LIMIT 100;
            """)

        rows = cur.fetchall()
        cur.close()
        conn.close()

        # Convert datetime objects to ISO strings for JSON serialization
        history = []
        for row in rows:
            entry = dict(row)
            entry['created_at'] = entry['created_at'].isoformat()
            history.append(entry)

        return jsonify({"history": history, "count": len(history)}), 200

    except Exception as e:
        print(f"[DB ERROR] History fetch failed: {e}")
        conn.close()
        return jsonify({"error": str(e)}), 500


# ─── GET /history/<id> ────────────────────────────────────────────────────────
@app.route("/history/<int:record_id>", methods=["GET"])
def get_prediction(record_id):
    """Fetch a single prediction by its ID."""
    conn = get_db_connection()
    if not conn:
        return jsonify({"error": "Database not configured"}), 503

    try:
        cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        cur.execute("""
            SELECT id, created_at, patient_name, age, gender, bmi,
                   blood_pressure, cholesterol, glucose, heart_rate,
                   smoking, risk_score, prediction, explanation
            FROM predictions
            WHERE id = %s;
        """, (record_id,))

        row = cur.fetchone()
        cur.close()
        conn.close()

        if row is None:
            return jsonify({"error": "Record not found"}), 404

        entry = dict(row)
        entry['created_at'] = entry['created_at'].isoformat()
        return jsonify(entry), 200

    except Exception as e:
        print(f"[DB ERROR] Record fetch failed: {e}")
        conn.close()
        return jsonify({"error": str(e)}), 500


# ─── GET /health ───────────────────────────────────────────────────────────────
@app.route("/health", methods=["GET"])
def health():
    db_status = "connected" if get_db_connection() else "not configured"
    return jsonify({
        "status":   "ok",
        "model":    "GradientBoostingClassifier",
        "version":  "1.0.0",
        "database": db_status,
        "features": FEATURE_COLS
    })


# ─── GET / ────────────────────────────────────────────────────────────────────
@app.route("/", methods=["GET"])
def index():
    return jsonify({
        "app":       "Disease Risk Prediction API",
        "endpoints": {
            "POST /predict":        "Predict disease risk from patient data",
            "GET  /history":        "Fetch all past predictions from database",
            "GET  /history/<id>":   "Fetch a single prediction by ID",
            "GET  /health":         "API health check"
        }
    })


if __name__ == "__main__":
    print("\n" + "=" * 50)
    print("  Disease Risk Prediction API")
    print("=" * 50)
    print("  POST http://localhost:5000/predict")
    print("  GET  http://localhost:5000/history")
    print("  GET  http://localhost:5000/health")
    print("=" * 50 + "\n")
    app.run(debug=True, host="0.0.0.0", port=5000)
