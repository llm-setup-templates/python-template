"""ASGI application entry point."""

from fastapi import FastAPI
from pydantic import BaseModel

from my_project.handlers.exception import register_exception_handlers

app = FastAPI(title="my_project", version="0.1.0")
register_exception_handlers(app)


class HealthResponse(BaseModel):
    status: str
    version: str


@app.get("/health", response_model=HealthResponse)
async def health_check() -> HealthResponse:
    """Return service health status."""
    return HealthResponse(status="ok", version="0.1.0")


def main() -> None:
    """CLI entry point for uvicorn."""
    import uvicorn

    uvicorn.run(
        "my_project.main:app",
        host="0.0.0.0",  # noqa: S104
        port=8000,
        reload=False,
    )
