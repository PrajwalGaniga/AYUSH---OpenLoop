from pydantic import BaseModel
from typing import Optional, List

class PlantQuestionRequest(BaseModel):
    plant_name: str
    plant_scientific: str
    user_question: str
    prakriti: Optional[str] = None
    conditions: Optional[List[str]] = []
    medications: Optional[List[str]] = []

class PlantQuestionResponse(BaseModel):
    plant_name: str
    question: str
    answer: str
    sources_mentioned: List[str]
    disclaimer: str
    confidence_note: str
