"""Tests for schemas/error.py — Pydantic error response schemas."""

import pytest
from my_project.schemas.error import (
    ErrorResponse,
    ValidationErrorDetail,
    ValidationErrorResponse,
)


class TestErrorResponse:
    def test_required_fields(self) -> None:
        resp = ErrorResponse(error_code="not_found", message="리소스 없음")
        assert resp.error_code == "not_found"
        assert resp.message == "리소스 없음"

    def test_optional_trace_id_defaults_none(self) -> None:
        resp = ErrorResponse(error_code="err", message="msg")
        assert resp.trace_id is None

    def test_optional_details_defaults_none(self) -> None:
        resp = ErrorResponse(error_code="err", message="msg")
        assert resp.details is None

    def test_with_trace_id(self) -> None:
        resp = ErrorResponse(error_code="err", message="msg", trace_id="abc-123")
        assert resp.trace_id == "abc-123"

    def test_with_details(self) -> None:
        details: dict[str, object] = {"field": "email", "reason": "format"}
        resp = ErrorResponse(error_code="err", message="msg", details=details)
        assert resp.details == details

    def test_model_dump_keys(self) -> None:
        resp = ErrorResponse(error_code="err", message="msg")
        dumped = resp.model_dump()
        assert "error_code" in dumped
        assert "message" in dumped
        assert "trace_id" in dumped
        assert "details" in dumped

    def test_validation_requires_error_code(self) -> None:
        with pytest.raises(Exception):
            ErrorResponse(message="msg")  # type: ignore[call-arg]

    def test_validation_requires_message(self) -> None:
        with pytest.raises(Exception):
            ErrorResponse(error_code="err")  # type: ignore[call-arg]


class TestValidationErrorDetail:
    def test_fields(self) -> None:
        detail = ValidationErrorDetail(field="email", message="올바른 이메일 형식이 아닙니다", type="value_error")
        assert detail.field == "email"
        assert detail.message == "올바른 이메일 형식이 아닙니다"
        assert detail.type == "value_error"


class TestValidationErrorResponse:
    def test_default_error_code(self) -> None:
        resp = ValidationErrorResponse()
        assert resp.error_code == "validation_error"

    def test_default_message(self) -> None:
        resp = ValidationErrorResponse()
        assert resp.message == "입력값이 올바르지 않습니다"

    def test_empty_errors_by_default(self) -> None:
        resp = ValidationErrorResponse()
        assert resp.errors == []

    def test_with_errors(self) -> None:
        errors = [ValidationErrorDetail(field="name", message="필수 항목", type="missing")]
        resp = ValidationErrorResponse(errors=errors)
        assert len(resp.errors) == 1
        assert resp.errors[0].field == "name"

    def test_inherits_error_response(self) -> None:
        assert issubclass(ValidationErrorResponse, ErrorResponse)

    def test_model_dump_includes_errors(self) -> None:
        resp = ValidationErrorResponse()
        dumped = resp.model_dump()
        assert "errors" in dumped
        assert "error_code" in dumped
