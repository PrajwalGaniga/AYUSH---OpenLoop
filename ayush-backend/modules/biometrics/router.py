from fastapi import APIRouter, HTTPException, UploadFile, File, Depends
from datetime import datetime, timezone
from database.mongodb import get_db
from middleware.auth_middleware import get_current_user
from .tongue_analyzer import analyze_tongue
from .eye_analyzer import analyze_eye

router = APIRouter()

@router.post("/tongue")
async def analyze_tongue_endpoint(
    file: UploadFile = File(...),
    current_user: dict = Depends(get_current_user)
):
    image_bytes = await file.read()
    result = analyze_tongue(image_bytes)
    
    if "error" in result:
        raise HTTPException(status_code=422, detail=result["error"])
    
    today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    
    tongue_entry = {
        "userId": current_user["sub"],
        "date_key": today,
        "timestamp": datetime.now(timezone.utc),
        "coating_score": result["coating_score"],
        "color_classification": result["color_classification"],
        "tongue_health_score": result["tongue_health_score"],
        "ama_level": result["ama_level"],
        "dosha_signal": result["dosha_signal"],
    }
    
    db = get_db()
    # Add an array of captures instead of just upserting one entry per day if multiple scans are desired
    # Or follow user's exact upsert query
    await db["tongue_captures"].update_one(
        {"userId": current_user["sub"], "date_key": today},
        {"$set": tongue_entry},
        upsert=True
    )
    
    return {
        "status": "success",
        "data": result,
        "message": "Tongue analysis complete"
    }


@router.post("/eye")
async def analyze_eye_endpoint(
    file: UploadFile = File(...),
    current_user: dict = Depends(get_current_user)
):
    image_bytes = await file.read()
    result = analyze_eye(image_bytes)
    
    if "error" in result:
        raise HTTPException(status_code=422, detail=result["error"])
    
    today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    
    eye_entry = {
        "userId": current_user["sub"],
        "date_key": today,
        "timestamp": datetime.now(timezone.utc),
        "redness_index": result["redness_index"],
        "redness_classification": result["redness_classification"],
        "jaundice_score": result["jaundice_score"],
        "jaundice_flag": result["jaundice_flag"],
        "eye_health_score": result["eye_health_score"],
        "dosha_signal": result["dosha_signal"]
    }
    
    db = get_db()
    await db["eye_captures"].update_one(
        {"userId": current_user["sub"], "date_key": today},
        {"$set": eye_entry},
        upsert=True
    )
    
    return {
        "status": "success",
        "data": result,
        "message": "Eye analysis complete"
    }
