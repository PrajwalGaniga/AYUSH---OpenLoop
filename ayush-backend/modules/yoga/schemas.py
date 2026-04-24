from pydantic import BaseModel
from typing import List, Optional

class PoseCheckRequest(BaseModel):
    asana_id: str
    frame_base64: str       # base64 encoded JPEG frame from browser camera
    frame_width: int
    frame_height: int

class JointFeedback(BaseModel):
    joint_name: str
    reference_angle: float
    detected_angle: float
    deviation: float
    is_correct: bool
    correction_message: str   # empty string if correct

class PoseCheckResponse(BaseModel):
    asana_id: str
    overall_correct: bool
    accuracy_percent: float
    joint_feedbacks: List[JointFeedback]
    primary_correction: str   # the single most important correction to speak
    landmarks_visible: bool   # false if key landmarks not detected
    visibility_message: str   # "Move back so full body is visible" etc
    landmarks: Optional[List[dict]] = []  # Added for frontend skeleton rendering
