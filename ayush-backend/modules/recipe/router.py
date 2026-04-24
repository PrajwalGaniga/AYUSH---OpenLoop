from fastapi import APIRouter
from typing import Dict, Any

from .schemas import RecipeGenerateRequest, YouTubeSearchResponse
from .service import generate_recipe, search_youtube, get_history, delete_history

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

@router.get("/history/{user_id}")
async def get_user_recipe_history(user_id: str):
    """
    Get all past generated recipes for a user.
    """
    return await get_history(user_id)

@router.delete("/history/{recipe_hash}")
async def delete_recipe_from_history(recipe_hash: str):
    """
    Delete a specific recipe from history.
    """
    success = await delete_history(recipe_hash)
    return {"success": success}
