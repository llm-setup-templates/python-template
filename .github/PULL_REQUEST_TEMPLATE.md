## Summary

<!-- 1–3 sentences. What changes and why. -->

## Related documents

<!-- Link every applicable document. Delete rows that don't apply. -->

- [ ] FR: `docs/requirements/FR-XX.md` — <!-- closes #... -->
- [ ] ADR: `docs/architecture/decisions/ADR-NNN-<slug>.md` — <!-- Accepted via this PR -->
- [ ] RFC: `docs/architecture/decisions/RFC-NNN-<slug>.md` — <!-- still Proposed, not in scope for merge -->
- [ ] Report: `docs/reports/<type>-YYYY-MM-DD-<slug>.md` — <!-- spike / benchmark / api-analysis / paar -->
- [ ] Briefing: `docs/briefings/YYYY-MM-DD-<slug>/` — <!-- event archive -->

## RTM discipline

- [ ] If this PR implements or changes an FR, `docs/requirements/RTM.md`
      is updated in this PR (new row or cell edits).

## Architecture / layer checks

<!-- Check everything that applies. Unchecked items with a comment explaining why = acceptable. -->

- [ ] Layer direction respected (`routers → services → repositories`;
      `routers` do not import `repositories` directly)
- [ ] `services/` does **not** import `sqlalchemy`, `fastapi`, or
      `httpx` — business logic stays framework-agnostic
      (`uv run lint-imports` passes)
- [ ] No `fastapi.HTTPException` raised in services / repositories —
      use `AppException` subtree from `core/exceptions.py`
- [ ] Pydantic schemas (`schemas/`) validate all inbound request bodies —
      not post-hoc `if x is None` checks
- [ ] No `print()` / `pprint()` — Loguru `logger` only
      (Ruff `T201` enforces)
- [ ] Every `__init__.py` exposes its public API via `__all__`
- [ ] `basedpyright` strict mode passes (no new `Any` / no `# type: ignore`
      without a cited reason)

## Data-flow Balancing Rule (only if DFD changed)

- [ ] No Black Hole (a process with input but no output)
- [ ] No Miracle (a process with output but no input)
- [ ] No Gray Hole (a process whose outputs cannot be derived from its
      inputs — e.g. returns data that wasn't fetched)
- [ ] Terminology is consistent between parent and child levels

## Verification

- [ ] `uv run ruff check . && uv run ruff format --check . && uv run basedpyright && uv run lint-imports && uv run pytest`
      passes locally
- [ ] Tests updated in the same commit as the code change
      (see `.claude/rules/test-modification.md`)
- [ ] No `pytest --snapshot-update` without reading the snapshot diff

## Business impact (only for large or risky changes)

<!-- Delete this section for routine changes. Required for ADR-level PRs. -->

**Cost**: <!-- managed DB tier, vendor API quota, engineer time -->
**Risk**: <!-- what can go wrong, what's the blast radius -->
**Velocity impact**: <!-- what does this enable / block for the next sprint -->
