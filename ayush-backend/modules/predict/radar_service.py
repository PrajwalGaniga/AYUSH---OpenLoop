import json
import logging
from datetime import date, timedelta
from database.mongodb import get_db
import google.generativeai as genai
from config.settings import settings

logger = logging.getLogger(__name__)

# Initialize Gemini Client for Radar
genai.configure(api_key=settings.radar_gemini_api_key)

async def _fetch_7day_features(user_id: str) -> list:
    """Fetches the last 7 consolidated daily_logs for a user."""
    db = get_db()
    daily_logs_collection = db["daily_logs"]
    
    today = date.today()
    feature_docs = []

    for i in range(6, -1, -1):  # day-6 (oldest) to day-0 (today)
        target_date = (today - timedelta(days=i)).isoformat()
        doc = await daily_logs_collection.find_one(
            {"userId": user_id, "date": target_date}
        )

        if not doc or "features" not in doc:
            feature_docs.append({"date": target_date, "data": "missing"})
        else:
            feat = doc["features"]
            feature_docs.append({
                "date": target_date,
                "food_quality_score": feat.get("food_quality_score", 50),
                "yoga_done": feat.get("yoga_done", False),
                "tongue_coating": feat.get("tongue_coating", 0),
                "eye_redness": feat.get("eye_redness", 0),
                "heart_rate_bpm": feat.get("heart_rate_bpm", 72),
                "sleep_quality": feat.get("sleep_quality", 7),
                "stress_level": feat.get("stress_level", 3),
                "energy_level": feat.get("energy_level", 7),
            })

    return feature_docs

async def generate_radar_analysis(user_id: str, date_key: str):
    """
    Background task triggered by daily check-in submission.
    Uses Gemini 2.5 Flash to generate a predictive LSTM-style radar analysis.
    """
    logger.info(f"[Radar Service] Generating analysis for {user_id} on {date_key}")
    
    db = get_db()
    users_collection = db["users"]
    
    # Get user prakriti context
    user_doc = await users_collection.find_one({"userId": user_id})
    prakriti = user_doc.get("prakriti", "vata") if user_doc else "vata"
    
    # Fetch 7 day history
    history = await _fetch_7day_features(user_id)
    
    # Construct the highly engineered prompt
    prompt = f"""
    You are an advanced Ayurvedic Predictive Engine (acting as an LSTM surrogate).
    Your goal is to analyze the following 7-day chronological sequence of biomarkers and output a JSON predictive analysis.
    
    User Profile: Dominant Dosha is {prakriti.upper()}
    
    Chronological Sequence (Oldest to Today):
    {json.dumps(history, indent=2)}
    
    Based on this trajectory, forecast the user's OJAS trajectory for the next 3 days.
    
    You must output ONLY valid JSON using the following structure:
    {{
      "forecast": "rise" | "fall" | "stable",
      "alert_level": "CLEAR" | "WATCH" | "WARNING" | "CRITICAL",
      "explanation": "A 2-3 sentence engaging explanation of WHY the trajectory is what it is, pointing out specific trends in sleep, stress, or tongue coating.",
      "interventions": [
        {{
          "title": "Actionable Title",
          "description": "Specific {prakriti}-friendly recommendation based on the most alarming signal."
        }},
        {{
          "title": "Actionable Title 2",
          "description": "Specific {prakriti}-friendly recommendation."
        }}
      ]
    }}
    
    DO NOT output Markdown blocks like ```json. ONLY output the raw JSON object.
    """
    
    try:
        model = genai.GenerativeModel(settings.packaged_food_gemini_model) # gemini-2.5-flash
        response = model.generate_content(prompt)
        text = response.text.strip()
        
        # Clean potential markdown formatting
        if text.startswith("```json"):
            text = text[7:]
        if text.startswith("```"):
            text = text[3:]
        if text.endswith("```"):
            text = text[:-3]
            
        result_data = json.loads(text.strip())
        
        # Save to DB
        radar_collection = db["radar_analysis"]
        await radar_collection.update_one(
            {"user_id": user_id},
            {
                "$set": {
                    "latest_date": date_key,
                    "analysis": result_data,
                    "updated_at": date.today().isoformat()
                }
            },
            upsert=True
        )
        logger.info(f"[Radar Service] Successfully saved analysis for {user_id}")
        
    except Exception as e:
        logger.error(f"[Radar Service] Failed to generate analysis: {e}")
