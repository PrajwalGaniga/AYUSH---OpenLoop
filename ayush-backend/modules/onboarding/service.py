"""
Onboarding Business Logic
─────────────────────────
- Prakriti calculation engine (24-question dosha scoring)
- OJAS vitality score computation (penalty/bonus system)
- MongoDB CRUD for all onboarding steps
"""
from datetime import datetime, timezone
from typing import Optional
import uuid

from database.mongodb import get_db


# ─── Prakriti Calculation ────────────────────────────────────────────────────

def calculate_prakriti(answers: list) -> dict:
    """
    answers: [{ "questionId": "Q1", "selectedDosha": "vata" }]
    Returns: { dominant, secondary, type, scores: {vata, pitta, kapha} }
    """
    counts = {"vata": 0, "pitta": 0, "kapha": 0}

    for answer in answers:
        dosha = answer.get("selectedDosha", "").lower()
        if dosha in counts:
            counts[dosha] += 1

    total = sum(counts.values())
    if total == 0:
        return {"error": "No answers provided"}

    # Normalize to percentages
    scores = {k: round((v / total) * 100) for k, v in counts.items()}

    sorted_doshas = sorted(scores.items(), key=lambda x: x[1], reverse=True)
    dominant_name, dominant_score = sorted_doshas[0]
    second_name, second_score = sorted_doshas[1]

    # Classification logic
    if all(25 <= s <= 40 for s in scores.values()):
        prakriti_type = "Tridosha"
        dominant = dominant_name.capitalize()
        secondary = second_name.capitalize()
    elif dominant_score >= 50:
        dominant = dominant_name.capitalize()
        if second_score >= 25:
            secondary = second_name.capitalize()
            prakriti_type = f"{dominant}-{secondary}"
        else:
            secondary = None
            prakriti_type = dominant
    else:
        dominant = dominant_name.capitalize()
        secondary = second_name.capitalize()
        prakriti_type = f"{dominant}-{secondary}"

    return {
        "dominant": dominant,
        "secondary": secondary,
        "type": prakriti_type,
        "scores": scores,
    }


# ─── OJAS Score Calculation ──────────────────────────────────────────────────

def calculate_ojas(user_doc: dict) -> dict:
    """
    Computes OJAS vitality score from the user's full profile.
    Returns: { ojasScore, breakdown }
    """
    base = 100
    penalties = []
    bonuses = []

    conditions = user_doc.get("healthConditions", {})
    lifestyle = user_doc.get("lifestyle", {})

    # ── Disease penalties ──────────────────────────────────────────────────
    for condition in conditions.get("chronicConditions", []):
        penalties.append({"reason": f"Chronic condition: {condition}", "value": -15})

    for condition in conditions.get("diagnosedConditions", []):
        penalties.append({"reason": f"Diagnosed: {condition}", "value": -5})

    for condition in conditions.get("mentalHealthConditions", []):
        penalties.append({"reason": f"Mental health: {condition}", "value": -5})

    # ── Lifestyle penalties ────────────────────────────────────────────────
    sleep_hours = lifestyle.get("sleepHours", 7)
    if sleep_hours and sleep_hours < 6:
        penalties.append({"reason": "Poor sleep (< 6 hrs)", "value": -5})

    if lifestyle.get("occupationType") == "sedentary":
        penalties.append({"reason": "Sedentary lifestyle", "value": -5})

    smoking = lifestyle.get("smokingStatus", "")
    if smoking in ["regular", "heavy"]:
        penalties.append({"reason": "Smoking habit", "value": -10})

    stress = lifestyle.get("stressLevel", "")
    if stress in ["often", "very_often", "always"]:
        penalties.append({"reason": "Chronic high stress", "value": -8})

    water = lifestyle.get("waterIntakeLiters", 2)
    if water and water < 1.5:
        penalties.append({"reason": "Poor hydration (< 1.5L/day)", "value": -3})

    alcohol = lifestyle.get("alcoholStatus", "")
    if alcohol in ["regular", "heavy"]:
        penalties.append({"reason": "Regular alcohol use", "value": -7})

    # ── Lifestyle bonuses ──────────────────────────────────────────────────
    if lifestyle.get("yogaPractice"):
        bonuses.append({"reason": "Regular yoga practice", "value": 5})

    if lifestyle.get("meditationPractice"):
        bonuses.append({"reason": "Meditation practice", "value": 5})

    diet = lifestyle.get("dietType", "")
    if diet in ["vegetarian", "vegan"]:
        bonuses.append({"reason": "Plant-based diet", "value": 3})

    if sleep_hours and 7 <= sleep_hours <= 9:
        bonuses.append({"reason": "Healthy sleep (7–9 hrs)", "value": 4})

    exercise = lifestyle.get("exerciseFrequency", "")
    if exercise in ["3_4_week", "daily"]:
        bonuses.append({"reason": "Regular exercise", "value": 5})

    if water and water >= 2.5:
        bonuses.append({"reason": "Excellent hydration (≥ 2.5L/day)", "value": 3})

    total_penalty = sum(p["value"] for p in penalties)
    total_bonus = sum(b["value"] for b in bonuses)
    final_score = max(0, min(100, base + total_penalty + total_bonus))

    return {
        "ojasScore": final_score,
        "breakdown": {
            "base": base,
            "penalties": penalties,
            "bonuses": bonuses,
            "totalPenalty": total_penalty,
            "totalBonus": total_bonus,
            "final": final_score,
        },
    }


# ─── MongoDB Helpers ─────────────────────────────────────────────────────────

def _now():
    return datetime.now(timezone.utc)


async def update_user_field(user_id: str, update_dict: dict):
    db = get_db()
    update_dict["updatedAt"] = _now()
    await db["users"].update_one({"userId": user_id}, {"$set": update_dict})


async def get_user_by_id(user_id: str) -> Optional[dict]:
    db = get_db()
    return await db["users"].find_one({"userId": user_id}, {"_id": 0})


async def get_user_by_phone(phone: str) -> Optional[dict]:
    db = get_db()
    return await db["users"].find_one({"phone": phone}, {"_id": 0})
