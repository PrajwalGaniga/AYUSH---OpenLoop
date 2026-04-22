import base64
import json
import re
from utils.gemini_client import get_gemini_model

EXTRACTION_PROMPT = """
You are a medical data extraction system. From this document extract all health data.
Return ONLY valid JSON with exactly this structure (no markdown, no extra text):
{
  "conditions": ["string"],
  "medications": [{"name": "string", "dosage": "string", "frequency": "string"}],
  "labValues": [{"test": "string", "value": "string", "unit": "string", "referenceRange": "string", "status": "normal|low|high"}],
  "vitalSigns": {"bloodPressure": "string", "heartRate": "string", "temperature": "string", "weight": "string", "height": "string"},
  "doctorNotes": "string",
  "reportDate": "string"
}
If any field is absent, use empty array [] or null. Do not hallucinate values.
"""

EMPTY_RESULT = {
    "conditions": [],
    "medications": [],
    "labValues": [],
    "vitalSigns": {},
    "doctorNotes": None,
    "reportDate": None,
}


async def extract_medical_report(file_bytes: bytes, mime_type: str) -> dict:
    """
    Sends a medical report (PDF or image) to Gemini 2.5 Flash for structured extraction.
    Returns a validated dict or an empty result with an extractionError field on failure.
    """
    try:
        model = get_gemini_model()

        part = {
            "inline_data": {
                "mime_type": mime_type,
                "data": base64.b64encode(file_bytes).decode(),
            }
        }

        response = model.generate_content([EXTRACTION_PROMPT, part])

        # Strip markdown code fences if Gemini wraps in ```json ... ```
        raw = response.text.strip()
        raw = re.sub(r"^```json\s*", "", raw)
        raw = re.sub(r"\s*```$", "", raw)

        extracted = json.loads(raw)
        return extracted

    except json.JSONDecodeError:
        # Never crash — return empty result with user-facing error note
        result = EMPTY_RESULT.copy()
        result["extractionError"] = (
            "Could not fully parse the report. Please review and add details manually."
        )
        return result

    except Exception as e:
        result = EMPTY_RESULT.copy()
        result["extractionError"] = (
            f"AI extraction failed: {str(e)}. Please try again or enter details manually."
        )
        return result
