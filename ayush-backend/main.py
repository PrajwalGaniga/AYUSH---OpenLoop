"""
AYUSH FastAPI Backend — Entry Point
"""
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from database.mongodb import connect_db, close_db
from modules.onboarding.router import router as onboarding_router
from config.settings import settings


@asynccontextmanager
async def lifespan(app: FastAPI):
    await connect_db()
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

# Mount all routes — auth lives under same router for simplicity
app.include_router(onboarding_router, prefix="/api/v1", tags=["Auth + Onboarding"])


@app.get("/health", tags=["System"])
async def health():
    return {
        "status": "ok",
        "service": "AYUSH API",
        "version": "1.0.0",
        "env": settings.app_env,
    }
