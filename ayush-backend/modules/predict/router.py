from fastapi import APIRouter, HTTPException, Depends
from datetime import date, timedelta
from database.mongodb import get_db
from modules.predict.ojas_predictor import OjasPredictor, get_predictor

router = APIRouter(prefix="/api/v1/predict", tags=["Prediction"])


async def _fetch_7day_features(user_id: str) -> list:
    """
    Fetches the last 7 consolidated daily_logs for a user.
    Returns a list of 12-feature dicts in chronological order.
    Returns None if fewer than 7 days exist.
    """
    db = get_db()
    daily_logs_collection = db["daily_logs"]
    
    today = date.today()
    feature_docs = []

    for i in range(6, -1, -1):  # day-6 (oldest) to day-0 (today)
        target_date = (today - timedelta(days=i)).isoformat()

        doc = await daily_logs_collection.find_one(
            {"userId": user_id, "date": target_date, "consolidated": True}
        )

        if not doc or "features" not in doc:
            # Day has no data — pass empty dict, predictor will use defaults
            feature_docs.append({})
        else:
            feat = doc["features"]
            # Only pass the 12 features the model knows about (NOT ojas_score)
            feature_docs.append({
                "food_quality_score":        feat.get("food_quality_score"),
                "viruddha_violations":       feat.get("viruddha_violations"),
                "yoga_done":                 feat.get("yoga_done"),
                "yoga_accuracy_percent":     feat.get("yoga_accuracy_percent"),
                "tongue_coating":            feat.get("tongue_coating"),
                "tongue_color":              feat.get("tongue_color"),
                "eye_redness":               feat.get("eye_redness"),
                "heart_rate_bpm":            feat.get("heart_rate_bpm"),
                "sleep_quality":             feat.get("sleep_quality"),
                "stress_level":              feat.get("stress_level"),
                "energy_level":              feat.get("energy_level"),
                "days_since_last_violation": feat.get("days_since_last_violation"),
            })

    return feature_docs


@router.get("/ojas/{user_id}")
async def predict_ojas(
    user_id: str,
    predictor: OjasPredictor = Depends(get_predictor)
):
    """
    Main prediction endpoint. Called once per day per user,
    triggered when the user opens the Home screen.

    Returns the OJAS prediction for 3 days from now,
    plus alert level and intervention triggers.
    """
    db = get_db()
    daily_logs_collection = db["daily_logs"]
    users_collection = db["users"]
    
    # Fetch 7 days of features from MongoDB
    seven_days = await _fetch_7day_features(user_id)

    # Run inference
    try:
        result = predictor.predict(seven_days)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

    # Determine which biomarker signals are most alarming
    # Used by Flutter to show the signal breakdown grid
    latest_features = seven_days[-1]
    signal_flags = _compute_signal_flags(latest_features)

    # Generate archetype-aware intervention text
    user_doc = await users_collection.find_one({"userId": user_id})
    prakriti  = user_doc.get("prakriti", "vata") if user_doc else "vata"
    interventions = _get_interventions(result["alert_level"], signal_flags, prakriti)

    # Persist prediction back to today's daily_log (for tracking model accuracy later)
    today = date.today().isoformat()
    await daily_logs_collection.update_one(
        {"userId": user_id, "date": today},
        {"$set": {
            "prediction.predicted_ojas_day3": result["predicted_ojas"],
            "prediction.predicted_on":        today,
            "prediction.alert_level":         result["alert_level"],
        }},
        upsert=True
    )

    return {
        "user_id":          user_id,
        "predicted_ojas":   result["predicted_ojas"],
        "current_ojas_est": result["current_ojas_est"],
        "direction":        result["direction"],
        "delta":            result["delta"],
        "alert_level":      result["alert_level"],    # "CLEAR"|"WATCH"|"WARNING"|"CRITICAL"
        "confidence":       result["confidence"],
        "horizon_days":     3,
        "signal_flags":     signal_flags,             # for Health Radar UI
        "interventions":    interventions,            # for intervention cards
        "missing_features": result["missing_features"]
    }


@router.get("/history/{user_id}")
async def get_prediction_history(user_id: str):
    """
    Returns last 30 days of daily_logs for the OJAS trend chart.
    Called by Health Radar screen on load.
    """
    db = get_db()
    daily_logs_collection = db["daily_logs"]
    
    today = date.today()
    history = []

    for i in range(29, -1, -1):
        d = (today - timedelta(days=i)).isoformat()
        doc = await daily_logs_collection.find_one(
            {"userId": user_id, "date": d}
        )
        if doc and "features" in doc:
            history.append({
                "date":          d,
                "ojas_score":    doc["features"].get("ojas_score"),
                "energy_level":  doc["features"].get("energy_level"),
                "stress_level":  doc["features"].get("stress_level"),
                "tongue_coating":doc["features"].get("tongue_coating"),
                "predicted_ojas":doc.get("prediction", {}).get("predicted_ojas_day3"),
                "alert_level":   doc.get("prediction", {}).get("alert_level"),
            })
        else:
            history.append({"date": d, "ojas_score": None})

    return {"user_id": user_id, "history": history}


# ── Internal helpers ──────────────────────────────────────────────────────────

def _compute_signal_flags(features: dict) -> dict:
    """
    Identifies which biomarkers are in alarming range.
    Returns structured flags for the Flutter signal grid.
    """
    return {
        "food_quality":    "BAD"     if (features.get("food_quality_score") or 50) < 40 else
                           "NEUTRAL" if (features.get("food_quality_score") or 50) < 65 else "GOOD",
        "yoga":            "BAD"     if not features.get("yoga_done") else "GOOD",
        "tongue_coating":  "BAD"     if (features.get("tongue_coating") or 0) > 3.0 else
                           "NEUTRAL" if (features.get("tongue_coating") or 0) > 2.0 else "GOOD",
        "heart_rate":      "BAD"     if (features.get("heart_rate_bpm") or 72) > 90 else
                           "NEUTRAL" if (features.get("heart_rate_bpm") or 72) > 80 else "GOOD",
        "sleep":           "BAD"     if (features.get("sleep_quality") or 5) < 4 else
                           "NEUTRAL" if (features.get("sleep_quality") or 5) < 6 else "GOOD",
        "stress":          "BAD"     if (features.get("stress_level") or 3) > 4 else
                           "NEUTRAL" if (features.get("stress_level") or 3) > 3 else "GOOD",
        "eye_redness":     "BAD"     if (features.get("eye_redness") or 0) > 2.5 else "GOOD",
        "viruddha":        "BAD"     if (features.get("viruddha_violations") or 0) >= 2 else "GOOD",
    }


def _get_interventions(alert_level: str, signal_flags: dict, prakriti: str) -> list:
    """
    Returns 2-4 ranked, prakriti-specific intervention cards.
    Priority: highest-impact signals for this prakriti type first.
    """
    base = []

    if signal_flags.get("tongue_coating") == "BAD":
        base.append({
            "priority": 1,
            "type":     "dietary",
            "action":   "Tongue scrape at dawn. Drink warm ginger water before any food.",
            "why":      "Ama (tongue coating) has risen to critical level — digestion is compromised."
        })

    if signal_flags.get("yoga") == "BAD":
        base.append({
            "priority": 2,
            "type":     "movement",
            "action":   "20-minute yoga session today — even gentle Surya Namaskar.",
            "why":      "Missed yoga is accelerating the OJAS decline. Movement is non-negotiable."
        })

    if signal_flags.get("sleep") == "BAD":
        base.append({
            "priority": 1,
            "type":     "sleep",
            "action":   "Set a hard sleep boundary at 10pm for the next 3 days.",
            "why":      "Sleep is the #1 OJAS regenerator. Nothing else compensates for this."
        })

    if signal_flags.get("food_quality") == "BAD":
        if prakriti == "pitta":
            base.append({
                "priority": 2,
                "type":     "dietary",
                "action":   "Avoid fried, spicy, and fermented foods. Eat cooling foods: cucumber, coconut water, coriander.",
                "why":      "Pitta is aggravated. Hot, oily food is driving the inflammation markers up."
            })
        elif prakriti == "vata":
            base.append({
                "priority": 2,
                "type":     "dietary",
                "action":   "Eat warm, oily, grounding food. Ghee with rice. No raw salads.",
                "why":      "Vata is aggravated by irregular, dry, or cold food. Stability in diet is critical."
            })
        else:  # kapha
            base.append({
                "priority": 2,
                "type":     "dietary",
                "action":   "Light meals only. Avoid dairy and heavy grains. Favor bitter, pungent, astringent tastes.",
                "why":      "Kapha accumulation is worsening. Light food prevents further ama buildup."
            })

    if signal_flags.get("stress") == "BAD":
        if prakriti == "pitta":
            base.append({
                "priority": 3,
                "type":     "breathing",
                "action":   "Sheetali pranayama (cooling breath) at sunset. 10 rounds.",
                "why":      "Stress is the fastest Ojas depleter. Pitta types need cooling, not stimulating, breathwork."
            })
        else:
            base.append({
                "priority": 3,
                "type":     "breathing",
                "action":   "Nadi Shodhana (alternate nostril breathing) for 10 minutes before bed.",
                "why":      "Calms Vata/Kapha nervous system. Directly reduces stress signal."
            })

    if not base:
        base.append({
            "priority": 1,
            "type":     "maintenance",
            "action":   "Continue your current routine. All signals are balanced.",
            "why":      "OJAS is projected to stay stable. Maintain consistency."
        })

    # Sort by priority, return top 3
    return sorted(base, key=lambda x: x["priority"])[:3]

@router.get("/radar/{user_id}")
async def get_radar_analysis(user_id: str):
    """
    Fetches the latest Gemini 2.5 Flash LSTM surrogate analysis.
    Returns 404 if not found (e.g., background task still running).
    """
    db = get_db()
    radar_collection = db["radar_analysis"]
    
    doc = await radar_collection.find_one({"user_id": user_id})
    if not doc:
        raise HTTPException(status_code=404, detail="Radar analysis not yet available.")
        
    return {
        "user_id": user_id,
        "latest_date": doc.get("latest_date"),
        "analysis": doc.get("analysis")
    }
