from fastapi import APIRouter
from typing import Dict, Any

from .schemas import RecipeGenerateRequest, YouTubeSearchResponse
from .service import generate_recipe, search_youtube

router = APIRouter(prefix="/recipe", tags=["Recipe Generator"])

@router.post("/generate")
async def generate_recipe_endpoint(request: RecipeGenerateRequest) -> Dict[str, Any]:
    """
    Generate an Ayurvedic recipe based on ingredients and profile.
    Uses Gemini 2.5 Flash and checks cache to save credits.
    """
    return await generate_recipe(request)

@router.get("/youtube", response_model=YouTubeSearchResponse)
async def youtube_search_endpoint(query: str):
    """
    Search YouTube for a recipe name and cache the results.
    """
    return await search_youtube(query)
