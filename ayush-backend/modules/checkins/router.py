from fastapi import APIRouter, HTTPException
from datetime import datetime, timezone
import logging

from database.mongodb import get_db
from .schemas import CheckinRequest, CheckinResponse

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/checkins", tags=["Daily Checkins"])

@router.post("", response_model=CheckinResponse)
async def log_daily_checkin(request: CheckinRequest):
    db = get_db()
    now = datetime.now(timezone.utc)
    date_key = now.strftime("%Y-%m-%d")

    try:
        # Upsert the checkin for the day
        await db["checkins"].update_one(
            {
                "userId": request.user_id,
                "date": date_key
            },
            {
                "$set": {
                    "sleep_quality": request.sleep_quality,
                    "stress_level": request.stress_level,
                    "energy_level": request.energy_level,
                    "updatedAt": now
                }
            },
            upsert=True
        )

        logger.info(f"Logged daily checkin for {request.user_id} on {date_key}")
        
        return CheckinResponse(
            status="success",
            message=f"Checkin logged successfully for {date_key}"
        )
    except Exception as e:
        logger.error(f"Error logging checkin: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to log checkin")

@router.post('/trigger-cron')
async def trigger_cron():
    from utils.scheduler import consolidate_all_users_daily_logs
    await consolidate_all_users_daily_logs()
    return {'status': 'Cron triggered manually'}
