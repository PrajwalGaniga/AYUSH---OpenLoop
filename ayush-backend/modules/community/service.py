import math
import uuid
import shutil
from pathlib import Path
from datetime import datetime, timedelta
from typing import List, Optional
from bson import ObjectId
from database.mongodb import get_db
from config.settings import settings

UPLOAD_DIR = Path("uploads/community")
# Photo URLs use ngrok URL so images load correctly on physical devices
BASE_URL = settings.ngrok_url

# ─────────────────────────────────────────
# GEOHASH (pure Python, no package needed)
# ─────────────────────────────────────────
_BASE32 = '0123456789bcdefghjkmnpqrstuvwxyz'

def geohash_encode(lat: float, lng: float, precision: int = 6) -> str:
    is_even = True
    min_lat, max_lat = -90.0, 90.0
    min_lng, max_lng = -180.0, 180.0
    bit, ch, geohash = 4, 0, ""
    while len(geohash) < precision:
        if is_even:
            mid = (min_lng + max_lng) / 2
            if lng > mid: ch |= (1 << bit); min_lng = mid
            else: max_lng = mid
        else:
            mid = (min_lat + max_lat) / 2
            if lat > mid: ch |= (1 << bit); min_lat = mid
            else: max_lat = mid
        is_even = not is_even
        if bit > 0: bit -= 1
        else: geohash += _BASE32[ch]; bit = 4; ch = 0
    return geohash

def haversine_km(lat1, lng1, lat2, lng2) -> float:
    R = 6371.0
    d_lat = math.radians(lat2 - lat1)
    d_lng = math.radians(lng2 - lng1)
    a = math.sin(d_lat/2)**2 + \
        math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * \
        math.sin(d_lng/2)**2
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))

def get_radius_prefix(lat: float, lng: float, radius_km: float) -> str:
    # precision 4 = ~40km cell, covers 20km radius safely
    # precision 5 = ~5km cell, use for tight radius
    precision = 4 if radius_km >= 20 else 5
    return geohash_encode(lat, lng, precision)

# ─────────────────────────────────────────
# HELPER
# ─────────────────────────────────────────
def _doc_to_response(doc: dict, requesting_user_id: str,
                      user_lat: float = None, user_lng: float = None) -> dict:
    created_at = doc.get("created_at", datetime.utcnow())
    days_left = max(0, 30 - (datetime.utcnow() - created_at).days)
    distance = None
    if user_lat and user_lng:
        loc = doc.get("location", {})
        distance = round(haversine_km(
            user_lat, user_lng, loc.get("lat", 0), loc.get("lng", 0)
        ), 2)
    # Build absolute photo URLs
    photo_urls = []
    for filename in doc.get("photo_filenames", []):
        photo_urls.append(f"{BASE_URL}/uploads/community/{filename}")
    return {
        "post_id": str(doc["_id"]),
        "user_id": doc["user_id"],
        "user_display_name": doc["user_display_name"],
        "plant_name": doc["plant_name"],
        "plant_key": doc.get("plant_key", ""),
        "description": doc["description"],
        "availability": doc["availability"],
        "photo_urls": photo_urls,
        "location": doc["location"],
        "contact_preference": doc.get("contact_preference", "in_app"),
        "whatsapp_number": doc.get("whatsapp_number") if doc.get("contact_preference") == "whatsapp" else None,
        "saved_by_count": len(doc.get("saved_by", [])),
        "is_saved": requesting_user_id in doc.get("saved_by", []),
        "flag_count": doc.get("flag_count", 0),
        "status": doc.get("status", "active"),
        "days_left": days_left,
        "created_at": created_at,
        "distance_km": distance,
    }

# ─────────────────────────────────────────
# CORE FUNCTIONS
# ─────────────────────────────────────────
async def create_post(data: dict, photo_filenames: List[str]) -> str:
    db = get_db()
    plant_posts_collection = db["plant_posts"]
    
    # Check active post limit for user
    active_count = await plant_posts_collection.count_documents({
        "user_id": data["user_id"],
        "status": "active"
    })
    if active_count >= 5:
        raise ValueError("MAX_POSTS_REACHED")
    
    post_id = str(ObjectId())
    now = datetime.utcnow()
    doc = {
        "_id": ObjectId(post_id),
        **data,
        "photo_filenames": photo_filenames,
        "saved_by": [],
        "flag_count": 0,
        "flagged_by": [],
        "status": "active",
        "created_at": now,
        "expires_at": now + timedelta(days=30),
    }
    await plant_posts_collection.insert_one(doc)
    return post_id

async def get_nearby_posts(user_lat: float, user_lng: float,
                            radius_km: float, requesting_user_id: str,
                            plant_name_filter: str = None,
                            availability_filter: str = None,
                            page: int = 1, page_size: int = 20) -> List[dict]:
    db = get_db()
    plant_posts_collection = db["plant_posts"]
    
    prefix = get_radius_prefix(user_lat, user_lng, radius_km)
    query = {
        "status": "active",
        "location.geohash": {"$regex": f"^{prefix}"}
    }
    if availability_filter:
        query["availability"] = availability_filter
    if plant_name_filter:
        query["plant_name"] = {"$regex": plant_name_filter, "$options": "i"}

    cursor = plant_posts_collection.find(query) \
        .sort("created_at", -1) \
        .skip((page - 1) * page_size) \
        .limit(page_size * 2)  # fetch more, filter by actual distance

    results = []
    async for doc in cursor:
        loc = doc.get("location", {})
        dist = haversine_km(user_lat, user_lng, loc.get("lat", 0), loc.get("lng", 0))
        if dist <= radius_km:
            r = _doc_to_response(doc, requesting_user_id, user_lat, user_lng)
            r["distance_km"] = round(dist, 2)
            results.append(r)

    results.sort(key=lambda x: x["distance_km"] or 999)
    return results[:page_size]

async def get_post(post_id: str, requesting_user_id: str) -> Optional[dict]:
    db = get_db()
    plant_posts_collection = db["plant_posts"]
    
    doc = await plant_posts_collection.find_one({"_id": ObjectId(post_id)})
    if not doc: return None
    return _doc_to_response(doc, requesting_user_id)

async def toggle_save(post_id: str, user_id: str) -> bool:
    db = get_db()
    plant_posts_collection = db["plant_posts"]
    
    doc = await plant_posts_collection.find_one({"_id": ObjectId(post_id)})
    if not doc: raise ValueError("Post not found")
    saved_by = doc.get("saved_by", [])
    if user_id in saved_by:
        await plant_posts_collection.update_one(
            {"_id": ObjectId(post_id)},
            {"$pull": {"saved_by": user_id}}
        )
        return False  # now unsaved
    else:
        await plant_posts_collection.update_one(
            {"_id": ObjectId(post_id)},
            {"$addToSet": {"saved_by": user_id}}
        )
        return True  # now saved

async def flag_post(post_id: str, user_id: str, reason: str):
    db = get_db()
    plant_posts_collection = db["plant_posts"]
    
    doc = await plant_posts_collection.find_one({"_id": ObjectId(post_id)})
    if not doc: raise ValueError("Post not found")
    if user_id in doc.get("flagged_by", []):
        raise ValueError("ALREADY_FLAGGED")
    new_count = doc.get("flag_count", 0) + 1
    new_status = doc.get("status", "active")
    if new_count >= 5: new_status = "archived"
    elif new_count >= 3: new_status = "review"
    await plant_posts_collection.update_one(
        {"_id": ObjectId(post_id)},
        {
            "$inc": {"flag_count": 1},
            "$addToSet": {"flagged_by": user_id},
            "$set": {"status": new_status}
        }
    )

async def delete_post(post_id: str, user_id: str):
    db = get_db()
    plant_posts_collection = db["plant_posts"]
    
    doc = await plant_posts_collection.find_one({"_id": ObjectId(post_id)})
    if not doc: raise ValueError("Not found")
    if doc["user_id"] != user_id: raise ValueError("UNAUTHORIZED")
    # Delete photo files
    for fname in doc.get("photo_filenames", []):
        fpath = UPLOAD_DIR / fname
        if fpath.exists(): fpath.unlink()
    await plant_posts_collection.delete_one({"_id": ObjectId(post_id)})

async def get_my_posts(user_id: str) -> List[dict]:
    db = get_db()
    plant_posts_collection = db["plant_posts"]
    
    cursor = plant_posts_collection.find({"user_id": user_id}).sort("created_at", -1)
    results = []
    async for doc in cursor:
        results.append(_doc_to_response(doc, user_id))
    return results

async def send_contact_request(data: dict) -> str:
    db = get_db()
    contact_requests_collection = db["contact_requests"]
    
    # Prevent duplicate requests to same post
    existing = await contact_requests_collection.find_one({
        "from_user_id": data["from_user_id"],
        "post_id": data["post_id"],
        "status": "pending"
    })
    if existing: raise ValueError("REQUEST_ALREADY_SENT")
    doc = {
        "_id": ObjectId(),
        **data,
        "status": "pending",
        "created_at": datetime.utcnow()
    }
    await contact_requests_collection.insert_one(doc)
    return str(doc["_id"])

async def get_my_requests(user_id: str) -> List[dict]:
    db = get_db()
    contact_requests_collection = db["contact_requests"]
    
    # Requests received by user (as post owner)
    cursor = contact_requests_collection.find(
        {"to_user_id": user_id}
    ).sort("created_at", -1)
    results = []
    async for doc in cursor:
        results.append({
            "request_id": str(doc["_id"]),
            "from_user_id": doc["from_user_id"],
            "from_display_name": doc["from_display_name"],
            "post_id": doc["post_id"],
            "plant_name": doc["plant_name"],
            "message": doc["message"],
            "status": doc["status"],
            "created_at": doc["created_at"],
        })
    return results

async def respond_to_request(request_id: str, user_id: str, accept: bool):
    db = get_db()
    contact_requests_collection = db["contact_requests"]
    
    doc = await contact_requests_collection.find_one({"_id": ObjectId(request_id)})
    if not doc: raise ValueError("Not found")
    if doc["to_user_id"] != user_id: raise ValueError("UNAUTHORIZED")
    await contact_requests_collection.update_one(
        {"_id": ObjectId(request_id)},
        {"$set": {"status": "accepted" if accept else "declined"}}
    )
