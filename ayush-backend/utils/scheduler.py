import asyncio
import logging
from datetime import datetime, timedelta, timezone

from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger

from database.mongodb import get_db

logger = logging.getLogger(__name__)

scheduler = AsyncIOScheduler()

async def consolidate_daily_log_for_user(db, user, target_date_str: str):
    """
    Consolidate all logs for a specific user and date into the daily_logs collection.
    target_date_str should be 'YYYY-MM-DD'
    """
    user_id = user["userId"]
    
    # Parse target_date to get start and end of day in UTC
    target_date = datetime.strptime(target_date_str, "%Y-%m-%d").replace(tzinfo=timezone.utc)
    start_of_day = target_date
    end_of_day = target_date + timedelta(days=1)

    # Base user features
    base_ojas = float(user.get("ojasScore", 83))
    
    # Checkins (sleep, stress, energy)
    checkin = await db["checkins"].find_one({"userId": user_id, "date": target_date_str})
    sleep_quality = float(checkin["sleep_quality"]) if checkin and "sleep_quality" in checkin else 7.0
    stress_level = float(checkin["stress_level"]) if checkin and "stress_level" in checkin else 3.0
    energy_level = float(checkin["energy_level"]) if checkin and "energy_level" in checkin else 7.0

    # Food Logs (food_quality_score, viruddha_violations)
    food_cursor = db["food_logs"].find({
        "userId": user_id,
        "loggedAt": {"$gte": start_of_day, "$lt": end_of_day}
    })
    
    food_scores = []
    viruddha_count = 0
    async for f_log in food_cursor:
        food_scores.append(float(f_log.get("meal_quality_score", 50)))
        viruddha_count += len(f_log.get("viruddhaWarnings", []))
        
    food_quality_score = round(sum(food_scores)/len(food_scores), 1) if food_scores else 50.0

    # Yoga Logs (yoga_done, yoga_accuracy_percent)
    yoga_cursor = db["session_logs"].find({
        "user_id": user_id,
        "date_key": target_date_str
    })
    
    yoga_acc = []
    async for y_log in yoga_cursor:
        yoga_acc.append(float(y_log.get("average_accuracy", 0)))
        
    yoga_done = 1 if yoga_acc else 0
    yoga_accuracy_percent = round(sum(yoga_acc)/len(yoga_acc), 1) if yoga_acc else 0.0

    # Tongue Logs (tongue_coating, tongue_color)
    tongue_log = await db["analysis_captures"].find_one(
        {"user_id": user_id, "type": "tongue", "timestamp": {"$gte": start_of_day, "$lt": end_of_day}},
        sort=[("timestamp", -1)]
    )
    tongue_coating = float(tongue_log.get("tongue_coating", 2.0)) if tongue_log else 2.0
    
    # We map tongue_color label to the float the LSTM expects (0.0=Pink, 1.0=Pale, etc.)
    # In a real system this mapping would be exact. Here we approximate from the model.
    tongue_color_val = 0.0
    if tongue_log:
        color_label = tongue_log.get("tongue_color", "pink").lower()
        if "pale" in color_label: tongue_color_val = 1.0
        elif "red" in color_label: tongue_color_val = 2.0
        elif "purple" in color_label or "blue" in color_label: tongue_color_val = 3.0

    # Eye Logs (eye_redness)
    eye_log = await db["analysis_captures"].find_one(
        {"user_id": user_id, "type": "eye", "timestamp": {"$gte": start_of_day, "$lt": end_of_day}},
        sort=[("timestamp", -1)]
    )
    eye_redness = float(eye_log.get("eye_redness", 0.5)) if eye_log else 0.5

    # Nadi History (heart_rate_bpm)
    nadi_history = user.get("nadiHistory", [])
    today_nadi = [
        float(n["bpm"]) for n in nadi_history 
        if start_of_day <= n.get("timestamp", start_of_day) < end_of_day
    ]
    heart_rate_bpm = round(sum(today_nadi)/len(today_nadi), 1) if today_nadi else 72.0

    features = {
        "food_quality_score": food_quality_score,
        "viruddha_violations": viruddha_count,
        "yoga_done": yoga_done,
        "yoga_accuracy_percent": yoga_accuracy_percent,
        "ojas_score": base_ojas,
        "tongue_coating": tongue_coating,
        "tongue_color": tongue_color_val,
        "eye_redness": eye_redness,
        "heart_rate_bpm": heart_rate_bpm,
        "sleep_quality": sleep_quality,
        "stress_level": stress_level,
        "energy_level": energy_level,
    }

    sources_used = {
        "food_logs": bool(food_scores),
        "tongue_captures": bool(tongue_log),
        "eye_captures": bool(eye_log),
        "nadi_history": bool(today_nadi),
        "yoga": bool(yoga_done),
        "checkins": bool(checkin)
    }

    now = datetime.now(timezone.utc)
    
    # Upsert the daily log
    await db["daily_logs"].update_one(
        {"userId": user_id, "date": target_date_str},
        {
            "$set": {
                "userId": user_id,
                "date": target_date_str,
                "features": features,
                "sources_used": sources_used,
                "consolidated": True,
                "schema_version": "1.0",
                "data_tag": "live_consolidation",
                "updated_at": now,
            },
            "$setOnInsert": {"created_at": now}
        },
        upsert=True
    )
    
    logger.info(f"Consolidated daily_log for {user_id} on {target_date_str}")

async def consolidate_all_users_daily_logs():
    """
    Run the consolidation for all users for yesterday's data.
    """
    logger.info("Starting midnight consolidation cron job...")
    db = get_db()
    
    # Usually we consolidate "yesterday" if running exactly at midnight.
    # We will do yesterday.
    yesterday = datetime.now(timezone.utc) - timedelta(days=1)
    target_date_str = yesterday.strftime("%Y-%m-%d")
    
    async for user in db["users"].find():
        try:
            await consolidate_daily_log_for_user(db, user, target_date_str)
        except Exception as e:
            logger.error(f"Error consolidating for user {user.get('userId')}: {str(e)}")
            
    logger.info("Midnight consolidation completed successfully.")

def start_scheduler():
    # Run every day at 00:01 UTC
    scheduler.add_job(
        consolidate_all_users_daily_logs, 
        CronTrigger(hour=0, minute=1, timezone=timezone.utc),
        id="midnight_consolidation",
        replace_existing=True
    )
    scheduler.start()
    logger.info("APScheduler started for daily_logs consolidation.")

def stop_scheduler():
    scheduler.shutdown()
    logger.info("APScheduler stopped.")
