"""Smoke tests for the library archetype."""

from __future__ import annotations

import pytest
from typer.testing import CliRunner

import my_project
from my_project import cli, core
from my_project.core import process


def test_package_importable() -> None:
    """The top-level package must be importable with its version string."""
    assert my_project.__version__ == "0.1.0"


def test_cli_module_importable() -> None:
    """The cli submodule must expose the Typer app and main()."""
    assert cli is not None
    assert cli.app is not None
    assert callable(cli.main)


def test_core_module_importable() -> None:
    """The core submodule must expose process()."""
    assert core is not None
    assert callable(core.process)


def test_process_uppercases_trimmed_input() -> None:
    assert process("hello") == "HELLO"
    assert process("  mixed case  ") == "MIXED CASE"


def test_process_rejects_empty_input() -> None:
    with pytest.raises(ValueError, match="must not be empty"):
        process("")


def test_cli_app_has_run_command() -> None:
    """Typer app must register the 'run' command."""
    runner = CliRunner()
    result = runner.invoke(cli.app, ["--help"])
    assert result.exit_code == 0
    assert "run" in result.output
