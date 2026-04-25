from pydantic_settings import BaseSettings
from typing import List


class Settings(BaseSettings):
    gemini_api_key: str
    gemini_model: str = "gemini-2.5-flash"
    mongodb_url: str = "mongodb://localhost:27017"
    mongodb_db_name: str = "ayush_db"
    jwt_secret: str = "ayush_super_secret_key_change_in_prod_2024"
    jwt_expire_hours: int = 8760  # 1 year — "remember forever" per spec
    app_env: str = "development"
    cors_origins: str = '["*"]'
    module_3_api_key: str
    youtube_api_key: str
    plant_gemini_api_key: str = ""
    plant_gemini_model: str = "gemini-2.5-flash"
    ngrok_url: str = "http://localhost:8000"  # Used for community photo URLs on device
    twilio_account_sid: str = ""
    twilio_auth_token: str = ""
    twilio_from_number: str = "+18146373200"

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


settings = Settings()
