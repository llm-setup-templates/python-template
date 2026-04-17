"""Standardized error response schemas."""
from pydantic import BaseModel, Field


class ErrorResponse(BaseModel):
    """Unified error response schema for all API errors.

    Attributes:
        error_code: Machine-readable error identifier (e.g. "user_not_found").
        message: Human-readable error description.
        trace_id: Optional request trace ID for correlation.
        details: Optional dict of additional context (field errors, etc.).
    """

    error_code: str = Field(..., examples=["user_not_found"])
    message: str = Field(..., examples=["사용자를 찾을 수 없습니다"])
    trace_id: str | None = None
    details: dict[str, object] | None = None


class ValidationErrorDetail(BaseModel):
    field: str
    message: str
    type: str


class ValidationErrorResponse(ErrorResponse):
    error_code: str = "validation_error"
    message: str = "입력값이 올바르지 않습니다"
    errors: list[ValidationErrorDetail] = []
