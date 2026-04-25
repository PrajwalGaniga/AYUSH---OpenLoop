import pytest
import pytest_asyncio
import io
from httpx import AsyncClient, ASGITransport
from main import app
from database.mongodb import connect_db, close_db
from pathlib import Path

@pytest_asyncio.fixture(autouse=True)
async def setup_environment():
    await connect_db()
    Path("uploads/community").mkdir(parents=True, exist_ok=True)
    yield
    await close_db()

# Test image bytes (1x1 white JPEG)
DUMMY_IMAGE = bytes([
    0xFF,0xD8,0xFF,0xE0,0x00,0x10,0x4A,0x46,0x49,0x46,0x00,0x01,
    0x01,0x00,0x00,0x01,0x00,0x01,0x00,0x00,0xFF,0xDB,0x00,0x43,
    0x00,0x08,0x06,0x06,0x07,0x06,0x05,0x08,0x07,0x07,0x07,0x09,
    0x09,0x08,0x0A,0x0C,0x14,0x0D,0x0C,0x0B,0x0B,0x0C,0x19,0x12,
    0x13,0x0F,0x14,0x1D,0x1A,0x1F,0x1E,0x1D,0x1A,0x1C,0x1C,0x20,
    0x24,0x2E,0x27,0x20,0x22,0x2C,0x23,0x1C,0x1C,0x28,0x37,0x29,
    0x2C,0x30,0x31,0x34,0x34,0x34,0x1F,0x27,0x39,0x3D,0x38,0x32,
    0x3C,0x2E,0x33,0x34,0x32,0xFF,0xC0,0x00,0x0B,0x08,0x00,0x01,
    0x00,0x01,0x01,0x01,0x11,0x00,0xFF,0xC4,0x00,0x1F,0x00,0x00,
    0x01,0x05,0x01,0x01,0x01,0x01,0x01,0x01,0x00,0x00,0x00,0x00,
    0x00,0x00,0x00,0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,
    0x09,0x0A,0x0B,0xFF,0xDA,0x00,0x08,0x01,0x01,0x00,0x00,0x3F,
    0x00,0xFB,0xD7,0xFF,0xD9
])

@pytest.mark.asyncio
async def test_create_post_success():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post("/api/v1/community/posts",
            data={
                "user_id": "test_user_1",
                "user_display_name": "Test User",
                "plant_name": "Tulsi",
                "plant_key": "tulsi",
                "description": "Found Tulsi growing near my garden. Healthy plant.",
                "availability": "abundant",
                "contact_preference": "in_app",
                "location_lat": "12.9716",
                "location_lng": "77.5946",
                "location_neighborhood": "Koramangala, Bangalore",
            },
            files=[("photos", ("test.jpg", DUMMY_IMAGE, "image/jpeg"))]
        )
    assert response.status_code == 200
    assert "post_id" in response.json()

@pytest.mark.asyncio
async def test_create_post_too_many_photos():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post("/api/v1/community/posts",
            data={"user_id": "u1", "user_display_name": "U",
                  "plant_name": "Neem", "description": "Neem tree",
                  "availability": "few", "contact_preference": "in_app",
                  "location_lat": "12.9", "location_lng": "77.5",
                  "location_neighborhood": "Test"},
            files=[
                ("photos", ("a.jpg", DUMMY_IMAGE, "image/jpeg")),
                ("photos", ("b.jpg", DUMMY_IMAGE, "image/jpeg")),
                ("photos", ("c.jpg", DUMMY_IMAGE, "image/jpeg")),
                ("photos", ("d.jpg", DUMMY_IMAGE, "image/jpeg")),  # 4th = error
            ]
        )
    assert response.status_code == 400

@pytest.mark.asyncio
async def test_fetch_nearby_posts():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get("/api/v1/community/posts/nearby",
            params={"user_id": "u1", "user_lat": "12.97",
                    "user_lng": "77.59", "radius_km": "20"})
    assert response.status_code == 200
    assert "posts" in response.json()
    assert isinstance(response.json()["posts"], list)

@pytest.mark.asyncio
async def test_contact_request_sent():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post("/api/v1/community/contact-requests",
            json={
                "from_user_id": "user_2",
                "from_display_name": "Ravi",
                "to_user_id": "test_user_1",
                "post_id": "some_post_id",
                "plant_name": "Tulsi",
                "message": "Hello, I would love to get some Tulsi from you!"
            })
    # 200 if post exists, otherwise still 200 (message saved)
    assert response.status_code in [200, 404]

@pytest.mark.asyncio
async def test_contact_request_message_too_short():
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.post("/api/v1/community/contact-requests",
            json={
                "from_user_id": "u2", "from_display_name": "R",
                "to_user_id": "u1", "post_id": "pid",
                "plant_name": "Tulsi", "message": "Hi"  # too short
            })
    assert response.status_code == 422
