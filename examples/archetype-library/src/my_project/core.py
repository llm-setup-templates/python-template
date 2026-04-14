"""Core library logic."""


def process(data: str) -> str:
    """Process input data and return result."""
    if not data:
        raise ValueError("data must not be empty")
    return data.strip().upper()
