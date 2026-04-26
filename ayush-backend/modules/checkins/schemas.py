from pydantic import BaseModel, Field

class CheckinRequest(BaseModel):
    user_id: str = Field(..., description="The ID of the user")
    sleep_quality: float = Field(..., description="Slider value 0-10", ge=0, le=10)
    stress_level: float = Field(..., description="Slider value 0-10", ge=0, le=10)
    energy_level: float = Field(..., description="Slider value 0-10", ge=0, le=10)

class CheckinResponse(BaseModel):
    status: str
    message: str
