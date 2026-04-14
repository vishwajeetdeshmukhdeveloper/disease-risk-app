# train_model.py
# Run this ONCE to train and save the ML model.
# Command: python train_model.py

import numpy as np
import pandas as pd
from sklearn.ensemble import GradientBoostingClassifier
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report, accuracy_score
import joblib
import os

print("=" * 50)
print("  Disease Risk Model Training")
print("=" * 50)

# ─── Step 1: Generate Synthetic Training Data ─────────────────────────────────
# In a real project, replace this with actual patient data (CSV, database, etc.)
# Features: age, gender(0/1), bmi, blood_pressure, cholesterol, glucose, heart_rate, smoking(0/1)

np.random.seed(42)
n_samples = 5000

# Generate realistic distributions for each feature
age             = np.random.normal(50, 15, n_samples).clip(18, 90)
gender          = np.random.randint(0, 2, n_samples)          # 0=female, 1=male
bmi             = np.random.normal(27, 6, n_samples).clip(15, 50)
blood_pressure  = np.random.normal(120, 20, n_samples).clip(70, 200)
cholesterol     = np.random.normal(200, 40, n_samples).clip(100, 350)
glucose         = np.random.normal(110, 35, n_samples).clip(60, 300)
heart_rate      = np.random.normal(75, 15, n_samples).clip(40, 140)
smoking         = np.random.randint(0, 2, n_samples)

# Create risk score based on clinical thresholds (ground truth for training)
risk_score = (
    0.25 * (glucose > 126).astype(float) +
    0.20 * (glucose > 200).astype(float) +
    0.15 * (bmi > 30).astype(float) +
    0.10 * (bmi > 35).astype(float) +
    0.12 * (blood_pressure > 130).astype(float) +
    0.08 * (blood_pressure > 160).astype(float) +
    0.10 * (cholesterol > 240).astype(float) +
    0.06 * (cholesterol > 200).astype(float) +
    0.08 * (age > 50).astype(float) +
    0.05 * (age > 65).astype(float) +
    0.07 * smoking +
    0.04 * (heart_rate > 100).astype(float) +
    np.random.normal(0, 0.05, n_samples)   # small noise
).clip(0, 1)

# Convert continuous score to 3-class label
# 0 = Low Risk, 1 = Medium Risk, 2 = High Risk
labels = np.where(risk_score >= 0.55, 2, np.where(risk_score >= 0.30, 1, 0))

# Build DataFrame
df = pd.DataFrame({
    'age':            age,
    'gender':         gender,
    'bmi':            bmi,
    'blood_pressure': blood_pressure,
    'cholesterol':    cholesterol,
    'glucose':        glucose,
    'heart_rate':     heart_rate,
    'smoking':        smoking,
    'label':          labels
})

print(f"\nDataset shape: {df.shape}")
print(f"Class distribution:\n  Low Risk:    {(labels==0).sum()} ({(labels==0).mean()*100:.1f}%)")
print(f"  Medium Risk: {(labels==1).sum()} ({(labels==1).mean()*100:.1f}%)")
print(f"  High Risk:   {(labels==2).sum()} ({(labels==2).mean()*100:.1f}%)")

# ─── Step 2: Prepare Features ────────────────────────────────────────────────
feature_cols = ['age', 'gender', 'bmi', 'blood_pressure',
                'cholesterol', 'glucose', 'heart_rate', 'smoking']

X = df[feature_cols].values
y = df['label'].values

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y
)

# ─── Step 3: Scale Features ───────────────────────────────────────────────────
scaler = StandardScaler()
X_train_scaled = scaler.fit_transform(X_train)
X_test_scaled  = scaler.transform(X_test)

# ─── Step 4: Train Gradient Boosting Classifier ───────────────────────────────
print("\nTraining Gradient Boosting Classifier...")
model = GradientBoostingClassifier(
    n_estimators=200,
    max_depth=4,
    learning_rate=0.1,
    subsample=0.8,
    random_state=42
)
model.fit(X_train_scaled, y_train)

# ─── Step 5: Evaluate ─────────────────────────────────────────────────────────
y_pred = model.predict(X_test_scaled)
acc = accuracy_score(y_test, y_pred)
print(f"\nModel Accuracy: {acc*100:.2f}%")
print("\nClassification Report:")
print(classification_report(y_test, y_pred,
      target_names=['Low Risk', 'Medium Risk', 'High Risk']))

# ─── Step 6: Feature Importance ───────────────────────────────────────────────
importances = model.feature_importances_
print("Feature Importances:")
for name, imp in sorted(zip(feature_cols, importances), key=lambda x: -x[1]):
    bar = "█" * int(imp * 40)
    print(f"  {name:20s} {bar} {imp:.4f}")

# ─── Step 7: Save Model & Scaler ─────────────────────────────────────────────
os.makedirs("model", exist_ok=True)
joblib.dump(model,  "model/disease_risk_model.pkl")
joblib.dump(scaler, "model/scaler.pkl")

# Save feature names for reference
import json
with open("model/features.json", "w") as f:
    json.dump(feature_cols, f)

print("\n✅ Model saved to model/disease_risk_model.pkl")
print("✅ Scaler saved to model/scaler.pkl")
print("\nNow run: python app.py")
