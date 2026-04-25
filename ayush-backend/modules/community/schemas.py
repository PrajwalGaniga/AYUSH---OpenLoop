from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime
from enum import Enum

class AvailabilityEnum(str, Enum):
    few = "few"
    moderate = "moderate"
    abundant = "abundant"

class ContactPreferenceEnum(str, Enum):
    in_app = "in_app"
    whatsapp = "whatsapp"
    none = "none"

class PostStatusEnum(str, Enum):
    active = "active"
    review = "review"
    archived = "archived"

class PostLocationSchema(BaseModel):
    geohash: str
    lat: float
    lng: float
    neighborhood: str      # reverse geocoded display name

class CreatePostRequest(BaseModel):
    user_id: str
    user_display_name: str
    plant_name: str
    plant_key: str = ""   # from Module 6 if used
    description: str = Field(..., max_length=300)
    availability: AvailabilityEnum
    location: PostLocationSchema
    contact_preference: ContactPreferenceEnum = ContactPreferenceEnum.in_app
    whatsapp_number: Optional[str] = None  # only if contact_preference == whatsapp

class PlantPostResponse(BaseModel):
    post_id: str
    user_id: str
    user_display_name: str
    plant_name: str
    plant_key: str
    description: str
    availability: str
    photo_urls: List[str]     # full URLs: http://host/uploads/community/filename.jpg
    location: PostLocationSchema
    contact_preference: str
    whatsapp_number: Optional[str]
    saved_by_count: int
    is_saved: bool            # computed per requesting user
    flag_count: int
    status: str
    days_left: int            # 30 - days since creation
    created_at: datetime
    distance_km: Optional[float] = None   # computed client-side or passed in

class NearbyPostsRequest(BaseModel):
    user_lat: float
    user_lng: float
    radius_km: float = 20.0
    plant_name_filter: Optional[str] = None
    availability_filter: Optional[str] = None
    page: int = 1
    page_size: int = 20

class ContactRequestCreate(BaseModel):
    from_user_id: str
    from_display_name: str
    to_user_id: str
    post_id: str
    plant_name: str
    message: str = Field(..., min_length=10, max_length=500)

class ContactRequestResponse(BaseModel):
    request_id: str
    from_user_id: str
    from_display_name: str
    post_id: str
    plant_name: str
    message: str
    status: str   # pending | accepted | declined
    created_at: datetime

class FlagPostRequest(BaseModel):
    user_id: str
    reason: str   # "spam" | "wrong_info" | "inappropriate"
