import json
import hashlib
from datetime import datetime, timezone, timedelta
import httpx
import google.generativeai as genai
from fastapi import HTTPException

from config.settings import settings
from database.mongodb import get_db
from .schemas import RecipeGenerateRequest, RecipeResponse, YouTubeSearchResponse, YouTubeVideo
from .ritucharya_mapper import get_current_ritu

# Initialize Gemini
genai.configure(api_key=settings.module_3_api_key)
model = genai.GenerativeModel(settings.gemini_model)

async def generate_recipe(request: RecipeGenerateRequest) -> dict:
    db = get_db()
    
    # 1. Generate Cache Hash
    # Hash based on exact ingredients, prakriti, diet to save credits
    hash_input = f"{sorted(request.ingredients)}_{sorted(request.spices)}_{request.prakriti}_{request.diet}_{request.language}"
    recipe_hash = hashlib.md5(hash_input.encode()).hexdigest()
    
    cached = await db["recipes"].find_one({"recipeHash": recipe_hash})
    if cached:
        cached.pop("_id", None)
        return {"data": cached, "cached": True}

    # 2. Prepare Prompt
    ritu = get_current_ritu(request.region)
    ingredients_str = ", ".join(request.ingredients)
    spices_str = ", ".join(request.spices)
    conditions_str = ", ".join(request.conditions) if request.conditions else "None"
    
    prompt = f"""
    You are an expert Ayurvedic Chef. Create a personalized recipe based on these inputs:
    - Primary Ingredients: {ingredients_str}
    - Spices available: {spices_str}
    - User Prakriti (Body Type): {request.prakriti}
    - Health Conditions: {conditions_str}
    - Diet: {request.diet}
    - Current Season (Ritu): {ritu}
    - Language: {request.language}
    
    CRITICAL: YOU MUST RESPOND ONLY IN VALID JSON FORMAT EXACTLY MATCHING THIS SCHEMA. NO MARKDOWN BLOCK, NO OTHER TEXT.
    {{
        "name": "Recipe Name",
        "description": "Short description of why this fits their profile",
        "ingredients": [
            {{"name": "ingredient name", "quantity": "amount"}}
        ],
        "steps": [
            {{"step_number": 1, "instruction": "do this"}}
        ],
        "dosha_impact": {{
            "vata": "Pacifies/Aggravates/Neutral",
            "pitta": "Pacifies/Aggravates/Neutral",
            "kapha": "Pacifies/Aggravates/Neutral",
            "overall_ojas": 5
        }},
        "best_time": "Lunch/Dinner/Breakfast",
        "is_viruddha": false,
        "viruddha_reason": ""
    }}
    Ensure the recipe is NOT Viruddha Ahara (incompatible mixing like milk + fruit). If it is unavoidable based on their ingredients, set is_viruddha to true and explain.
    """

    # 3. Call Gemini with Retry Logic
    try:
        response = model.generate_content(prompt)
        response_text = response.text.strip()
        if response_text.startswith("```json"):
            response_text = response_text[7:-3]
        elif response_text.startswith("```"):
            response_text = response_text[3:-3]
            
        recipe_data = json.loads(response_text)
    except Exception as e:
        # Retry once
        try:
            retry_prompt = prompt + "\n\nCRITICAL FAILURE PREVIOUSLY. RESPOND *ONLY* IN RAW JSON."
            response = model.generate_content(retry_prompt)
            response_text = response.text.strip()
            if response_text.startswith("```json"):
                response_text = response_text[7:-3]
            elif response_text.startswith("```"):
                response_text = response_text[3:-3]
            recipe_data = json.loads(response_text)
        except Exception as retry_e:
            raise HTTPException(status_code=500, detail="Failed to parse AI recipe generation.")

    # Validate against schema just in case
    try:
        validated = RecipeResponse(**recipe_data)
        recipe_data = validated.model_dump()
    except Exception as e:
        raise HTTPException(status_code=500, detail="AI output did not match required schema.")

    # 4. Save to Cache/History
    recipe_data["recipeHash"] = recipe_hash
    recipe_data["userId"] = request.user_id
    recipe_data["createdAt"] = datetime.now(timezone.utc)
    
    await db["recipes"].insert_one(recipe_data)
    
    recipe_data.pop("_id", None)
    return {"data": recipe_data, "cached": False}


async def search_youtube(query: str) -> YouTubeSearchResponse:
    db = get_db()
    query_hash = hashlib.md5(query.lower().encode()).hexdigest()
    
    # Check cache (7-day TTL logic handled here manually)
    cached = await db["yt_cache"].find_one({"queryHash": query_hash})
    if cached:
        cached_time = cached.get("createdAt").replace(tzinfo=timezone.utc)
        if datetime.now(timezone.utc) - cached_time < timedelta(days=7):
            return YouTubeSearchResponse(videos=cached["videos"], cached=True)

    # Cache miss or expired, call YouTube API
    api_key = settings.youtube_api_key
    url = f"https://www.googleapis.com/youtube/v3/search"
    params = {
        "part": "snippet",
        "q": query + " recipe",
        "type": "video",
        "maxResults": 3,
        "key": api_key
    }
    
    async with httpx.AsyncClient() as client:
        response = await client.get(url, params=params)
        
    if response.status_code != 200:
        raise HTTPException(status_code=502, detail="YouTube API error.")
        
    data = response.json()
    videos = []
    for item in data.get("items", []):
        snippet = item.get("snippet", {})
        videos.append(YouTubeVideo(
            video_id=item["id"]["videoId"],
            title=snippet.get("title", ""),
            channel_name=snippet.get("channelTitle", ""),
            thumbnail_url=snippet.get("thumbnails", {}).get("high", {}).get("url", "")
        ))
        
    # Save to cache
    await db["yt_cache"].update_one(
        {"queryHash": query_hash},
        {"$set": {
            "query": query,
            "videos": [v.model_dump() for v in videos],
            "createdAt": datetime.now(timezone.utc)
        }},
        upsert=True
    )
    
    return YouTubeSearchResponse(videos=videos, cached=False)


async def get_history(user_id: str) -> list:
    db = get_db()
    cursor = db["recipes"].find({"userId": user_id}).sort("createdAt", -1)
    history = await cursor.to_list(length=100)
    for h in history:
        h.pop("_id", None)
    return history

async def delete_history(recipe_hash: str) -> bool:
    db = get_db()
    result = await db["recipes"].delete_one({"recipeHash": recipe_hash})
    return result.deleted_count > 0
