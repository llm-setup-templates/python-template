"""Global exception handlers — convert all exceptions to ErrorResponse."""
from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from loguru import logger
from starlette.exceptions import HTTPException as StarletteHTTPException

from my_project.core.context import get_trace_id
from my_project.core.exceptions import AppException
from my_project.schemas.error import ErrorResponse, ValidationErrorDetail, ValidationErrorResponse


def register_exception_handlers(app: FastAPI) -> None:
    @app.exception_handler(AppException)
    async def app_exception_handler(request: Request, exc: AppException) -> JSONResponse:
        trace_id = get_trace_id()
        logger.bind(trace_id=trace_id, error_code=exc.error_code,
            path=request.url.path, method=request.method).warning(f"AppException: {exc.message}")
        return JSONResponse(status_code=exc.status_code,
            content=ErrorResponse(error_code=exc.error_code, message=exc.message,
                trace_id=trace_id, details=exc.details).model_dump())

    @app.exception_handler(RequestValidationError)
    async def validation_exception_handler(request: Request, exc: RequestValidationError) -> JSONResponse:
        trace_id = get_trace_id()
        errors = [ValidationErrorDetail(field=".".join(str(loc) for loc in e["loc"][1:]) or "body",
            message=e["msg"], type=e["type"]) for e in exc.errors()]
        return JSONResponse(status_code=422,
            content=ValidationErrorResponse(trace_id=trace_id, errors=errors).model_dump())

    @app.exception_handler(StarletteHTTPException)
    async def http_exception_handler(request: Request, exc: StarletteHTTPException) -> JSONResponse:
        trace_id = get_trace_id()
        return JSONResponse(status_code=exc.status_code,
            content=ErrorResponse(error_code="http_error", message=str(exc.detail), trace_id=trace_id).model_dump())

    @app.exception_handler(Exception)
    async def unhandled_exception_handler(request: Request, exc: Exception) -> JSONResponse:
        trace_id = get_trace_id()
        logger.bind(trace_id=trace_id, path=request.url.path).exception("Unhandled exception")
        return JSONResponse(status_code=500,
            content=ErrorResponse(error_code="internal_server_error",
                message="서버 오류가 발생했습니다", trace_id=trace_id).model_dump())
