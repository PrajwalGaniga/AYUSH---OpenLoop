from pydantic import BaseModel
from typing import Optional

class SOSTriggerRequest(BaseModel):
    guardian_phone: str          # Full E.164 format, e.g. "+919324815718"
    user_name: Optional[str] = "AYUSH User"
    latitude: Optional[float] = None
    longitude: Optional[float] = None

class SOSTriggerResponse(BaseModel):
    success: bool
    call_sid: Optional[str] = None
    sms_sid: Optional[str] = None
    message: str
