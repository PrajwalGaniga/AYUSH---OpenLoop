"""
service.py — Business logic for food scan (YOLO) and Ayurvedic analysis.

Design decisions:
  - YOLO model and JSON knowledge base are loaded ONCE at module import time.
  - No Gemini / external API calls anywhere in this module.
  - All scoring logic is purely derived from yolo_classes_and_qna.json.
"""
from __future__ import annotations

import json
import logging
from pathlib import Path
from typing import List

from fastapi import HTTPException
from datetime import datetime, timezone
import uuid

from database.mongodb import get_db
from .schemas import (
    DetectedFoodItem,
    FoodAnalysisRequest,
    FoodAnalysisResponse,
    FoodItemResult,
    ViruddhAharaWarning,
    LogMealRequest,
)
from utils.gemini_client import get_gemini_model

logger = logging.getLogger(__name__)

# ─────────────────────────────────────────────────────────────────────────────
# Module-level singletons — loaded ONCE, reused for every request
# ─────────────────────────────────────────────────────────────────────────────

_BASE_DIR = Path(__file__).resolve().parent.parent.parent  # ayush-backend/
_JSON_PATH = _BASE_DIR / "yolo-model" / "yolo_classes_and_qna.json"
_MODEL_PATH = _BASE_DIR / "yolo-model" / "yolo.pt"

# --- Load knowledge base ---
try:
    with _JSON_PATH.open(encoding="utf-8") as f:
        _food_wisdom_db: dict = json.load(f)
    logger.info("[FoodService] Loaded knowledge base from %s", _JSON_PATH)
except FileNotFoundError:
    raise RuntimeError(
        f"[FoodService] Knowledge base not found at: {_JSON_PATH}. "
        "Ensure yolo-model/yolo_classes_and_qna.json exists."
    )

# --- Load YOLO model (lazy, thread-safe singleton) ---
_yolo_model = None


def _get_yolo_model():
    """Lazy-load the YOLO model the first time it is needed."""
    global _yolo_model
    if _yolo_model is None:
        try:
            from ultralytics import YOLO  # type: ignore
            if not _MODEL_PATH.exists():
                raise FileNotFoundError(
                    f"YOLO model not found at: {_MODEL_PATH}"
                )
            _yolo_model = YOLO(str(_MODEL_PATH))
            logger.info("[FoodService] YOLO model loaded from %s", _MODEL_PATH)
        except ImportError as exc:
            raise RuntimeError(
                "ultralytics package is not installed. "
                "Run: pip install ultralytics"
            ) from exc
    return _yolo_model


# ─────────────────────────────────────────────────────────────────────────────
# Helper accessors
# ─────────────────────────────────────────────────────────────────────────────

def _get_food_entry(class_id: str) -> dict:
    """Return the food wisdom entry for a class_id or raise HTTP 422."""
    entry = _food_wisdom_db.get("food_wisdom", {}).get(class_id)
    if entry is None:
        raise HTTPException(
            status_code=422,
            detail=f"Unknown food class_id '{class_id}'. Not present in knowledge base.",
        )
    return entry


# ─────────────────────────────────────────────────────────────────────────────
# Function 1 — YOLO inference
# ─────────────────────────────────────────────────────────────────────────────

CONFIDENCE_THRESHOLD = 0.05


def run_yolo_scan(image_path: str) -> List[DetectedFoodItem]:
    """
    Run YOLO inference on a saved image and return all detections
    above CONFIDENCE_THRESHOLD.

    Raises:
        HTTPException 404 — if image file does not exist.
        HTTPException 204 — if no detections pass the threshold.
    """
    img_path = Path(image_path)
    if not img_path.exists():
        raise HTTPException(
            status_code=404,
            detail=f"Image not found at path: {image_path}",
        )

    model = _get_yolo_model()
    results = model.predict(source=str(img_path), verbose=False)
    
    detected = []
    seen_class_ids = set()  # prevent duplicate class detections

    for result in results:
        if result.boxes is None:
            continue
        for box in result.boxes:
            confidence = float(box.conf[0])
            class_id = int(box.cls[0])
            class_id_str = str(class_id)

            if confidence < CONFIDENCE_THRESHOLD:
                continue
            if class_id_str not in _food_wisdom_db.get("food_wisdom", {}):
                continue  # YOLO detected something not in our 31-class knowledge base
            
            if class_id_str in seen_class_ids:
                # Keep the one with higher confidence
                existing = next(x for x in detected if x.class_id == class_id_str)
                if confidence > existing.confidence:
                    detected.remove(existing)
                    seen_class_ids.discard(class_id_str)
                else:
                    continue

            seen_class_ids.add(class_id_str)
            kb_entry = _food_wisdom_db["food_wisdom"][class_id_str]
            name = kb_entry["name"]
            
            print(f"[YOLO] Detected: {name} (Class {class_id_str}) - Confidence: {confidence}")
            
            detected.append(DetectedFoodItem(
                class_id=class_id_str,
                name=name,
                confidence=round(confidence, 3)
            ))

    # Sort by confidence descending
    detected.sort(key=lambda x: x.confidence, reverse=True)
    print(f"[YOLO] Returning {len(detected)} unique items to Flutter.")
    return detected


# ─────────────────────────────────────────────────────────────────────────────
# Function 2 — Ayurvedic analysis (pure JSON, no external calls)
# ─────────────────────────────────────────────────────────────────────────────

def calculate_analysis(request: FoodAnalysisRequest) -> FoodAnalysisResponse:
    """
    For each confirmed food item:
      1. Look up Ayurvedic properties from the knowledge base.
      2. Find the user's audit answer (positive/negative).
      3. Assign ojas_delta = ojas_bonus (positive) or ojas_penalty (negative).
      4. Check all Viruddha Ahara (food incompatibility) rules.

    No Gemini. No external API calls. Pure deterministic JSON lookup.
    """
    meal_source = request.meal_source.lower()
    print(f"\n[ANALYSIS] Starting analysis. Received meal_source: '{meal_source}'")
    
    if meal_source not in ("home", "hotel"):
        print(f"[ANALYSIS WARNING] Invalid meal_source received: '{meal_source}'")
        raise HTTPException(
            status_code=422,
            detail="meal_source must be 'home' or 'hotel'.",
        )

    # Build a lookup: class_id → audit answer
    audit_map: dict[str, str] = {
        a.class_id: a.answer.lower() for a in request.audit_answers
    }
    print(f"[ANALYSIS] Audit answers map: {audit_map}")

    food_results: List[FoodItemResult] = []
    total_ojas_delta = 0

    for class_id in request.confirmed_items:
        entry = _get_food_entry(class_id)
        if not entry:
            print(f"[ANALYSIS WARNING] Class ID {class_id} not found in DB.")
            continue

        deep_audit = entry.get("deep_audit", {})
        
        # Determine the correct block to use based on meal_source
        if meal_source in deep_audit:
            print(f"[ANALYSIS] Using '{meal_source}' audit block for {entry.get('name')}")
            audit_block = deep_audit[meal_source]
        else:
            print(f"[ANALYSIS] '{meal_source}' block missing for {entry.get('name')}. Falling back to 'home'.")
            audit_block = deep_audit.get("home", {})

        base_delta = entry.get("nutritional_context", {}).get("base_ojas_delta", 0)
        
        answer_given_enum = audit_map.get(class_id)
        
        if answer_given_enum is None:
            ojas_delta = base_delta
            audit_adjustment = 0
            answer_given = "Not answered"
            reasoning = ""
        elif answer_given_enum == "positive":
            audit_adjustment = audit_block.get("ojas_bonus", 0)
            ojas_delta = base_delta + audit_adjustment
            answer_given = audit_block.get("positive_label", "Yes")
            reasoning = audit_block.get("positive_reasoning", "")
        else:
            audit_adjustment = audit_block.get("ojas_penalty", 0)
            ojas_delta = base_delta + audit_adjustment
            answer_given = audit_block.get("negative_label", "No")
            reasoning = audit_block.get("negative_reasoning", "")

        total_ojas_delta += ojas_delta

        ayurvedic_profile = entry.get("ayurvedic_profile", {})
        dosha_effect = ayurvedic_profile.get("dosha_effect", {})
        nutritional_context = entry.get("nutritional_context", {})
        ritucharya = entry.get("ritucharya", {})
        prakriti_advice = entry.get("prakriti_advice", {})
        pairings = entry.get("pairings", {})

        food_results.append(
            FoodItemResult(
                class_id=class_id,
                name=entry.get("name", "Unknown"),
                classification=entry.get("classification", ""),
                base_ojas_delta=base_delta,
                audit_ojas_adjustment=audit_adjustment,
                total_ojas_delta=ojas_delta,
                dosha_summary=dosha_effect.get("summary", ""),
                vata_effect=dosha_effect.get("vata", ""),
                pitta_effect=dosha_effect.get("pitta", ""),
                kapha_effect=dosha_effect.get("kapha", ""),
                virya=ayurvedic_profile.get("virya", ""),
                vipaka=ayurvedic_profile.get("vipaka", ""),
                guna=ayurvedic_profile.get("guna", []),
                agni_impact=ayurvedic_profile.get("agni_impact", ""),
                ama_risk=ayurvedic_profile.get("ama_risk", ""),
                digestibility=nutritional_context.get("digestibility", ""),
                best_meal_time=nutritional_context.get("best_meal_time", ""),
                question_asked=audit_block.get("question", ""),
                positive_label=audit_block.get("positive_label", "Yes"),
                negative_label=audit_block.get("negative_label", "No"),
                answer_given=answer_given,
                reasoning=reasoning,
                ideal_seasons=ritucharya.get("ideal_seasons", []),
                avoid_seasons=ritucharya.get("avoid_seasons", []),
                ritucharya_reason=ritucharya.get("reason", ""),
                prakriti_advice_vata=prakriti_advice.get("vata", ""),
                prakriti_advice_pitta=prakriti_advice.get("pitta", ""),
                prakriti_advice_kapha=prakriti_advice.get("kapha", ""),
                pairings_ideal=pairings.get("ideal_with", []),
                pairings_avoid=pairings.get("avoid_with", []),
                condition_warnings=entry.get("condition_warnings", []),
                red_flags=audit_block.get("red_flags", [])
            )
        )

    # ── Viruddha Ahara check ─────────────────────────────────────────────────
    confirmed_set = set(request.confirmed_items)
    viruddha_warnings: List[ViruddhAharaWarning] = []

    for rule in _food_wisdom_db.get("viruddha_ahara_logic", []):
        rule_items: List[str] = rule.get("items", [])
        # Only flag if ALL items in the rule are present in this meal
        if all(item in confirmed_set for item in rule_items):
            # Resolve class_ids → human-readable names
            names = []
            for cid in rule_items:
                kb_entry = _food_wisdom_db.get("food_wisdom", {}).get(cid)
                names.append(kb_entry["name"] if kb_entry else cid)

            viruddha_warnings.append(
                ViruddhAharaWarning(
                    items=names,
                    reason=rule.get("reason", ""),
                    risk=rule.get("risk", "Moderate"),
                )
            )

    return FoodAnalysisResponse(
        total_ojas_delta=total_ojas_delta,
        food_results=food_results,
        viruddha_warnings=viruddha_warnings,
        logged=True,
    )


# ─────────────────────────────────────────────────────────────────────────────
# Function 3 — Log Meal to DB
# ─────────────────────────────────────────────────────────────────────────────

async def get_gemini_quality_score(food_results: list, user_profile: dict) -> int:
    try:
        model = get_gemini_model()
        food_names = [item.name for item in food_results]
        prompt = f"""
        Analyze this meal for a user with the following profile:
        {json.dumps(user_profile, default=str)}
        
        Meal contents: {', '.join(food_names)}
        
        Return ONLY a JSON object with a single key "quality_score".
        "quality_score": integer between 0-100. 
        0 = highly harmful (fried, incompatible, processed)
        50 = neutral
        100 = ideal Ayurvedic meal for this user's prakriti.
        This is NOT the ojas_delta. It is the intrinsic quality of the meal independent of current ojas baseline.
        """
        response = await model.generate_content_async(prompt)
        text = response.text
        if "```json" in text:
            text = text.split("```json")[1].split("```")[0].strip()
        elif "```" in text:
            text = text.replace("```", "").strip()
        data = json.loads(text)
        return int(data.get("quality_score", 50))
    except Exception as e:
        logger.error(f"Gemini quality score failed: {e}")
        return 50  # Safe default

async def log_meal_to_db(request: LogMealRequest) -> None:
    db = get_db()
    
    now = datetime.now(timezone.utc)
    
    user = await db["users"].find_one({"userId": request.user_id})
    user_profile = user.get("profile", {}) if user else {}
    current_ojas = user.get("ojasScore") if user else None
    
    meal_quality_score = await get_gemini_quality_score(request.food_results, user_profile)
    
    log_entry = {
        "logId": str(uuid.uuid4()),
        "userId": request.user_id,
        "mealSource": request.meal_source,
        "totalOjasDelta": request.total_ojas_delta,
        "meal_quality_score": meal_quality_score,
        "foodResults": [item.model_dump() for item in request.food_results],
        "viruddhaWarnings": [warn.model_dump() for warn in request.viruddha_warnings],
        "loggedAt": now,
    }
    
    # Save the meal log
    await db["food_logs"].insert_one(log_entry)
    
    # Update OJAS and create history ledger entry
    if user and current_ojas is not None:
        new_ojas = current_ojas + request.total_ojas_delta
        # Clamp between 0 and 100
        new_ojas = max(0, min(100, new_ojas))
        
        await db["users"].update_one(
            {"userId": request.user_id},
            {"$set": {"ojasScore": new_ojas, "updatedAt": now}}
        )
        
        history_entry = {
            "user_id": request.user_id,
            "timestamp": now,
            "value": new_ojas,
            "delta": request.total_ojas_delta,
            "source": "food_scan",
            "source_id": log_entry["logId"]
        }
        await db["ojas_history"].insert_one(history_entry)


