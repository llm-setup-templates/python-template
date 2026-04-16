# {{PROJECT_NAME}}

> Generated from llm-setup-prompts/python-template.

## Project Overview
Python 3.13 project template: uv + Ruff + basedpyright strict + pytest (FastAPI / Library-CLI / Data-science archetype)

## Tech Stack
- Language: Python 3.13
- Package Manager: uv
- Formatter: Ruff format
- Linter: Ruff lint
- Type Checker: basedpyright (CI strict) + ty (IDE, not in CI)
- Test Runner: pytest 9.0.3 + pytest-cov 7.1.0 + syrupy 5.1.0
- CI: GitHub Actions
- PR Review: CodeRabbit

## Primary Commands
- Install deps: `uv sync --all-extras --dev`
- Format check: `uv run ruff format .`
- Lint: `uv run ruff check .`
- Type check: `uv run basedpyright`
- Test: `uv run pytest`
- Build: `uv build`
- Full verify: `uv run ruff check . && uv run ruff format --check . && uv run basedpyright && uv run pytest`

## Architecture Summary
See `.claude/rules/architecture.md` for full rules.
src/ layout (uv init --package) with FastAPI router/service/repository layering or Library CLI (typer) or Data-science (numpy/pandas pipeline). All archetypes share the same 14-section SETUP.md; Phase 1 Archetype Switch selects the branch. Type safety enforced by basedpyright strict in CI; ty provides IDE-level hints. Ruff unifies formatting and linting. Coverage gate at 60% (initial), ramp to 80% per PR guidance.

## Verification Rules
After any code change, run the full verification loop.
Never declare a task complete until it passes.
See `.claude/rules/verification-loop.md`.

## Test Modification

When modifying code, always update tests in the same commit. Determine affected test layers:

- **Endpoint/feature added** → create unit + integration + snapshot tests
- **Signature/schema changed** → update existing assertions and fixtures
- **Logic modified** → update assertions, add edge cases
- **Dependency bumped** → review snapshot diff before `--snapshot-update`
- **Refactoring only** → do NOT touch tests; if they break, the refactoring is wrong

Snapshot rule: **never `--snapshot-update` without reading the diff first**.

Full rules and checklist: `.claude/rules/test-modification.md`

## Git Workflow
- Never commit directly to `main`
- Conventional Commits required
- See `.claude/rules/git-workflow.md`

## Business / Domain Terms
<!--
  DEFAULT: "N/A — add project-specific terms here as the codebase evolves."
  REPLACE {{DOMAIN_GLOSSARY}} with project-specific terminology, or leave
  the default string if no domain terms exist yet. Delete this section
  entirely only if the language template explicitly opts out.
-->
N/A — add project-specific terms here
