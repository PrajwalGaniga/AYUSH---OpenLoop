from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime


# ─── Auth Models ─────────────────────────────────────────────────────────────

class RegisterRequest(BaseModel):
    phone: str
    password: str


class LoginRequest(BaseModel):
    phone: str
    password: str


class AuthResponse(BaseModel):
    userId: str
    token: str
    isOnboarded: bool
    onboardingStep: int
    profile: Optional[Dict] = None


# ─── Onboarding Step Models ───────────────────────────────────────────────────

class Step1Request(BaseModel):
    userId: str
    fullName: str
    age: Optional[int] = None
    dob: Optional[str] = None
    gender: str
    heightCm: Optional[float] = None
    weightKg: Optional[float] = None
    bloodGroup: Optional[str] = None
    language: str = "en"
    region: Optional[str] = None


class PainPoint(BaseModel):
    region: str
    severity: int = Field(ge=1, le=5)
    description: Optional[str] = ""
    timing: Optional[List[str]] = []
    duration: Optional[str] = ""


class Step2BodyScanRequest(BaseModel):
    userId: str
    painPoints: List[PainPoint] = []


class PhysicalTraitsRequest(BaseModel):
    userId: str
    bodyFrame: Optional[str] = None
    skinType: Optional[str] = None
    hairTexture: Optional[str] = None
    eyeCharacteristics: Optional[str] = None
    appetiteType: Optional[str] = None
    digestionQuality: Optional[str] = None
    bowelRegularity: Optional[str] = None
    sweatTendency: Optional[str] = None
    sleepQuality: Optional[str] = None
    energyLevels: Optional[str] = None
    voiceQuality: Optional[str] = None


class PrakritiAnswer(BaseModel):
    questionId: str
    selectedDosha: str  # "vata" | "pitta" | "kapha"


class Step3AnswersRequest(BaseModel):
    userId: str
    answers: List[PrakritiAnswer]


class Step3CalculateRequest(BaseModel):
    userId: str


class PrakritiResult(BaseModel):
    dominant: str
    secondary: Optional[str] = None
    type: str
    scores: Dict[str, int]


class Step4LifestyleRequest(BaseModel):
    userId: str
    occupationType: Optional[str] = None
    stressLevel: Optional[str] = None
    exerciseFrequency: Optional[str] = None
    dietType: Optional[str] = None
    waterIntakeLiters: Optional[float] = None
    sleepHours: Optional[float] = None
    smokingStatus: Optional[str] = None
    alcoholStatus: Optional[str] = None
    screenTimeHours: Optional[float] = None
    yogaPractice: Optional[bool] = False
    meditationPractice: Optional[bool] = False


class MedicationItem(BaseModel):
    name: str
    dosage: Optional[str] = None
    frequency: Optional[str] = None


class Step5HealthConditionsRequest(BaseModel):
    userId: str
    diagnosedConditions: List[str] = []
    chronicConditions: List[str] = []
    allergies: List[str] = []
    currentMedications: List[MedicationItem] = []
    surgeries: List[str] = []
    familyHistory: List[str] = []
    mentalHealthConditions: List[str] = []


class ConfirmReportRequest(BaseModel):
    userId: str
    reportId: str
    confirmedData: Dict[str, Any]


class CalculateOjasRequest(BaseModel):
    userId: str


class CompleteOnboardingRequest(BaseModel):
    userId: str


# ─── OJAS Response ────────────────────────────────────────────────────────────

class OjasBreakdown(BaseModel):
    base: int
    penalties: List[Dict]
    bonuses: List[Dict]
    totalPenalty: int
    totalBonus: int
    final: int


class OjasResponse(BaseModel):
    ojasScore: int
    breakdown: OjasBreakdown
