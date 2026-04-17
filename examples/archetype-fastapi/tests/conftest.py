"""Shared pytest fixtures."""

import pytest
from fastapi.testclient import TestClient
from my_project.main import app


@pytest.fixture()
def client() -> TestClient:
    """Return a synchronous TestClient for the ASGI app."""
    return TestClient(app)
