from __future__ import annotations

import io
import json
import re
import traceback

import google.generativeai as genai
import PIL.Image
from fastapi import APIRouter, File, Form, HTTPException, UploadFile

from config.settings import settings
from .schemas import (
    PackagedFoodAnalysisResponse,
    PackagedFoodIngredient,
)

router = APIRouter(prefix="/api/v1/packaged-food", tags=["packaged-food"])


def _build_prompt(prakriti: str, conditions: str, ojas_score: int, medications: str) -> str:
    profile_section = f"""
USER HEALTH PROFILE:
- Ayurvedic Prakriti (Body Constitution): {prakriti or 'Unknown'}
- Existing Health Conditions: {conditions or 'None mentioned'}
- Current Medications: {medications or 'None mentioned'}
- OJAS Score (vitality, 0–100): {ojas_score or 'Not available'}
"""
    return f"""You are an expert Ayurvedic nutritionist and food safety analyst.

The attached image is a photo of a packaged food product's label or packaging.

{profile_section}

Your tasks:
1. Read ALL visible text in the image (product name, brand, ingredients, nutrition info, etc.)
2. Based on that text and the user's health profile, produce a personalized food analysis.

Return ONLY valid JSON (no markdown fences, no extra text):
{{
  "product_name": "<detected product name or 'Unknown Product'>",
  "brand": "<detected brand or 'Unknown'>",
  "overall_score": <integer 0-100, how healthy this is for THIS user specifically>,
  "recommendation": "<exactly one of: buy | skip | moderate>",
  "recommendation_reason": "<1-2 sentences specific to this user's prakriti and conditions>",
  "ingredients": [
    {{
      "name": "<ingredient name>",
      "is_concerning": <true|false>,
      "reason": "<why it is concerning or beneficial for this user>"
    }}
  ],
  "positives": ["<benefit 1>", "<benefit 2>"],
  "negatives": ["<concern 1>", "<concern 2>"],
  "ayurvedic_note": "<Ayurvedic perspective on this food for this prakriti type>",
  "allergen_flags": ["<allergen 1>"],
  "serving_tip": "<practical tip to make this safer/healthier if consumed>",
  "raw_ocr_text": "<all text you read from the image, verbatim>"
}}

Rules:
- overall_score must factor in the user's specific prakriti and conditions
- ingredients list should cover all identifiable ingredients visible in the image
- allergen_flags: only list actual allergens found in the ingredients
- If the image is unclear, make best-effort inferences
"""


def _parse_gemini_response(text: str) -> dict:
    cleaned = re.sub(r"```(?:json)?", "", text).strip().strip("`").strip()
    try:
        return json.loads(cleaned)
    except json.JSONDecodeError as e:
        print(f"[PackagedFood] JSON parse error: {e}")
        print(f"[PackagedFood] Raw Gemini response:\n{text}")
        raise ValueError(f"Gemini returned invalid JSON: {e}")


@router.post("/analyze", response_model=PackagedFoodAnalysisResponse)
async def analyze_packaged_food(
    image: UploadFile = File(...),
    prakriti: str = Form(default=""),
    conditions: str = Form(default=""),
    ojas_score: int = Form(default=0),
    medications: str = Form(default=""),
):
    print(f"\n{'='*60}")
    print(f"[PackagedFood] 📦 SCAN REQUEST")
    print(f"[PackagedFood]   File      : {image.filename} ({image.content_type})")
    print(f"[PackagedFood]   Prakriti  : {prakriti}")
    print(f"[PackagedFood]   Conditions: {conditions}")
    print(f"[PackagedFood]   Ojas      : {ojas_score}")
    print(f"{'='*60}")

    # ── 1. Read image ─────────────────────────────────────────────────────────
    image_bytes = await image.read()
    if len(image_bytes) == 0:
        raise HTTPException(status_code=400, detail="Empty image file")
    print(f"[PackagedFood] Image: {len(image_bytes)/1024:.1f} KB")

    try:
        pil_image = PIL.Image.open(io.BytesIO(image_bytes))
        pil_image = pil_image.convert("RGB")   # ensure no alpha channel issues
        print(f"[PackagedFood] Decoded image: {pil_image.size} mode={pil_image.mode}")
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Could not decode image: {e}")

    # ── 2. Gemini Vision — read label + analyze ───────────────────────────────
    api_key = settings.packaged_food_gemini_api_key
    model_name = settings.packaged_food_gemini_model

    if not api_key:
        raise HTTPException(status_code=500, detail="PACKAGED_FOOD_GEMINI_API_KEY not configured")

    print(f"[PackagedFood] Calling Gemini Vision: model={model_name} key={api_key[:8]}...")

    try:
        genai.configure(api_key=api_key)
        model = genai.GenerativeModel(model_name)
        prompt = _build_prompt(prakriti, conditions, ojas_score, medications)

        response = model.generate_content([prompt, pil_image])
        gemini_text = response.text
        print(f"[PackagedFood] Gemini response ({len(gemini_text)} chars):\n{gemini_text[:400]}...")
    except Exception as e:
        traceback.print_exc()
        raise HTTPException(status_code=502, detail=f"Gemini Vision API error: {e}")

    # ── 3. Parse ──────────────────────────────────────────────────────────────
    try:
        data = _parse_gemini_response(gemini_text)
    except ValueError as e:
        raise HTTPException(status_code=502, detail=str(e))

    print(f"[PackagedFood] ✅ Done: '{data.get('product_name')}' | "
          f"score={data.get('overall_score')} | rec={data.get('recommendation')}")
    print(f"[PackagedFood] OCR text preview: {str(data.get('raw_ocr_text',''))[:150]}")
    print(f"{'='*60}\n")

    return PackagedFoodAnalysisResponse(
        product_name=data.get("product_name", "Unknown Product"),
        brand=data.get("brand", "Unknown"),
        overall_score=int(data.get("overall_score", 50)),
        recommendation=data.get("recommendation", "moderate"),
        recommendation_reason=data.get("recommendation_reason", ""),
        ingredients=[PackagedFoodIngredient(**i) for i in data.get("ingredients", [])],
        positives=data.get("positives", []),
        negatives=data.get("negatives", []),
        ayurvedic_note=data.get("ayurvedic_note", ""),
        allergen_flags=data.get("allergen_flags", []),
        serving_tip=data.get("serving_tip", ""),
        raw_ocr_text=data.get("raw_ocr_text", ""),
    )


@router.get("/health")
async def packaged_food_health():
    api_key = settings.packaged_food_gemini_api_key
    return {
        "ocr_backend": "Gemini Vision (multimodal)",
        "gemini_model": settings.packaged_food_gemini_model,
        "gemini_key_set": bool(api_key),
        "note": "No local OCR — image sent directly to Gemini Vision API",
    }
