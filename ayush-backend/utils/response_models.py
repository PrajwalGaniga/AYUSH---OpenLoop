from pydantic import BaseModel
from typing import Any, Optional


class ApiResponse(BaseModel):
    success: bool
    message: str
    data: Optional[Any] = None


class ErrorResponse(BaseModel):
    success: bool = False
    message: str
    error_code: Optional[str] = None


def success_response(data: Any = None, message: str = "Success") -> dict:
    return {"success": True, "message": message, "data": data}


def error_response(message: str, error_code: str = None) -> dict:
    return {"success": False, "message": message, "error_code": error_code}
