import google.generativeai as genai
from fastapi import APIRouter, HTTPException, UploadFile, File
from modules.plant.schemas import PlantQuestionRequest, PlantQuestionResponse
from modules.plant.predictor import PlantPredictor
import os

router = APIRouter(prefix="/api/v1/plant", tags=["plant"])

# Initialize Gemini specifically for the Plant module
GEMINI_API_KEY = os.getenv("PLANT_GEMINI_API_KEY")
GEMINI_MODEL_NAME = os.getenv("PLANT_GEMINI_MODEL", "gemini-2.5-flash")

if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)
    gemini_model = genai.GenerativeModel(GEMINI_MODEL_NAME)
else:
    gemini_model = None

DISCLAIMER = (
    "This information is AI-generated for educational purposes only. "
    "It is not a substitute for professional medical advice. "
    "Always consult a qualified Ayurvedic practitioner before use."
)

@router.post("/identify")
async def identify_plant(image: UploadFile = File(...)):
    if not image.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File must be an image")
    
    try:
        predictor = PlantPredictor.get_instance()
        image_bytes = await image.read()
        predictions = predictor.predict(image_bytes)
        return {"predictions": predictions}
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Prediction failed: {str(e)}")

@router.post("/ask", response_model=PlantQuestionResponse)
async def ask_plant_question(request: PlantQuestionRequest):
    if not gemini_model:
        raise HTTPException(status_code=500, detail="Plant Gemini API key not configured")
        
    if not request.user_question or len(request.user_question.strip()) < 5:
        raise HTTPException(status_code=400, detail="Question too short")

    prakriti_context = f"User's Prakriti (body constitution): {request.prakriti}" if request.prakriti else ""
    conditions_context = f"User's health conditions: {', '.join(request.conditions)}" if request.conditions else ""
    medications_context = f"Current medications: {', '.join(request.medications)}" if request.medications else ""

    prompt = f"""
You are an expert Ayurvedic physician and botanist. 
Answer the following specific question about a medicinal plant.

Plant: {request.plant_name} ({request.plant_scientific})
{prakriti_context}
{conditions_context}
{medications_context}

User's Question: {request.user_question}

Rules for your answer:
1. Answer ONLY the specific question asked — do not give a general overview
2. Ground your answer in Ayurvedic classical texts where possible (Charaka, Sushruta, Ashtanga Hridayam)
3. Be specific about dosages, methods, timing when relevant
4. Flag any safety concerns clearly
5. If the question involves drug interactions, be conservative and recommend consultation
6. Keep answer under 250 words — precise, not verbose
7. Format: plain text only, no markdown, no bullet symbols
8. End with which classical text supports this if applicable

Answer:
"""

    try:
        response = gemini_model.generate_content(prompt)
        answer_text = response.text.strip()

        # Extract any classical text references
        sources = []
        for ref in ["Charaka Samhita", "Sushruta Samhita", "Ashtanga Hridayam", 
                    "Ashtanga Sangraha", "Bhavaprakasha", "Dravyaguna"]:
            if ref.lower() in answer_text.lower():
                sources.append(ref)

        return PlantQuestionResponse(
            plant_name=request.plant_name,
            question=request.user_question,
            answer=answer_text,
            sources_mentioned=sources,
            disclaimer=DISCLAIMER,
            confidence_note="This answer is AI-generated. Always verify with a qualified practitioner."
        )

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Gemini error: {str(e)}")
