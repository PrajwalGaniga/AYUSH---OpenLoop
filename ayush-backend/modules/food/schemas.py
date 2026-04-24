"""
schemas.py — Pydantic models for the Food Scan & Analysis endpoints
"""
from typing import List
from pydantic import BaseModel


class DetectedFoodItem(BaseModel):
    class_id: str
    name: str
    confidence: float


class FoodScanResponse(BaseModel):
    scan_id: str            # uuid4
    detection_count: int
    detected_items: List[DetectedFoodItem]
    image_path: str         # relative path where the image was saved


class DeepAuditAnswer(BaseModel):
    class_id: str
    answer: str             # "positive" | "negative"


class FoodAnalysisRequest(BaseModel):
    scan_id: str
    user_id: str
    confirmed_items: List[str]      # list of class_ids the user confirmed
    meal_source: str                # "home" | "restaurant"
    audit_answers: List[DeepAuditAnswer]


class FoodItemResult(BaseModel):
    class_id: str
    name: str
    classification: str
    base_ojas_delta: int
    audit_ojas_adjustment: int   # the bonus or penalty part only
    total_ojas_delta: int        # base + adjustment
    dosha_summary: str
    vata_effect: str
    pitta_effect: str
    kapha_effect: str
    virya: str
    vipaka: str
    guna: List[str]
    agni_impact: str
    ama_risk: str
    digestibility: str
    best_meal_time: str
    question_asked: str
    positive_label: str
    negative_label: str
    answer_given: str            # which label was selected
    reasoning: str               # positive_reasoning or negative_reasoning based on answer
    ideal_seasons: List[str]
    avoid_seasons: List[str]
    ritucharya_reason: str
    prakriti_advice_vata: str
    prakriti_advice_pitta: str
    prakriti_advice_kapha: str
    pairings_ideal: List[str]
    pairings_avoid: List[str]
    condition_warnings: List[dict]   # [{condition, advice}]
    red_flags: List[str]         # hotel only, empty list for home


class ViruddhAharaWarning(BaseModel):
    items: List[str]        # human-readable food names involved
    reason: str
    risk: str               # "Critical" | "High" | "Moderate"


class FoodAnalysisResponse(BaseModel):
    total_ojas_delta: int
    food_results: List[FoodItemResult]
    viruddha_warnings: List[ViruddhAharaWarning]
    logged: bool


class LogMealRequest(BaseModel):
    user_id: str
    meal_source: str
    total_ojas_delta: int
    food_results: List[FoodItemResult]
    viruddha_warnings: List[ViruddhAharaWarning]
