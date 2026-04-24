"""
FastAPI Router — Auth + Onboarding Endpoints
─────────────────────────────────────────────
Base URL: /api/v1
Auth:      /auth/register | /auth/login | /auth/me
Onboarding: /onboarding/step1/... through /onboarding/complete
"""
import uuid
from datetime import datetime, timezone, timedelta
from typing import Optional

from fastapi import APIRouter, HTTPException, status, UploadFile, File, Form, Depends
from jose import jwt

from config.settings import settings
from database.mongodb import get_db
from middleware.auth_middleware import get_current_user
from modules.onboarding.models import (
    RegisterRequest, LoginRequest,
    Step1Request, Step2BodyScanRequest, PhysicalTraitsRequest,
    Step3AnswersRequest, Step3CalculateRequest,
    Step4LifestyleRequest, Step5HealthConditionsRequest,
    ConfirmReportRequest, CalculateOjasRequest, CompleteOnboardingRequest,
)
from modules.onboarding.service import (
    calculate_prakriti, calculate_ojas,
    update_user_field, get_user_by_id, get_user_by_phone,
)
from modules.onboarding.gemini_service import extract_medical_report
from utils.password_utils import store_password, verify_password
from utils.response_models import success_response, error_response

router = APIRouter()


# ─── Token Helper ────────────────────────────────────────────────────────────

def create_token(user_id: str) -> str:
    expire = datetime.now(timezone.utc) + timedelta(hours=settings.jwt_expire_hours)
    payload = {"sub": user_id, "exp": expire}
    return jwt.encode(payload, settings.jwt_secret, algorithm="HS256")


def _now():
    return datetime.now(timezone.utc)


# ═══════════════════════════════════════════════════════════════════════════════
# AUTH ENDPOINTS
# ═══════════════════════════════════════════════════════════════════════════════

@router.post("/auth/register")
async def register(req: RegisterRequest):
    db = get_db()

    existing = await db["users"].find_one({"phone": req.phone})
    if existing:
        raise HTTPException(status_code=409, detail="Phone already registered")

    user_id = str(uuid.uuid4())
    token = create_token(user_id)
    now = _now()

    user_doc = {
        "userId": user_id,
        "phone": req.phone,
        "password": store_password(req.password),  # plaintext per spec
        "isOnboarded": False,
        "onboardingStep": 0,
        "createdAt": now,
        "updatedAt": now,
        "lastLoginAt": now,
        "sessionToken": token,
        "profile": {
            "fullName": "", "age": None, "dob": "", "gender": "",
            "heightCm": None, "weightKg": None, "bloodGroup": "",
            "language": "en", "region": "", "completionPercent": 0,
        },
        "physicalTraits": {},
        "bodyPainPoints": [],
        "prakritiAnswers": [],
        "prakritiResult": {"dominant": "", "secondary": "", "type": "", "scores": {"vata": 0, "pitta": 0, "kapha": 0}},
        "lifestyle": {},
        "healthConditions": {
            "diagnosedConditions": [], "chronicConditions": [], "allergies": [],
            "currentMedications": [], "surgeries": [], "familyHistory": [], "mentalHealthConditions": [],
        },
        "medicalReports": [],
        "ojasScore": None,
        "ojasBreakdown": {"base": 100, "penalties": [], "bonuses": [], "final": None},
        "healthSnapshots": [],
    }

    await db["users"].insert_one(user_doc)

    return success_response(
        data={"userId": user_id, "token": token, "isOnboarded": False, "onboardingStep": 0},
        message="Registration successful",
    )


@router.post("/auth/login")
async def login(req: LoginRequest):
    db = get_db()
    user = await db["users"].find_one({"phone": req.phone}, {"_id": 0})
    if not user:
        raise HTTPException(status_code=404, detail="Phone not registered")

    if not verify_password(req.password, user["password"]):
        raise HTTPException(status_code=401, detail="Incorrect password")

    token = create_token(user["userId"])
    await db["users"].update_one(
        {"userId": user["userId"]},
        {"$set": {"sessionToken": token, "lastLoginAt": _now(), "updatedAt": _now()}},
    )

    return success_response(
        data={
            "userId": user["userId"],
            "token": token,
            "isOnboarded": user.get("isOnboarded", False),
            "onboardingStep": user.get("onboardingStep", 0),
            "profile": user.get("profile", {}),
            "ojasScore": user.get("ojasScore"),
            "prakritiResult": user.get("prakritiResult"),
        },
        message="Login successful",
    )


@router.get("/auth/me")
async def get_me(current_user: dict = Depends(get_current_user)):
    user = await get_user_by_id(current_user["sub"])
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    return success_response(data={
        "userId": user["userId"],
        "phone": user["phone"],
        "isOnboarded": user.get("isOnboarded", False),
        "onboardingStep": user.get("onboardingStep", 0),
        "profile": user.get("profile", {}),
        "ojasScore": user.get("ojasScore"),
        "prakritiResult": user.get("prakritiResult"),
    })


# ═══════════════════════════════════════════════════════════════════════════════
# ONBOARDING ENDPOINTS
# ═══════════════════════════════════════════════════════════════════════════════

@router.post("/step1/basic-profile")
async def step1_basic_profile(req: Step1Request):
    await update_user_field(req.userId, {
        "profile": {
            "fullName": req.fullName,
            "age": req.age,
            "dob": req.dob,
            "gender": req.gender,
            "heightCm": req.heightCm,
            "weightKg": req.weightKg,
            "bloodGroup": req.bloodGroup or "",
            "language": req.language,
            "region": req.region or "",
            "completionPercent": 16,
        },
        "onboardingStep": 1,
    })
    return success_response(message="Step 1 saved")


@router.post("/step2/body-scan")
async def step2_body_scan(req: Step2BodyScanRequest):
    pain_points = [p.model_dump() for p in req.painPoints]
    await update_user_field(req.userId, {
        "bodyPainPoints": pain_points,
        "onboardingStep": 2,
    })
    return success_response(message="Body scan saved")


@router.post("/step2/physical-traits")
async def step2_physical_traits(req: PhysicalTraitsRequest):
    traits = req.model_dump(exclude={"userId"})
    await update_user_field(req.userId, {"physicalTraits": traits})
    return success_response(message="Physical traits saved")


@router.post("/step3/prakriti-answers")
async def step3_prakriti_answers(req: Step3AnswersRequest):
    answers = [a.model_dump() for a in req.answers]
    await update_user_field(req.userId, {
        "prakritiAnswers": answers,
        "onboardingStep": 3,
    })
    return success_response(message="Prakriti answers saved")


@router.post("/step3/calculate-prakriti")
async def step3_calculate_prakriti(req: Step3CalculateRequest):
    user = await get_user_by_id(req.userId)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    answers = user.get("prakritiAnswers", [])
    result = calculate_prakriti(answers)

    await update_user_field(req.userId, {"prakritiResult": result})
    return success_response(data=result, message="Prakriti calculated")


@router.post("/step4/lifestyle")
async def step4_lifestyle(req: Step4LifestyleRequest):
    lifestyle = req.model_dump(exclude={"userId"})
    await update_user_field(req.userId, {
        "lifestyle": lifestyle,
        "onboardingStep": 4,
    })
    return success_response(message="Lifestyle saved")


@router.post("/step5/health-conditions")
async def step5_health_conditions(req: Step5HealthConditionsRequest):
    conditions = req.model_dump(exclude={"userId"})
    # Serialize medication objects
    conditions["currentMedications"] = [
        m.model_dump() if hasattr(m, "model_dump") else m
        for m in req.currentMedications
    ]
    await update_user_field(req.userId, {
        "healthConditions": conditions,
        "onboardingStep": 5,
    })
    return success_response(message="Health conditions saved")


@router.post("/step6/upload-report")
async def step6_upload_report(
    userId: str = Form(...),
    file: UploadFile = File(...),
):
    file_bytes = await file.read()
    mime_type = file.content_type or "application/pdf"

    # Send to Gemini for extraction
    extracted = await extract_medical_report(file_bytes, mime_type)

    report_id = str(uuid.uuid4())
    report_doc = {
        "reportId": report_id,
        "fileName": file.filename,
        "uploadedAt": _now(),
        "geminiExtracted": extracted,
        "userConfirmed": False,  # NEVER auto-confirm — user must explicitly confirm
    }

    db = get_db()
    await db["users"].update_one(
        {"userId": userId},
        {
            "$push": {"medicalReports": report_doc},
            "$set": {"updatedAt": _now(), "onboardingStep": 5},
        },
    )

    return success_response(
        data={"reportId": report_id, "extractedData": extracted},
        message="Report uploaded and analyzed",
    )


@router.post("/step6/confirm-report")
async def step6_confirm_report(req: ConfirmReportRequest):
    """
    User explicitly confirms extracted report data.
    HARD RULE: Only saves when user taps 'Confirm & Save'.
    """
    db = get_db()
    await db["users"].update_one(
        {"userId": req.userId, "medicalReports.reportId": req.reportId},
        {
            "$set": {
                "medicalReports.$.geminiExtracted": req.confirmedData,
                "medicalReports.$.userConfirmed": True,
                "updatedAt": _now(),
            }
        },
    )
    return success_response(message="Report confirmed and saved")


@router.post("/calculate-ojas")
async def calculate_ojas_endpoint(req: CalculateOjasRequest):
    user = await get_user_by_id(req.userId)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    result = calculate_ojas(user)

    await update_user_field(req.userId, {
        "ojasScore": result["ojasScore"],
        "ojasBreakdown": result["breakdown"],
    })

    return success_response(data=result, message="OJAS score calculated")


@router.post("/complete")
async def complete_onboarding(req: CompleteOnboardingRequest):
    user = await get_user_by_id(req.userId)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    await update_user_field(req.userId, {
        "isOnboarded": True,
        "onboardingStep": 6,
        "profile.completionPercent": 100,
    })

    return success_response(
        data={
            "prakritiResult": user.get("prakritiResult"),
            "ojasScore": user.get("ojasScore"),
            "completionPercent": 100,
        },
        message="Onboarding complete!",
    )


@router.get("/status/{user_id}")
async def onboarding_status(user_id: str):
    user = await get_user_by_id(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    return success_response(data={
        "isOnboarded": user.get("isOnboarded", False),
        "onboardingStep": user.get("onboardingStep", 0),
        "completionPercent": user.get("profile", {}).get("completionPercent", 0),
    })
