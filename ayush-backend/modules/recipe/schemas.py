from pydantic import BaseModel, Field
from typing import List, Optional


class RecipeGenerateRequest(BaseModel):
    user_id: str
    ingredients: List[str]
    spices: List[str]
    prakriti: str = "Unknown"
    conditions: List[str] = []
    diet: str = "Omnivore"
    region: str = "India"
    language: str = "English"


class RecipeStep(BaseModel):
    step_number: int
    instruction: str


class RecipeIngredient(BaseModel):
    name: str
    quantity: str


class RecipeDoshaImpact(BaseModel):
    vata: str
    pitta: str
    kapha: str
    overall_ojas: int


class RecipeResponse(BaseModel):
    name: str
    description: str
    ingredients: List[RecipeIngredient]
    steps: List[RecipeStep]
    dosha_impact: RecipeDoshaImpact
    best_time: str
    is_viruddha: bool = False
    viruddha_reason: str = ""


class YouTubeVideo(BaseModel):
    video_id: str
    title: str
    channel_name: str
    thumbnail_url: str


class YouTubeSearchResponse(BaseModel):
    videos: List[YouTubeVideo]
    cached: bool = False
