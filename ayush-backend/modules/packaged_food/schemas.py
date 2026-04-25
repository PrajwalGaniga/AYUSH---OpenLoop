from pydantic import BaseModel
from typing import List, Optional


class PackagedFoodIngredient(BaseModel):
    name: str
    is_concerning: bool
    reason: str


class PackagedFoodAnalysisRequest(BaseModel):
    prakriti: str = ""
    conditions: str = ""
    ojas_score: int = 0
    medications: str = ""


class PackagedFoodAnalysisResponse(BaseModel):
    product_name: str
    brand: str
    overall_score: int            # 0–100
    recommendation: str           # "buy" | "skip" | "moderate"
    recommendation_reason: str
    ingredients: List[PackagedFoodIngredient]
    positives: List[str]
    negatives: List[str]
    ayurvedic_note: str
    allergen_flags: List[str]
    serving_tip: str
    raw_ocr_text: Optional[str] = None   # debug: what OCR extracted
