import uuid
import aiofiles
import logging
from pathlib import Path
from typing import List, Optional
from fastapi import APIRouter, UploadFile, File, Form, HTTPException, Query
from fastapi.responses import JSONResponse
from modules.community import service
from modules.community.schemas import (
    NearbyPostsRequest, ContactRequestCreate, FlagPostRequest
)

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/v1/community", tags=["community"])
UPLOAD_DIR = Path("uploads/community")
ALLOWED_TYPES = {"image/jpeg", "image/jpg", "image/png", "image/webp", "image/heic", "image/heif"}
MAX_FILE_SIZE = 5 * 1024 * 1024  # 5MB

# ── CREATE POST ──────────────────────────────────────────
@router.post("/posts")
async def create_post(
    user_id: str = Form(...),
    user_display_name: str = Form(...),
    plant_name: str = Form(...),
    plant_key: str = Form(""),
    description: str = Form(...),
    availability: str = Form(...),
    contact_preference: str = Form("in_app"),
    whatsapp_number: Optional[str] = Form(None),
    location_lat: float = Form(...),
    location_lng: float = Form(...),
    location_neighborhood: str = Form(...),
    photos: List[UploadFile] = File(...),
):
    if len(photos) > 3:
        raise HTTPException(400, "Maximum 3 photos allowed")
    if len(description) > 300:
        raise HTTPException(400, "Description max 300 characters")

    # Validate and save photos
    photo_filenames = []
    for photo in photos:
        content_type = (photo.content_type or "").lower().strip()
        # Normalize content type — some devices send image/jpg instead of image/jpeg
        if content_type == "image/jpg":
            content_type = "image/jpeg"
        if content_type not in ALLOWED_TYPES:
            logger.warning(f"Rejected photo with content_type={photo.content_type!r}")
            raise HTTPException(400, f"Invalid file type: {photo.content_type}. Use JPEG, PNG, or WebP")
        content = await photo.read()
        if len(content) > MAX_FILE_SIZE:
            raise HTTPException(400, "Each photo must be under 5MB")
        
        filename = f"{uuid.uuid4()}.jpg"
        filepath = UPLOAD_DIR / filename
        async with aiofiles.open(filepath, 'wb') as f:
            await f.write(content)
        photo_filenames.append(filename)

    geohash = service.geohash_encode(location_lat, location_lng)
    
    data = {
        "user_id": user_id,
        "user_display_name": user_display_name,
        "plant_name": plant_name,
        "plant_key": plant_key,
        "description": description,
        "availability": availability,
        "contact_preference": contact_preference,
        "whatsapp_number": whatsapp_number if contact_preference == "whatsapp" else None,
        "location": {
            "geohash": geohash,
            "lat": location_lat,
            "lng": location_lng,
            "neighborhood": location_neighborhood,
        }
    }

    try:
        post_id = await service.create_post(data, photo_filenames)
    except ValueError as e:
        if str(e) == "MAX_POSTS_REACHED":
            raise HTTPException(400, "You can have at most 5 active posts")
        raise HTTPException(500, str(e))

    return {"post_id": post_id, "message": "Post created successfully"}


# ── NEARBY POSTS ─────────────────────────────────────────
@router.get("/posts/nearby")
async def get_nearby_posts(
    user_id: str = Query(...),
    user_lat: float = Query(...),
    user_lng: float = Query(...),
    radius_km: float = Query(20.0),
    plant_name: Optional[str] = Query(None),
    availability: Optional[str] = Query(None),
    page: int = Query(1),
):
    posts = await service.get_nearby_posts(
        user_lat=user_lat, user_lng=user_lng,
        radius_km=radius_km, requesting_user_id=user_id,
        plant_name_filter=plant_name, availability_filter=availability,
        page=page
    )
    return {"posts": posts, "count": len(posts)}


# ── SINGLE POST ───────────────────────────────────────────
@router.get("/posts/{post_id}")
async def get_post(post_id: str, user_id: str = Query(...)):
    post = await service.get_post(post_id, user_id)
    if not post:
        raise HTTPException(404, "Post not found")
    return post


# ── SAVE / UNSAVE ─────────────────────────────────────────
@router.post("/posts/{post_id}/save")
async def toggle_save(post_id: str, user_id: str = Query(...)):
    try:
        is_saved = await service.toggle_save(post_id, user_id)
        return {"is_saved": is_saved}
    except ValueError:
        raise HTTPException(404, "Post not found")


# ── FLAG POST ─────────────────────────────────────────────
@router.post("/posts/{post_id}/flag")
async def flag_post(post_id: str, body: FlagPostRequest):
    try:
        await service.flag_post(post_id, body.user_id, body.reason)
        return {"message": "Post flagged"}
    except ValueError as e:
        if str(e) == "ALREADY_FLAGGED":
            raise HTTPException(400, "You have already flagged this post")
        raise HTTPException(404, str(e))


# ── DELETE POST ───────────────────────────────────────────
@router.delete("/posts/{post_id}")
async def delete_post(post_id: str, user_id: str = Query(...)):
    try:
        await service.delete_post(post_id, user_id)
        return {"message": "Post deleted"}
    except ValueError as e:
        if str(e) == "UNAUTHORIZED":
            raise HTTPException(403, "Not your post")
        raise HTTPException(404, "Post not found")


# ── MY POSTS ──────────────────────────────────────────────
@router.get("/posts/user/{user_id}")
async def get_my_posts(user_id: str):
    posts = await service.get_my_posts(user_id)
    return {"posts": posts}


# ── CONTACT REQUEST ───────────────────────────────────────
@router.post("/contact-requests")
async def send_contact_request(body: ContactRequestCreate):
    try:
        req_id = await service.send_contact_request(body.dict())
        return {"request_id": req_id, "message": "Request sent"}
    except ValueError as e:
        if str(e) == "REQUEST_ALREADY_SENT":
            raise HTTPException(400, "You already sent a request for this post")
        raise HTTPException(500, str(e))


# ── MY RECEIVED REQUESTS ──────────────────────────────────
@router.get("/contact-requests/received")
async def get_received_requests(user_id: str = Query(...)):
    requests = await service.get_my_requests(user_id)
    return {"requests": requests}


# ── RESPOND TO REQUEST ────────────────────────────────────
@router.patch("/contact-requests/{request_id}")
async def respond_to_request(
    request_id: str,
    user_id: str = Query(...),
    accept: bool = Query(...),
):
    try:
        await service.respond_to_request(request_id, user_id, accept)
        return {"message": "accepted" if accept else "declined"}
    except ValueError as e:
        raise HTTPException(403 if "UNAUTHORIZED" in str(e) else 404, str(e))
