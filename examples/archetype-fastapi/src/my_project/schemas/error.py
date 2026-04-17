"""Standardized error response schemas."""
from pydantic import BaseModel, Field


class ErrorResponse(BaseModel):
    error_code: str = Field(..., examples=["user_not_found"])
    message: str = Field(..., examples=["사용자를 찾을 수 없습니다"])
    trace_id: str | None = Field(None, description="Request trace ID")
    details: dict[str, object] | None = Field(None, description="Additional details")


class ValidationErrorDetail(BaseModel):
    field: str
    message: str
    type: str


class ValidationErrorResponse(ErrorResponse):
    error_code: str = "validation_error"
    message: str = "입력값이 올바르지 않습니다"
    errors: list[ValidationErrorDetail] = []
