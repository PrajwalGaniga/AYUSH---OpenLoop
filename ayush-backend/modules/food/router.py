"""
router.py — Food scan & Ayurvedic analysis endpoints.

Routes:
  POST /api/v1/food/scan     — Upload image, run YOLO, return detections
  POST /api/v1/food/analyze  — Submit confirmed items + audit answers, get OJAS delta
"""
from __future__ import annotations

import uuid
from pathlib import Path

from fastapi import APIRouter, File, Form, HTTPException, UploadFile, status

from utils.response_models import success_response
from .schemas import FoodAnalysisRequest, FoodAnalysisResponse, FoodScanResponse, LogMealRequest
from .service import calculate_analysis, run_yolo_scan, log_meal_to_db

router = APIRouter(prefix="/food", tags=["Food Scan & Analysis"])

_UPLOADS_BASE = Path(__file__).resolve().parent.parent.parent / "uploads"


# ─────────────────────────────────────────────────────────────────────────────
# POST /food/scan
# ─────────────────────────────────────────────────────────────────────────────

@router.post(
    "/scan",
    response_model=dict,
    summary="Scan a food image with YOLO",
    status_code=status.HTTP_200_OK,
)
async def food_scan(
    file: UploadFile = File(..., description="Food image (JPEG/PNG)"),
    user_id: str = Form(..., description="The authenticated user's ID"),
):
    """
    1. Validate & save the uploaded image to uploads/{user_id}/{uuid4}.jpg
    2. Run YOLO inference (confidence ≥ 0.40)
    3. Return scan_id, detected items, and the relative saved path
    """
    # ── Validate file type ───────────────────────────────────────────────────
    content_type = file.content_type or ""
    if not content_type.startswith("image/"):
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail=f"Unsupported file type '{content_type}'. Upload a JPEG or PNG image.",
        )

    # ── Persist image ────────────────────────────────────────────────────────
    scan_id = str(uuid.uuid4())
    user_upload_dir = _UPLOADS_BASE / user_id
    user_upload_dir.mkdir(parents=True, exist_ok=True)

    # Keep original extension; default to .jpg
    suffix = Path(file.filename or "image.jpg").suffix or ".jpg"
    saved_filename = f"{scan_id}{suffix}"
    saved_path = user_upload_dir / saved_filename

    contents = await file.read()
    if not contents:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Uploaded file is empty.",
        )

    saved_path.write_bytes(contents)

    # Relative path returned to client (safe, no absolute filesystem exposure)
    relative_path = f"uploads/{user_id}/{saved_filename}"

    # ── YOLO inference ───────────────────────────────────────────────────────
    detected_items = run_yolo_scan(str(saved_path))

    scan_response = FoodScanResponse(
        scan_id=scan_id,
        detection_count=len(detected_items),
        detected_items=detected_items,
        image_path=relative_path,
    )

    return success_response(
        data=scan_response.model_dump(),
        message=(
            f"{len(detected_items)} item(s) detected."
            if detected_items
            else "No food items detected above confidence threshold."
        ),
    )


# ─────────────────────────────────────────────────────────────────────────────
# POST /food/analyze
# ─────────────────────────────────────────────────────────────────────────────

@router.post(
    "/analyze",
    response_model=dict,
    summary="Analyze confirmed food items for OJAS impact",
    status_code=status.HTTP_200_OK,
)
async def food_analyze(request: FoodAnalysisRequest):
    """
    Pure Ayurvedic analysis — no Gemini, no external calls.
    Computes OJAS delta and Viruddha Ahara warnings from the JSON knowledge base.
    """
    if not request.confirmed_items:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="confirmed_items must contain at least one class_id.",
        )

    result: FoodAnalysisResponse = calculate_analysis(request)

    return success_response(
        data=result.model_dump(),
        message="Food analysis complete.",
    )


# ─────────────────────────────────────────────────────────────────────────────
# POST /food/log
# ─────────────────────────────────────────────────────────────────────────────

@router.post(
    "/log",
    response_model=dict,
    summary="Log a meal to user profile",
    status_code=status.HTTP_200_OK,
)
async def log_meal(request: LogMealRequest):
    """
    Logs the final analyzed meal to the database.
    """
    await log_meal_to_db(request)

    return success_response(
        message="Meal logged successfully.",
    )
