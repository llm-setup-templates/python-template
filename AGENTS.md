# {{REPO_NAME}}

> Generated from llm-setup-templates/python-template.
> Canonical rules body for all agents (Claude Code loads this via CLAUDE.md imports; Codex CLI loads it directly).

## 1. Project Overview
Python 3.13 project template: uv + Ruff + basedpyright strict + pytest (FastAPI / Library-CLI / Data-science archetype)

## 2. Tech Stack
- Language: Python 3.13
- Package Manager: uv
- Formatter: Ruff format
- Linter: Ruff lint
- Type Checker: basedpyright (CI strict) + ty (IDE, not in CI)
- Test Runner: pytest 9.0.3 + pytest-cov 7.1.0 + syrupy 5.1.0
- CI: GitHub Actions
- PR Review: CodeRabbit

## 3. Primary Commands
- Install deps: `uv sync --all-extras --dev`
- Format check: `uv run ruff format --check .`
- Lint: `uv run ruff check .`
- Type check: `uv run basedpyright`
- Architecture check: `uv run lint-imports`
- Test: `uv run pytest`
- Build: `uv build`
- Full verify: `uv run ruff check . && uv run ruff format --check . && uv run basedpyright && uv run lint-imports && uv run pytest`

## 4. Architecture Summary
See `.agents/rules/architecture.md` for full rules.
src/ layout (uv init --package). The rules below describe the **FastAPI archetype**; the library and data-science archetypes use a simpler flat package layout without the router/service/exception stack. FastAPI archetype: `routers/ → services/ → repositories/` with `core/` providing HTTP status-based exception hierarchy (`AppException` → `NotFoundException` → `UserNotFoundException`), Loguru structured logging (JSON/console by environment), and ContextVar-based trace ID. Error responses unified via `ErrorResponse` schema + 4 global exception handlers (`handlers/exception.py`). Success responses use `response_model=Schema` directly (FastAPI standard — no wrapper). Import boundaries in `.agents/rules/architecture.md`; enforcement via Import Linter (`.importlinter` at the project root). Type safety: basedpyright strict (CI). Ruff formatting + linting. Coverage gate 60%.

## 5. Requirements traceability (RTM)

Every functional requirement gets an ID and a row in `docs/requirements/RTM.md`.

- ID formats: `FR-{DOMAIN}-{NNN}` for functional, `NFR-{CATEGORY}-{NNN}` for
  non-functional, `TC-{DOMAIN}-{NNN}` for test cases (all three digits,
  zero-padded). `ORDER` in examples is a placeholder — define your domain
  prefixes in the table at the top of RTM.md. Never reuse a retired number;
  set Status to `Deprecated` instead of deleting the row.
- When a PR implements or changes an FR, update its RTM row **in the same PR**.
  The row links the FR to its issue, ADRs, operationId, component paths,
  and tests (`TC-...` plus the test file path).
- Row completeness follows Status: `Draft`/`Design` rows need only ID, Summary,
  and Status; `Done` rows must list at least one existing component path and
  one existing test path. Any path you do write must exist (except on
  `Deprecated` rows, which keep their historical paths after code removal).
- The `V_rtm` section of `validate.sh` checks ID format, duplicates, the
  status gate above, and that referenced paths exist. If you don't use the
  RTM, the check stays silent; to drop it entirely, delete the `V_rtm`
  section in validate.sh (one block, marked by its header comment).
- Full rules: `.agents/rules/documentation.md`.

## 6. Verification Rules
After any code change, run the full verification loop.
Never declare a task complete until it passes.
See `.agents/rules/verification-loop.md`.

## 7. Test Modification

When modifying code, always update tests in the same commit. Determine affected test layers:

- **Endpoint/feature added** → create unit + integration + snapshot tests
- **Signature/schema changed** → update existing assertions and fixtures
- **Logic modified** → update assertions, add edge cases
- **Dependency bumped** → review snapshot diff before `--snapshot-update`
- **Refactoring only** → do NOT touch tests; if they break, the refactoring is wrong

Snapshot rule: **never `--snapshot-update` without reading the diff first**.

Full rules and checklist: `.agents/rules/test-modification.md`

## 8. Git Workflow
- Never commit directly to `main`
- Conventional Commits required
- See `.agents/rules/git-workflow.md`

## 9. Business / Domain Terms
<!--
  DEFAULT: "N/A — add project-specific terms here as the codebase evolves."
  REPLACE {{DOMAIN_GLOSSARY}} with project-specific terminology, or leave
  the default string if no domain terms exist yet. Delete this section
  entirely only if the language template explicitly opts out.
-->
N/A — add project-specific terms here
