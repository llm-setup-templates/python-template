"""Tests for core/exceptions.py — AppException hierarchy."""

import pytest
from my_project.core.exceptions import (
    AppException,
    BadRequestException,
    ConflictException,
    DuplicateResourceException,
    EmailAlreadyExistsException,
    ForbiddenException,
    InvalidCredentialsException,
    InvalidInputException,
    NotFoundException,
    PermissionDeniedException,
    TokenExpiredException,
    UnauthorizedException,
    UserNotFoundException,
)


class TestAppException:
    def test_default_attributes(self) -> None:
        exc = AppException()
        assert exc.status_code == 500
        assert exc.error_code == "internal_error"
        assert exc.message == "알 수 없는 오류가 발생했습니다"
        assert exc.details is None

    def test_custom_message(self) -> None:
        exc = AppException(message="custom error")
        assert exc.message == "custom error"

    def test_custom_details(self) -> None:
        details: dict[str, object] = {"field": "value"}
        exc = AppException(details=details)
        assert exc.details == details

    def test_is_exception(self) -> None:
        with pytest.raises(AppException):
            raise AppException("test")


class TestBadRequestException:
    def test_status_code(self) -> None:
        exc = BadRequestException()
        assert exc.status_code == 400

    def test_error_code(self) -> None:
        exc = BadRequestException()
        assert exc.error_code == "bad_request"

    def test_message(self) -> None:
        exc = BadRequestException()
        assert exc.message == "잘못된 요청입니다"

    def test_inherits_from_app_exception(self) -> None:
        assert issubclass(BadRequestException, AppException)


class TestInvalidInputException:
    def test_error_code(self) -> None:
        exc = InvalidInputException()
        assert exc.error_code == "invalid_input"

    def test_inherits_from_bad_request(self) -> None:
        assert issubclass(InvalidInputException, BadRequestException)
        exc = InvalidInputException()
        assert exc.status_code == 400


class TestUnauthorizedException:
    def test_status_code(self) -> None:
        exc = UnauthorizedException()
        assert exc.status_code == 401

    def test_error_code(self) -> None:
        exc = UnauthorizedException()
        assert exc.error_code == "unauthorized"


class TestInvalidCredentialsException:
    def test_error_code(self) -> None:
        exc = InvalidCredentialsException()
        assert exc.error_code == "invalid_credentials"

    def test_inherits_unauthorized(self) -> None:
        exc = InvalidCredentialsException()
        assert exc.status_code == 401


class TestTokenExpiredException:
    def test_error_code(self) -> None:
        exc = TokenExpiredException()
        assert exc.error_code == "token_expired"

    def test_status_code_inherited(self) -> None:
        exc = TokenExpiredException()
        assert exc.status_code == 401


class TestForbiddenException:
    def test_status_code(self) -> None:
        exc = ForbiddenException()
        assert exc.status_code == 403

    def test_error_code(self) -> None:
        exc = ForbiddenException()
        assert exc.error_code == "forbidden"


class TestPermissionDeniedException:
    def test_error_code(self) -> None:
        exc = PermissionDeniedException()
        assert exc.error_code == "permission_denied"

    def test_status_code_inherited(self) -> None:
        exc = PermissionDeniedException()
        assert exc.status_code == 403


class TestNotFoundException:
    def test_status_code(self) -> None:
        exc = NotFoundException()
        assert exc.status_code == 404

    def test_error_code(self) -> None:
        exc = NotFoundException()
        assert exc.error_code == "not_found"


class TestUserNotFoundException:
    def test_error_code(self) -> None:
        exc = UserNotFoundException()
        assert exc.error_code == "user_not_found"

    def test_inherits_not_found(self) -> None:
        exc = UserNotFoundException()
        assert exc.status_code == 404


class TestConflictException:
    def test_status_code(self) -> None:
        exc = ConflictException()
        assert exc.status_code == 409

    def test_error_code(self) -> None:
        exc = ConflictException()
        assert exc.error_code == "conflict"


class TestDuplicateResourceException:
    def test_error_code(self) -> None:
        exc = DuplicateResourceException()
        assert exc.error_code == "duplicate_resource"

    def test_status_code_inherited(self) -> None:
        exc = DuplicateResourceException()
        assert exc.status_code == 409


class TestEmailAlreadyExistsException:
    def test_error_code(self) -> None:
        exc = EmailAlreadyExistsException()
        assert exc.error_code == "email_already_exists"

    def test_full_chain(self) -> None:
        exc = EmailAlreadyExistsException()
        assert isinstance(exc, DuplicateResourceException)
        assert isinstance(exc, ConflictException)
        assert isinstance(exc, AppException)
        assert exc.status_code == 409
