"""
AYUSH FastAPI Backend — Entry Point
"""
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from database.mongodb import connect_db, close_db
from modules.onboarding.router import router as onboarding_router
from modules.food.router import router as food_router
from modules.recipe.router import router as recipe_router
from modules.yoga.router import router as yoga_router
from modules.plant.router import router as plant_router
from modules.community.router import router as community_router
from modules.sos.router import router as sos_router
from config.settings import settings
from pathlib import Path
from fastapi.staticfiles import StaticFiles
from database.mongodb import get_db


@asynccontextmanager
async def lifespan(app: FastAPI):
    await connect_db()
    
    # Community module startup
    Path("uploads/community").mkdir(parents=True, exist_ok=True)
    db = get_db()
    plant_posts_collection = db["plant_posts"]
    contact_requests_collection = db["contact_requests"]
    
    await plant_posts_collection.create_index([("status", 1), ("created_at", -1)])
    await plant_posts_collection.create_index([("user_id", 1)])
    await plant_posts_collection.create_index([("plant_name", "text")])
    await plant_posts_collection.create_index([("location.geohash", 1)])
    await contact_requests_collection.create_index([("to_user_id", 1), ("status", 1)])
    await contact_requests_collection.create_index([("from_user_id", 1)])
    
    yield
    await close_db()


app = FastAPI(
    title="AYUSH API",
    description="AI-Powered Ayurvedic Healthcare Platform — Module 1",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Restrict in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Onboarding + Auth routes
app.include_router(onboarding_router, prefix="/api/v1", tags=["Auth + Onboarding"])

# Food scan & analysis routes
app.include_router(food_router, prefix="/api/v1")

# Recipe generation routes
app.include_router(recipe_router, prefix="/api/v1")

# Yoga Posture Analyzer routes
app.include_router(yoga_router)

# Plant Identifier routes
app.include_router(plant_router)

# Community module routes
app.include_router(community_router)

# SOS / Fall Detection routes
app.include_router(sos_router)

# Mount static files for uploads
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")


@app.get("/health", tags=["System"])
async def health():
    return {
        "status": "ok",
        "service": "AYUSH API",
        "version": "1.0.0",
        "env": settings.app_env,
    }
