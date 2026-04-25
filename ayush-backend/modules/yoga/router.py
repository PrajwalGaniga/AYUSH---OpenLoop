from fastapi import APIRouter
from fastapi.responses import HTMLResponse
from pathlib import Path
from modules.yoga.schemas import PoseCheckRequest, PoseCheckResponse, SessionCompleteRequest
from modules.yoga import service

router = APIRouter(tags=["yoga"])

# Serve the HTML pose check page
@router.get("/yoga/live/{asana_id}", response_class=HTMLResponse)
async def serve_pose_check_page(asana_id: str):
    template_path = Path("modules/yoga/templates/pose_check.html")
    html = template_path.read_text(encoding="utf-8")
    # Inject asana_id into the HTML
    html = html.replace("__ASANA_ID__", asana_id)
    return HTMLResponse(content=html)

# Pose check endpoint
@router.post("/api/v1/yoga/check-pose", response_model=PoseCheckResponse)
async def check_pose_endpoint(request: PoseCheckRequest):
    result = service.check_pose(request)
    return result

# Session complete endpoint
@router.post("/api/v1/yoga/session/complete")
async def complete_yoga_session(request: SessionCompleteRequest):
    result = await service.complete_yoga_session(request, request.user_id)
    return result

# Asana list endpoint (Flutter calls this to load the 9 asanas)
@router.get("/api/v1/yoga/asanas")
async def get_all_asanas():
    asanas = service.ASANA_DB
    return {
        "asanas": [
            {
                "id": k,
                "name_sanskrit": v["name_sanskrit"],
                "name_english": v["name_english"],
                "dosha": v["dosha"],
                "dosha_effect": v["dosha_effect"],
                "difficulty": v["difficulty"],
                "hold_seconds": v["hold_seconds"],
                "description": v["description"],
                "how_it_helps": v["how_it_helps"],
                "steps": v["steps"]
            }
            for k, v in asanas.items()
        ]
    }
