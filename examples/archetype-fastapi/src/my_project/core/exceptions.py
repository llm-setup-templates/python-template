"""Custom exception hierarchy — HTTP status-based exception classes."""
from typing import Any


class AppException(Exception):
    status_code: int = 500
    error_code: str = "internal_error"
    message: str = "알 수 없는 오류가 발생했습니다"

    def __init__(self, message: str | None = None, details: dict[str, Any] | None = None):
        self.message = message or self.__class__.message
        self.details = details
        super().__init__(self.message)


class BadRequestException(AppException):
    status_code = 400
    error_code = "bad_request"
    message = "잘못된 요청입니다"

class InvalidInputException(BadRequestException):
    error_code = "invalid_input"
    message = "입력값이 올바르지 않습니다"

class UnauthorizedException(AppException):
    status_code = 401
    error_code = "unauthorized"
    message = "인증이 필요합니다"

class InvalidCredentialsException(UnauthorizedException):
    error_code = "invalid_credentials"
    message = "이메일 또는 비밀번호가 올바르지 않습니다"

class TokenExpiredException(UnauthorizedException):
    error_code = "token_expired"
    message = "토큰이 만료되었습니다"

class ForbiddenException(AppException):
    status_code = 403
    error_code = "forbidden"
    message = "접근이 금지되었습니다"

class PermissionDeniedException(ForbiddenException):
    error_code = "permission_denied"
    message = "권한이 없습니다"

class NotFoundException(AppException):
    status_code = 404
    error_code = "not_found"
    message = "요청한 리소스를 찾을 수 없습니다"

class UserNotFoundException(NotFoundException):
    error_code = "user_not_found"
    message = "사용자를 찾을 수 없습니다"

class ConflictException(AppException):
    status_code = 409
    error_code = "conflict"
    message = "요청이 현재 상태와 충돌합니다"

class DuplicateResourceException(ConflictException):
    error_code = "duplicate_resource"
    message = "이미 존재하는 리소스입니다"

class EmailAlreadyExistsException(DuplicateResourceException):
    error_code = "email_already_exists"
    message = "이미 사용 중인 이메일입니다"
