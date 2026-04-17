"""Custom exception hierarchy — HTTP status-based exception classes."""


class AppException(Exception):
    status_code: int = 500
    error_code: str = "internal_error"
    _default_message: str = "알 수 없는 오류가 발생했습니다"

    @classmethod
    def _get_default_message(cls) -> str:
        return cls._default_message

    def __init__(
        self, message: str | None = None, details: dict[str, object] | None = None
    ):
        self.message: str = message or self._get_default_message()
        self.details: dict[str, object] | None = details
        super().__init__(self.message)


class BadRequestException(AppException):
    status_code: int = 400
    error_code: str = "bad_request"
    _default_message: str = "잘못된 요청입니다"


class InvalidInputException(BadRequestException):
    error_code: str = "invalid_input"
    _default_message: str = "입력값이 올바르지 않습니다"


class UnauthorizedException(AppException):
    status_code: int = 401
    error_code: str = "unauthorized"
    _default_message: str = "인증이 필요합니다"


class InvalidCredentialsException(UnauthorizedException):
    error_code: str = "invalid_credentials"
    _default_message: str = "이메일 또는 비밀번호가 올바르지 않습니다"


class TokenExpiredException(UnauthorizedException):
    error_code: str = "token_expired"
    _default_message: str = "토큰이 만료되었습니다"


class ForbiddenException(AppException):
    status_code: int = 403
    error_code: str = "forbidden"
    _default_message: str = "접근이 금지되었습니다"


class PermissionDeniedException(ForbiddenException):
    error_code: str = "permission_denied"
    _default_message: str = "권한이 없습니다"


class NotFoundException(AppException):
    status_code: int = 404
    error_code: str = "not_found"
    _default_message: str = "요청한 리소스를 찾을 수 없습니다"


class UserNotFoundException(NotFoundException):
    error_code: str = "user_not_found"
    _default_message: str = "사용자를 찾을 수 없습니다"


class ConflictException(AppException):
    status_code: int = 409
    error_code: str = "conflict"
    _default_message: str = "요청이 현재 상태와 충돌합니다"


class DuplicateResourceException(ConflictException):
    error_code: str = "duplicate_resource"
    _default_message: str = "이미 존재하는 리소스입니다"


class EmailAlreadyExistsException(DuplicateResourceException):
    error_code: str = "email_already_exists"
    _default_message: str = "이미 사용 중인 이메일입니다"
