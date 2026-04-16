"""ContextVar-based request context — Trace ID.

NOTE: trace_id is set by request middleware.
Before middleware is configured, get_trace_id() always returns None.
Add a middleware that sets trace_id_var per request (e.g., in middleware/logging.py).
"""
from contextvars import ContextVar

trace_id_var: ContextVar[str | None] = ContextVar("trace_id", default=None)

def get_trace_id() -> str | None:
    return trace_id_var.get()
