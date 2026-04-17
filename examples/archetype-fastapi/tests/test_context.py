"""Tests for core/context.py — ContextVar-based trace ID."""

from my_project.core.context import get_trace_id, trace_id_var


class TestTraceIdVar:
    def test_default_is_none(self) -> None:
        assert get_trace_id() is None

    def test_set_and_get(self) -> None:
        token = trace_id_var.set("test-trace-123")
        try:
            assert get_trace_id() == "test-trace-123"
        finally:
            trace_id_var.reset(token)

    def test_reset_restores_default(self) -> None:
        token = trace_id_var.set("some-id")
        trace_id_var.reset(token)
        assert get_trace_id() is None

    def test_set_different_values(self) -> None:
        token1 = trace_id_var.set("first")
        assert get_trace_id() == "first"
        token2 = trace_id_var.set("second")
        assert get_trace_id() == "second"
        trace_id_var.reset(token2)
        trace_id_var.reset(token1)
