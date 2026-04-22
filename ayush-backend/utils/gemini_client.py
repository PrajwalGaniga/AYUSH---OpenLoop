import google.generativeai as genai
from config.settings import settings

# Configure Gemini with API key from environment — NEVER hardcode
genai.configure(api_key=settings.gemini_api_key)


def get_gemini_model():
    """Returns a configured Gemini generative model instance."""
    return genai.GenerativeModel(
        model_name=settings.gemini_model,
        system_instruction=(
            "You are AYUSH, an AI integrated into an Ayurvedic health platform. "
            "Always respond with medically cautious language, include disclaimers where appropriate, "
            "and return structured JSON unless instructed otherwise."
        ),
    )
