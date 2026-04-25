import json
import numpy as np
import torch
import torch.nn as nn
from pathlib import Path
from typing import List, Dict, Optional

# ── Model Architecture (must match training exactly) ──────────────────────────
class OjasLSTM(nn.Module):
    def __init__(self, input_size=12, hidden_size=128, num_layers=2,
                 dropout=0.3, bidirectional=True):
        super().__init__()
        self.directions = 2 if bidirectional else 1
        self.lstm = nn.LSTM(
            input_size=input_size, hidden_size=hidden_size,
            num_layers=num_layers, batch_first=True,
            dropout=dropout if num_layers > 1 else 0.0,
            bidirectional=bidirectional
        )
        lstm_out_size = hidden_size * self.directions  # 256
        self.layer_norm = nn.LayerNorm(lstm_out_size)
        self.head = nn.Sequential(
            nn.Linear(lstm_out_size, 128), nn.ReLU(), nn.Dropout(dropout),
            nn.Linear(128, 64), nn.ReLU(), nn.Dropout(dropout / 2),
            nn.Linear(64, 1), nn.Sigmoid()
        )

    def forward(self, x):
        lstm_out, _ = self.lstm(x)
        last_step = lstm_out[:, -1, :]
        return self.head(self.layer_norm(last_step))


# ── Predictor Class ────────────────────────────────────────────────────────────
class OjasPredictor:
    """
    Singleton-safe LSTM inference wrapper.
    Load once at FastAPI startup. Call predict() per request.
    """

    FEATURE_COLS = [
        "food_quality_score", "viruddha_violations", "yoga_done",
        "yoga_accuracy_percent", "tongue_coating", "tongue_color",
        "eye_redness", "heart_rate_bpm", "sleep_quality",
        "stress_level", "energy_level", "days_since_last_violation"
    ]

    # Feature-level defaults: used when a day has missing data
    # Values represent a neutral/average day — not best, not worst
    FEATURE_DEFAULTS = {
        "food_quality_score":        50.0,
        "viruddha_violations":        1.0,
        "yoga_done":                  0.0,
        "yoga_accuracy_percent":      0.0,
        "tongue_coating":             2.5,
        "tongue_color":               1.0,
        "eye_redness":                1.5,
        "heart_rate_bpm":            72.0,
        "sleep_quality":             5.0,
        "stress_level":               3.0,
        "energy_level":               5.0,
        "days_since_last_violation":  3.0,
    }

    def __init__(self, model_path: str, normalizer_path: str):
        self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

        # Load normalizer
        with open(normalizer_path, "r") as f:
            norm = json.load(f)
        self.feat_min = np.array(norm["feature_min"], dtype=np.float32)
        self.feat_max = np.array(norm["feature_max"], dtype=np.float32)
        self.y_min    = float(norm["target_min"])
        self.y_max    = float(norm["target_max"])

        # Load model
        checkpoint = torch.load(model_path, map_location=self.device, weights_only=False)  # nosec: model is trusted internal artifact
        config = checkpoint["config"]

        self.model = OjasLSTM(
            input_size   = config["input_size"],    # 12
            hidden_size  = config["hidden_size"],   # 128
            num_layers   = config["num_layers"],    # 2
            dropout      = config["dropout"],       # 0.3
            bidirectional= config["bidirectional"]  # True
        ).to(self.device)

        self.model.load_state_dict(checkpoint["model_state"])
        self.model.eval()
        print(f"OjasPredictor loaded on {self.device}")

    def _normalise(self, raw_matrix: np.ndarray) -> np.ndarray:
        """Scale (7, 12) raw feature matrix to [0, 1]."""
        scale = self.feat_max - self.feat_min
        scale[scale == 0] = 1.0  # avoid div-by-zero for binary features
        normalised = (raw_matrix - self.feat_min) / scale
        return np.clip(normalised, 0.0, 1.0).astype(np.float32)

    def _denormalise_target(self, y_norm: float) -> float:
        """Convert normalised prediction back to ojas score [0, 100]."""
        return float(y_norm * (self.y_max - self.y_min) + self.y_min)

    def _fill_missing(self, day_features: Dict) -> Dict:
        """Fill missing keys with neutral defaults. Never fail on incomplete data."""
        filled = {}
        for feat in self.FEATURE_COLS:
            filled[feat] = float(day_features.get(feat, self.FEATURE_DEFAULTS[feat]))
        return filled

    def predict(self, seven_day_features: List[Dict]) -> Dict:
        """
        Main inference method.

        Args:
            seven_day_features: List of 7 dicts, each containing feature values
                                 for one day, in chronological order (oldest first).
                                 Missing keys are filled with neutral defaults.

        Returns:
            {
                "predicted_ojas":   float,   # predicted ojas score in 3 days
                "current_ojas_est": float,   # last known ojas context (from features)
                "direction":        str,     # "IMPROVE" | "STABLE" | "DECLINE"
                "delta":            float,   # predicted change from current context
                "alert_level":      str,     # "CLEAR" | "WATCH" | "WARNING" | "CRITICAL"
                "confidence":       str,     # "HIGH" | "MEDIUM" (based on data completeness)
                "missing_features": list,    # which features had defaults applied
            }
        """
        if len(seven_day_features) != 7:
            raise ValueError(f"Need exactly 7 days of features. Got {len(seven_day_features)}.")

        # Track which features were missing
        missing_features = []
        for i, day in enumerate(seven_day_features):
            for feat in self.FEATURE_COLS:
                if feat not in day or day[feat] is None:
                    missing_features.append(f"day{i+1}.{feat}")

        # Fill defaults and build matrix
        filled_days = [self._fill_missing(d) for d in seven_day_features]
        raw_matrix  = np.array(
            [[day[f] for f in self.FEATURE_COLS] for day in filled_days],
            dtype=np.float32
        )  # shape: (7, 12)

        # Normalise and run inference
        norm_matrix = self._normalise(raw_matrix)  # (7, 12)
        x_tensor    = torch.tensor(norm_matrix).unsqueeze(0).to(self.device)  # (1, 7, 12)

        with torch.no_grad():
            y_norm = self.model(x_tensor).item()  # scalar [0, 1]

        predicted_ojas = round(self._denormalise_target(y_norm), 1)

        # Current context: use last day's inferred ojas from energy/sleep signals
        # (ojas_score was excluded from features — estimate from correlated signals)
        last_day   = filled_days[-1]
        energy_est = last_day["energy_level"] * 10          # 0-100 scale
        sleep_est  = last_day["sleep_quality"] * 10         # 0-100 scale
        coat_pen   = last_day["tongue_coating"] * 10        # higher = worse
        current_est = round((energy_est * 0.5 + sleep_est * 0.3) - coat_pen * 0.2, 1)
        current_est = max(15.0, min(100.0, current_est))

        delta     = round(predicted_ojas - current_est, 1)
        direction = "IMPROVE" if delta > 2 else ("DECLINE" if delta < -2 else "STABLE")

        # Alert level — drives the intervention engine
        if predicted_ojas >= 65:
            alert_level = "CLEAR"
        elif predicted_ojas >= 50:
            alert_level = "WATCH"
        elif predicted_ojas >= 35:
            alert_level = "WARNING"
        else:
            alert_level = "CRITICAL"

        # Confidence: degrade if more than 20% of features were missing
        confidence = "HIGH" if len(missing_features) < len(self.FEATURE_COLS) * 7 * 0.2 else "MEDIUM"

        return {
            "predicted_ojas":   predicted_ojas,
            "current_ojas_est": current_est,
            "direction":        direction,
            "delta":            delta,
            "alert_level":      alert_level,
            "confidence":       confidence,
            "missing_features": missing_features
        }


# Global singleton instance
ojas_predictor_instance = None

def init_predictor(model_path: str, normalizer_path: str):
    global ojas_predictor_instance
    ojas_predictor_instance = OjasPredictor(model_path, normalizer_path)

def get_predictor() -> OjasPredictor:
    if ojas_predictor_instance is None:
        raise RuntimeError("OjasPredictor has not been initialized.")
    return ojas_predictor_instance
