import numpy as np
import pandas as pd
import json
import os
import random
from dataclasses import dataclass, field
from typing import Callable, List, Dict, Tuple

# ─────────────────────────────────────────────────────────────────────────────
# REPRODUCIBILITY
# ─────────────────────────────────────────────────────────────────────────────
GLOBAL_SEED = 42
np.random.seed(GLOBAL_SEED)
random.seed(GLOBAL_SEED)

# ─────────────────────────────────────────────────────────────────────────────
# CONFIG
# ─────────────────────────────────────────────────────────────────────────────
N_USERS_PER_ARCHETYPE = 75    # 75 × 4 archetypes = 300 users
DAYS_PER_USER         = 30    # 30 days per user
WINDOW_SIZE           = 7     # LSTM looks back 7 days
FORECAST_HORIZON      = 3     # predict ojas 3 days ahead
TRAIN_SPLIT           = 0.70
VAL_SPLIT             = 0.15
# Test = remaining 0.15

OUTPUT_DIR = r"C:\Users\ASUS\Desktop\OpenLoop\lstm"

FEATURE_NAMES = [
    "food_quality_score",       # 0–100   avg meal quality for the day
    "viruddha_violations",      # 0–5     count of incompatible food combos
    "yoga_done",                # 0 or 1  binary
    "yoga_accuracy_percent",    # 0–100   0 if yoga_done=0
    "ojas_score",               # 0–100   the main health score (also TARGET)
    "tongue_coating",           # 0–5     ama level (higher = worse)
    "tongue_color",             # 0–3     0=pink,1=pale,2=red,3=dark
    "eye_redness",              # 0–5     0=clear,5=severely red
    "heart_rate_bpm",           # 40–130  resting BPM
    "sleep_quality",            # 1–10    self-report (derived from ojas)
    "stress_level",             # 1–10    derived from nadi/dosha
    "energy_level",             # 1–10    composite
    "days_since_last_violation",# 0–30    memory feature
]

N_FEATURES = len(FEATURE_NAMES)

# Per-feature hard clamps [min, max] — LSTM inputs must stay in these ranges
FEATURE_CLAMPS = {
    "food_quality_score":        (0.0,  100.0),
    "viruddha_violations":       (0.0,    5.0),
    "yoga_done":                 (0.0,    1.0),
    "yoga_accuracy_percent":     (0.0,  100.0),
    "ojas_score":                (15.0, 100.0),
    "tongue_coating":            (0.0,    5.0),
    "tongue_color":              (0.0,    3.0),
    "eye_redness":               (0.0,    5.0),
    "heart_rate_bpm":            (40.0, 130.0),
    "sleep_quality":             (1.0,   10.0),
    "stress_level":              (1.0,   10.0),
    "energy_level":              (1.0,   10.0),
    "days_since_last_violation": (0.0,   30.0),
}

# ─────────────────────────────────────────────────────────────────────────────
# HELPER — Gaussian noise + clamped value
# ─────────────────────────────────────────────────────────────────────────────
def _n(mu: float, sigma: float, lo: float, hi: float) -> float:
    """Gaussian sample clamped to [lo, hi]."""
    return float(np.clip(np.random.normal(mu, sigma), lo, hi))

def _clamp(val: float, feature: str) -> float:
    lo, hi = FEATURE_CLAMPS[feature]
    return round(float(np.clip(val, lo, hi)), 2)

def _bernoulli(p: float) -> int:
    return 1 if np.random.random() < p else 0


# ─────────────────────────────────────────════════════════════════════════════
# ARCHETYPE DEFINITIONS
# Each archetype has:
#   baseline_*     : starting/resting values for this user type
#   trigger_prob   : probability any given day starts a trigger episode
#   trigger_duration: how many days the trigger episode lasts
#   drop_per_day   : ojas loss per day while trigger is active
#   recovery_rate  : ojas gain per day during clean recovery
#   biomarker_fn   : function(day, trigger_strength) → dict of deltas
# ─────────────────────────────────────────────────────────────────────────────

@dataclass
class Archetype:
    name:              str
    baseline_ojas:     float
    baseline_hr:       float
    baseline_coating:  float
    baseline_color:    float      # 0=pink, 1=pale, 2=red, 3=dark
    baseline_stress:   float
    baseline_energy:   float
    baseline_sleep:    float
    baseline_food_q:   float
    yoga_prob_healthy: float      # P(yoga) when not in trigger
    yoga_prob_trigger: float      # P(yoga) when trigger active
    trigger_prob:      float      # P(new episode starting on any clean day)
    trigger_duration:  int        # days episode lasts
    drop_per_day:      float
    recovery_rate:     float
    # Biomarker response signatures during trigger
    coating_rise:      float      # how much coating rises per trigger day
    color_on_trigger:  float      # tongue_color during trigger
    redness_rise:      float      # eye_redness rise per trigger day
    hr_shift:          float      # +/- BPM during trigger (neg for Kapha)
    stress_rise:       float
    energy_drop:       float
    sleep_drop:        float
    food_q_drop:       float
    viruddha_lambda:   float      # Poisson lambda for viruddha count
    viruddha_lambda_t: float      # Poisson lambda during trigger


# ─────────────────────────────────────────────────────────────────────────────
# THE 4 ARCHETYPES — tuned from roadmap Ayurvedic rules
# ─────────────────────────────────────────────────────────────────────────────

ARCHETYPES: List[Archetype] = [

    # ── 1. PITTA WORKER ──────────────────────────────────────────────────────
    # High-functioning, driven. Eats spicy/oily food, overworks.
    # Trigger: viruddha food + late nights → Pitta aggravation
    # Signature: tongue goes red, HR spikes, eye redness rises fast
    Archetype(
        name              = "pitta_worker",
        baseline_ojas     = 70.0,
        baseline_hr       = 72.0,
        baseline_coating  = 1.5,
        baseline_color    = 1.0,    # starts pale (mild pitta)
        baseline_stress   = 3.0,
        baseline_energy   = 7.5,
        baseline_sleep    = 7.0,
        baseline_food_q   = 65.0,
        yoga_prob_healthy = 0.68,
        yoga_prob_trigger = 0.22,
        trigger_prob      = 0.18,
        trigger_duration  = 7,
        drop_per_day      = 4.0,
        recovery_rate     = 3.0,
        coating_rise      = 0.5,
        color_on_trigger  = 2.0,    # red/inflamed
        redness_rise      = 0.9,
        hr_shift          = +11.0,  # HR rises
        stress_rise       = 2.5,
        energy_drop       = 2.5,
        sleep_drop        = 2.0,
        food_q_drop       = 22.0,
        viruddha_lambda   = 0.3,
        viruddha_lambda_t = 2.2,
    ),

    # ── 2. VATA IRREGULAR ────────────────────────────────────────────────────
    # Anxious, inconsistent routine. Skips yoga, irregular eating.
    # Trigger: 3+ days no yoga + chronic stress
    # Signature: tongue goes pale (dry), energy crashes, slow recovery
    Archetype(
        name              = "vata_irregular",
        baseline_ojas     = 63.0,
        baseline_hr       = 68.0,
        baseline_coating  = 2.0,    # already somewhat coated
        baseline_color    = 1.0,    # pale baseline
        baseline_stress   = 4.0,    # already stressed
        baseline_energy   = 6.0,
        baseline_sleep    = 6.0,
        baseline_food_q   = 58.0,
        yoga_prob_healthy = 0.50,   # inconsistent even when healthy
        yoga_prob_trigger = 0.10,
        trigger_prob      = 0.22,
        trigger_duration  = 8,
        drop_per_day      = 3.0,
        recovery_rate     = 1.5,    # slow recovery (Vata)
        coating_rise      = 1.0,    # Vata dryness → coating rises
        color_on_trigger  = 0.0,    # pale (Vata = pale tongue)
        redness_rise      = 0.4,
        hr_shift          = +5.0,   # slight HR variability
        stress_rise       = 2.0,
        energy_drop       = 3.5,
        sleep_drop        = 1.5,
        food_q_drop       = 18.0,
        viruddha_lambda   = 0.5,    # more likely to eat wrong combos
        viruddha_lambda_t = 1.5,
    ),

    # ── 3. KAPHA SEDENTARY ───────────────────────────────────────────────────
    # Slow metabolism, comfort eater, avoids exercise.
    # Trigger: low food quality + no yoga for 4+ days
    # Signature: heavy tongue coating, HR drops (sluggish), sleeps too much
    Archetype(
        name              = "kapha_sedentary",
        baseline_ojas     = 58.0,
        baseline_hr       = 62.0,   # already low (Kapha = slow)
        baseline_coating  = 2.5,    # already coated
        baseline_color    = 1.0,    # pale-ish
        baseline_stress   = 2.5,    # low stress (Kapha = calm/inert)
        baseline_energy   = 4.5,
        baseline_sleep    = 8.5,    # oversleeps
        baseline_food_q   = 48.0,
        yoga_prob_healthy = 0.30,   # rarely does yoga
        yoga_prob_trigger = 0.05,
        trigger_prob      = 0.25,   # triggers easily due to sedentary baseline
        trigger_duration  = 9,
        drop_per_day      = 2.0,    # slow decline (Kapha = heavy but gradual)
        recovery_rate     = 1.0,    # very slow recovery
        coating_rise      = 1.5,    # Kapha = heavy coating
        color_on_trigger  = 1.0,    # stays pale (Kapha white)
        redness_rise      = 0.2,    # minimal redness (Kapha is cool)
        hr_shift          = -4.0,   # HR DROPS further (sluggish)
        stress_rise       = 0.5,
        energy_drop       = 2.0,
        sleep_drop        = -1.5,   # paradox: sleep INCREASES (oversleeping)
        food_q_drop       = 15.0,
        viruddha_lambda   = 0.4,
        viruddha_lambda_t = 1.2,
    ),

    # ── 4. BALANCED HEALTHY ──────────────────────────────────────────────────
    # Consistent routine, good food, regular yoga. Minor fluctuations only.
    # Trigger: only on rare bad days (3+ viruddha violations)
    # Signature: quick dip, fast recovery — LSTM learns this as "resilient"
    Archetype(
        name              = "balanced_healthy",
        baseline_ojas     = 80.0,
        baseline_hr       = 70.0,
        baseline_coating  = 1.0,
        baseline_color    = 0.0,    # pink/healthy baseline
        baseline_stress   = 2.0,
        baseline_energy   = 8.5,
        baseline_sleep    = 8.0,
        baseline_food_q   = 74.0,
        yoga_prob_healthy = 0.82,
        yoga_prob_trigger = 0.60,   # even in bad days, often still does yoga
        trigger_prob      = 0.10,   # rarely triggered
        trigger_duration  = 5,
        drop_per_day      = 2.0,
        recovery_rate     = 4.0,    # fastest recovery
        coating_rise      = 0.3,
        color_on_trigger  = 1.0,    # mild — just pale
        redness_rise      = 0.3,
        hr_shift          = +5.0,
        stress_rise       = 1.0,
        energy_drop       = 1.5,
        sleep_drop        = 0.5,
        food_q_drop       = 12.0,
        viruddha_lambda   = 0.15,   # rarely eats wrong combos
        viruddha_lambda_t = 1.8,
    ),
]


# ─────────────────────────────────────────────────────────────────────────────
# TRAJECTORY GENERATOR
# Simulates one user's 30-day health journey
# ─────────────────────────────────────────────────────────────────────────────

def generate_trajectory(arch: Archetype, n_days: int = 30, user_seed: int = 0) -> List[Dict]:
    """
    Generates a sequence of daily health feature vectors for one user.

    State machine:
      HEALTHY → trigger fires → DECLINING (trigger_duration days) → RECOVERING → HEALTHY

    Inter-feature correlations are explicitly modelled:
      - tongue_coating and tongue_color move together with ojas decline
      - eye_redness lags ojas by 1-2 days (body takes time to show in eyes)
      - heart_rate_bpm responds immediately to trigger
      - energy_level is a weighted composite of ojas + tongue + sleep
      - stress_level is an input driver (it causes ojas drop, not vice versa)
    """
    rng = np.random.default_rng(GLOBAL_SEED + user_seed)

    # Personalise baseline with per-user noise (±10% variation between users)
    ojas         = float(rng.normal(arch.baseline_ojas, 5))
    hr_base      = float(rng.normal(arch.baseline_hr,   3))
    coating_base = float(rng.normal(arch.baseline_coating, 0.3))

    # State
    trigger_days_remaining = 0
    trigger_strength       = 0.0   # 0→1 ramp, creates gradual onset
    last_violation_day     = -10   # how long since last viruddha
    eye_lag_buffer         = [0.0, 0.0]  # 2-day lag for eye redness
    prev_coating           = coating_base

    days = []

    for day_idx in range(n_days):
        in_trigger = trigger_days_remaining > 0

        # Trigger strength ramps up over first 2 days, full effect day 3+
        if in_trigger:
            days_into_trigger = arch.trigger_duration - trigger_days_remaining
            trigger_strength  = min(1.0, days_into_trigger / 2.0)
        else:
            trigger_strength = 0.0

        ts = trigger_strength  # shorthand

        # ── FOOD ─────────────────────────────────────────────────────────────
        food_q    = _n(arch.baseline_food_q - arch.food_q_drop * ts,
                       sigma=10, lo=15, hi=100)
        viruddha  = int(rng.poisson(
            arch.viruddha_lambda_t * ts + arch.viruddha_lambda * (1 - ts)
        ))
        viruddha  = min(viruddha, 5)

        # ── YOGA ─────────────────────────────────────────────────────────────
        yoga_p    = arch.yoga_prob_trigger * ts + arch.yoga_prob_healthy * (1 - ts)
        yoga_done = int(rng.random() < yoga_p)
        yoga_acc  = float(rng.normal(78, 10)) if yoga_done else 0.0
        yoga_acc  = float(np.clip(yoga_acc, 0, 100))

        # ── TONGUE ───────────────────────────────────────────────────────────
        # Coating rises gradually with trigger, has inertia (coats slowly, clears slowly)
        target_coating = (coating_base + arch.coating_rise * ts * arch.trigger_duration * 0.25)
        # Inertia: coating moves toward target at 30% per day
        new_coating = prev_coating + 0.30 * (target_coating - prev_coating)
        new_coating += float(rng.normal(0, 0.15))
        tongue_coating = _clamp(new_coating, "tongue_coating")
        prev_coating   = tongue_coating

        # Color is determined by trigger state (discrete signal)
        if in_trigger and trigger_strength > 0.5:
            tongue_color = arch.color_on_trigger + float(rng.normal(0, 0.1))
        else:
            tongue_color = arch.baseline_color + float(rng.normal(0, 0.15))
        tongue_color = _clamp(round(tongue_color, 1), "tongue_color")

        # ── EYE — 2-day lag ──────────────────────────────────────────────────
        # Today's redness is driven by 2 days ago's ojas drop severity
        eye_signal       = arch.redness_rise * eye_lag_buffer[0]
        eye_redness_raw  = float(rng.normal(1.0 + eye_signal, 0.3))
        eye_redness      = _clamp(eye_redness_raw, "eye_redness")
        # Update lag buffer
        eye_lag_buffer   = [ts, eye_lag_buffer[0]]

        # ── HEART RATE ───────────────────────────────────────────────────────
        hr = hr_base + arch.hr_shift * ts + float(rng.normal(0, 3))
        hr = _clamp(hr, "heart_rate_bpm")

        # ── SLEEP ────────────────────────────────────────────────────────────
        # Kapha: sleep_drop is negative (sleep increases) — handled by sign
        sleep = float(rng.normal(
            arch.baseline_sleep - arch.sleep_drop * ts, 0.8
        ))
        sleep = _clamp(sleep, "sleep_quality")

        # ── STRESS ───────────────────────────────────────────────────────────
        stress = float(rng.normal(
            arch.baseline_stress + arch.stress_rise * ts, 0.7
        ))
        stress = _clamp(stress, "stress_level")

        # ── ENERGY — composite ───────────────────────────────────────────────
        # energy is driven by ojas (main), reduced by coating and redness
        energy_from_ojas    = (ojas / 100) * 10
        energy_from_coating = -tongue_coating * 0.3
        energy_from_eye     = -eye_redness * 0.2
        energy_from_sleep   = (sleep - 5) * 0.2
        energy = (energy_from_ojas + energy_from_coating +
                  energy_from_eye  + energy_from_sleep  +
                  float(rng.normal(0, 0.5)))
        energy = _clamp(energy, "energy_level")

        # ── DAYS SINCE LAST VIOLATION ─────────────────────────────────────────
        if viruddha > 0:
            last_violation_day  = day_idx
        days_since_v = min(day_idx - last_violation_day, 30)

        # ── RECORD THE DAY ────────────────────────────────────────────────────
        day_record = {
            "food_quality_score":        round(food_q, 1),
            "viruddha_violations":       viruddha,
            "yoga_done":                 yoga_done,
            "yoga_accuracy_percent":     round(yoga_acc, 1),
            "ojas_score":                round(ojas, 1),
            "tongue_coating":            tongue_coating,
            "tongue_color":              tongue_color,
            "eye_redness":               eye_redness,
            "heart_rate_bpm":            round(hr, 1),
            "sleep_quality":             round(sleep, 1),
            "stress_level":              round(stress, 1),
            "energy_level":              round(energy, 2),
            "days_since_last_violation": int(days_since_v),
        }

        # ── UPDATE OJAS (STATE TRANSITION) ────────────────────────────────────
        if in_trigger:
            # Decline phase — drop modulated by trigger strength
            ojas -= (arch.drop_per_day + float(rng.normal(0, 1.2))) * trigger_strength
            trigger_days_remaining -= 1
        else:
            # Recovery phase — yoga accelerates recovery
            yoga_recovery = arch.recovery_rate * yoga_done
            ojas += yoga_recovery * 0.7 + float(rng.normal(0, 0.8))
            # Cap recovery at baseline (can't exceed starting point without intervention)
            ojas  = min(arch.baseline_ojas, ojas)

        ojas = _clamp(ojas, "ojas_score")

        # ── CHECK FOR NEW TRIGGER ─────────────────────────────────────────────
        # Only triggers when user is in a clean/healthy state
        if not in_trigger and rng.random() < arch.trigger_prob:
            trigger_days_remaining = arch.trigger_duration

        days.append(day_record)

    return days


# ─────────────────────────────────────────────────────────────────────────────
# DATASET BUILDER
# ─────────────────────────────────────────────────────────────────────────────

def build_dataset() -> Tuple[np.ndarray, np.ndarray, pd.DataFrame]:
    """
    Generates all users, builds sliding windows, returns:
      X_all   : (N_sequences, WINDOW_SIZE, N_FEATURES)
      y_all   : (N_sequences,)  — ojas_score at window_end + FORECAST_HORIZON
      raw_df  : full 9000-row flat DataFrame (for CSV export and inspection)
    """
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    all_sequences_X = []
    all_sequences_y = []
    raw_rows        = []
    user_id_counter = 0

    print("\n  Generating trajectories...")
    for arch in ARCHETYPES:
        arch_seq_count = 0
        for u in range(N_USERS_PER_ARCHETYPE):
            user_id      = f"{arch.name}_{u:03d}"
            user_seed    = user_id_counter
            user_id_counter += 1

            trajectory = generate_trajectory(arch, n_days=DAYS_PER_USER, user_seed=user_seed)

            # Flat rows for CSV
            for day_idx, day in enumerate(trajectory):
                row = {"user_id": user_id, "archetype": arch.name, "day": day_idx}
                row.update(day)
                raw_rows.append(row)

            # Sliding windows: [d : d+7] → label = ojas at d+7+3 = d+10
            n_windows = DAYS_PER_USER - WINDOW_SIZE - FORECAST_HORIZON
            for start in range(n_windows):
                window = trajectory[start : start + WINDOW_SIZE]
                label  = trajectory[start + WINDOW_SIZE + FORECAST_HORIZON - 1]["ojas_score"]

                x_seq = [[day[f] for f in FEATURE_NAMES] for day in window]
                all_sequences_X.append(x_seq)
                all_sequences_y.append(label)
                arch_seq_count += 1

        print(f"    {arch.name:<20} {N_USERS_PER_ARCHETYPE} users  "
              f"{arch_seq_count} sequences")

    X = np.array(all_sequences_X, dtype=np.float32)  # (N, 7, 13)
    y = np.array(all_sequences_y, dtype=np.float32)  # (N,)
    raw_df = pd.DataFrame(raw_rows)

    return X, y, raw_df


# ─────────────────────────────────────────────────────────────────────────────
# NORMALISATION
# Computed on TRAIN SET ONLY — applied to all sets to prevent leakage
# ─────────────────────────────────────────────────────────────────────────────

def normalise(X_train, X_val, X_test):
    """
    Per-feature MinMax normalisation.
    Fit on X_train, transform X_train/X_val/X_test.
    Returns normalised arrays + params dict.
    """
    N_train, W, F = X_train.shape

    X_flat   = X_train.reshape(-1, F)
    feat_min = X_flat.min(axis=0)   # (F,)
    feat_max = X_flat.max(axis=0)   # (F,)
    feat_range = feat_max - feat_min + 1e-8

    def _scale(X):
        shape = X.shape
        Xf = X.reshape(-1, F)
        Xs = (Xf - feat_min) / feat_range
        return Xs.reshape(shape).astype(np.float32)

    X_train_n = _scale(X_train)
    X_val_n   = _scale(X_val)
    X_test_n  = _scale(X_test)

    params = {
        "features":      FEATURE_NAMES,
        "min":           feat_min.tolist(),
        "max":           feat_max.tolist(),
        "range":         feat_range.tolist(),
        "n_features":    F,
        "window_size":   WINDOW_SIZE,
        "forecast_days": FORECAST_HORIZON,
    }

    return X_train_n, X_val_n, X_test_n, params


# ─────────────────────────────────────────────────────────────────────────────
# TRAIN / VAL / TEST SPLIT  (split by user count, not by row)
# ─────────────────────────────────────────────────────────────────────────────

def split_by_user(X: np.ndarray, y: np.ndarray) -> Tuple:
    """
    Users are ordered: [pitta×75, vata×75, kapha×75, balanced×75]
    Each user contributes (DAYS - WINDOW - HORIZON) = 20 sequences.
    We split at user boundaries to prevent data leakage.
    """
    seqs_per_user = DAYS_PER_USER - WINDOW_SIZE - FORECAST_HORIZON  # = 20
    total_users   = N_USERS_PER_ARCHETYPE * len(ARCHETYPES)          # = 300

    n_train_users = int(total_users * TRAIN_SPLIT)   # 210
    n_val_users   = int(total_users * VAL_SPLIT)     # 45
    # n_test_users  = 45

    i_train = n_train_users * seqs_per_user
    i_val   = i_train + n_val_users * seqs_per_user

    X_train, X_val, X_test = X[:i_train], X[i_train:i_val], X[i_val:]
    y_train, y_val, y_test = y[:i_train], y[i_train:i_val], y[i_val:]

    return (X_train, y_train), (X_val, y_val), (X_test, y_test)


# ─────────────────────────────────────────────────────────────────────────────
# QUALITY AUDIT
# ─────────────────────────────────────────────────────────────────────────────

def audit_dataset(raw_df: pd.DataFrame, X: np.ndarray, y: np.ndarray,
                  norm_params: dict) -> str:
    lines = []
    lines.append("═" * 64)
    lines.append("  AYUSH LSTM DATASET — QUALITY AUDIT REPORT")
    lines.append("═" * 64)

    # Shape
    lines.append(f"\n  SHAPES")
    lines.append(f"  {'raw rows':<28} {len(raw_df):,}")
    lines.append(f"  {'X sequences':<28} {X.shape}")
    lines.append(f"  {'y labels':<28} {y.shape}")

    # Archetype distribution
    lines.append(f"\n  ARCHETYPE DISTRIBUTION")
    for arch in ARCHETYPES:
        n = len(raw_df[raw_df["archetype"] == arch.name])
        lines.append(f"  {arch.name:<20} {n:>5} rows")

    # Label (ojas) distribution
    lines.append(f"\n  TARGET (ojas_score) DISTRIBUTION")
    lines.append(f"  {'min':<20} {y.min():.2f}")
    lines.append(f"  {'max':<20} {y.max():.2f}")
    lines.append(f"  {'mean':<20} {y.mean():.2f}")
    lines.append(f"  {'std':<20} {y.std():.2f}")
    q = np.percentile(y, [10, 25, 50, 75, 90])
    lines.append(f"  {'p10/p25/p50/p75/p90':<20} {q[0]:.1f} / {q[1]:.1f} / {q[2]:.1f} / {q[3]:.1f} / {q[4]:.1f}")

    # Per-feature stats (pre-normalisation)
    lines.append(f"\n  FEATURE STATISTICS (pre-normalisation)")
    lines.append(f"  {'Feature':<30} {'Mean':>8} {'Std':>8} {'Min':>8} {'Max':>8}")
    lines.append(f"  {'─'*66}")
    for i, feat in enumerate(FEATURE_NAMES):
        col = X[:, :, i].flatten()
        lines.append(f"  {feat:<30} {col.mean():>8.2f} {col.std():>8.2f} "
                     f"{col.min():>8.2f} {col.max():>8.2f}")

    # Correlation: each feature vs ojas label
    lines.append(f"\n  FEATURE-TARGET CORRELATION (|r| with ojas_score label)")
    lines.append(f"  Higher = feature is more predictive of ojas")
    lines.append(f"  {'─'*50}")
    last_day_X = X[:, -1, :]  # last day of each window (most recent signal)
    correlations = []
    for i, feat in enumerate(FEATURE_NAMES):
        r = float(np.corrcoef(last_day_X[:, i], y)[0, 1])
        correlations.append((feat, r))
    correlations.sort(key=lambda x: abs(x[1]), reverse=True)
    for feat, r in correlations:
        bar = "█" * int(abs(r) * 20)
        sign = "+" if r >= 0 else "-"
        lines.append(f"  {feat:<30} {sign}{abs(r):.3f}  {bar}")

    # Normalisation params
    lines.append(f"\n  NORMALISATION PARAMS (fit on train set)")
    lines.append(f"  {'Feature':<30} {'Min':>8} {'Max':>8}")
    lines.append(f"  {'─'*50}")
    for i, feat in enumerate(FEATURE_NAMES):
        lines.append(f"  {feat:<30} {norm_params['min'][i]:>8.2f} "
                     f"{norm_params['max'][i]:>8.2f}")

    # Data quality checks
    lines.append(f"\n  DATA QUALITY CHECKS")
    nan_count = np.isnan(X).sum() + np.isnan(y).sum()
    lines.append(f"  {'NaN values':<30} {nan_count}  {'✔ PASS' if nan_count == 0 else '✘ FAIL'}")
    inf_count = np.isinf(X).sum() + np.isinf(y).sum()
    lines.append(f"  {'Inf values':<30} {inf_count}  {'✔ PASS' if inf_count == 0 else '✘ FAIL'}")
    oob = ((X < 0) | (X > 1)).sum()
    lines.append(f"  {'Out-of-range (post-norm)':<30} {oob}  {'✔ PASS' if oob == 0 else '✘ FAIL'}")

    lines.append(f"\n  FILES WRITTEN")
    lines.append(f"  {OUTPUT_DIR}/synthetic_raw.csv        — 9,000 row flat dataset")
    lines.append(f"  {OUTPUT_DIR}/X_train.npy              — (N_train, 7, 13) normalised")
    lines.append(f"  {OUTPUT_DIR}/y_train.npy              — (N_train,) labels")
    lines.append(f"  {OUTPUT_DIR}/X_val.npy                — (N_val, 7, 13) normalised")
    lines.append(f"  {OUTPUT_DIR}/y_val.npy                — (N_val,) labels")
    lines.append(f"  {OUTPUT_DIR}/X_test.npy               — (N_test, 7, 13) normalised")
    lines.append(f"  {OUTPUT_DIR}/y_test.npy               — (N_test,) labels")
    lines.append(f"  {OUTPUT_DIR}/normalizer_params.json   — min/max per feature")
    lines.append(f"  {OUTPUT_DIR}/dataset_report.txt       — this report")

    lines.append(f"\n  LSTM INPUT SPEC")
    lines.append(f"  {'input shape':<28} (batch, {WINDOW_SIZE}, {N_FEATURES})")
    lines.append(f"  {'output shape':<28} (batch, 1)  — ojas_score in [0,100]")
    lines.append(f"  {'sequence length':<28} {WINDOW_SIZE} days")
    lines.append(f"  {'forecast horizon':<28} +{FORECAST_HORIZON} days")
    lines.append(f"  {'features':<28} {N_FEATURES} (all normalised to [0,1])")
    lines.append(f"\n{'═'*64}\n")

    return "\n".join(lines)


# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────

def main():
    print("\n\033[1m\033[94m  AYUSH — SYNTHETIC LSTM DATASET GENERATOR\033[0m")
    print(f"  \033[2m{N_USERS_PER_ARCHETYPE} users × {len(ARCHETYPES)} archetypes × "
          f"{DAYS_PER_USER} days = "
          f"{N_USERS_PER_ARCHETYPE * len(ARCHETYPES) * DAYS_PER_USER:,} raw rows\033[0m\n")

    os.makedirs(OUTPUT_DIR, exist_ok=True)

    # ── 1. Generate ───────────────────────────────────────────────────────────
    X_all, y_all, raw_df = build_dataset()
    print(f"\n  \033[92m✔  Generated: X={X_all.shape}  y={y_all.shape}\033[0m")

    # ── 2. Split ──────────────────────────────────────────────────────────────
    (X_train, y_train), (X_val, y_val), (X_test, y_test) = split_by_user(X_all, y_all)
    print(f"  \033[92m✔  Split:  train={X_train.shape[0]}  "
          f"val={X_val.shape[0]}  test={X_test.shape[0]}\033[0m")

    # ── 3. Normalise ──────────────────────────────────────────────────────────
    X_train_n, X_val_n, X_test_n, norm_params = normalise(X_train, X_val, X_test)
    print(f"  \033[92m✔  Normalised (MinMax fit on train set)\033[0m")

    # ── 4. Save ───────────────────────────────────────────────────────────────
    raw_df.to_csv(f"{OUTPUT_DIR}/synthetic_raw.csv", index=False)

    np.save(f"{OUTPUT_DIR}/X_train.npy", X_train_n)
    np.save(f"{OUTPUT_DIR}/y_train.npy", y_train)
    np.save(f"{OUTPUT_DIR}/X_val.npy",   X_val_n)
    np.save(f"{OUTPUT_DIR}/y_val.npy",   y_val)
    np.save(f"{OUTPUT_DIR}/X_test.npy",  X_test_n)
    np.save(f"{OUTPUT_DIR}/y_test.npy",  y_test)

    with open(f"{OUTPUT_DIR}/normalizer_params.json", "w") as f:
        json.dump(norm_params, f, indent=2)

    # ── 5. Audit ──────────────────────────────────────────────────────────────
    report = audit_dataset(raw_df, X_train_n, y_train, norm_params)
    print(f"\n{report}")

    with open(f"{OUTPUT_DIR}/dataset_report.txt", "w", encoding="utf-8") as f:
        f.write(report)

    print(f"  \033[1m\033[92m✔  All files written to ./{OUTPUT_DIR}/\033[0m")
    print(f"  \033[2m  Next step: python train_ojas_lstm.py\033[0m\n")


if __name__ == "__main__":
    main()
