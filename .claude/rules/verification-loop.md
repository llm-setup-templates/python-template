# Verification Loop Rules

## The Loop
After any code change, the agent MUST run the verification loop:

```
uv run ruff format --check .                                 → format check
uv run basedpyright                                          → type check
# no separate static analysis step — Ruff handles E/F/B/S/UP rules inline
uv run ruff check .                                          → lint
uv run pytest                                                → tests (--cov-fail-under=60 via pyproject.toml)
uv build                                                     → build
```

> Python 템플릿은 `{{OVERRIDE_STATIC_ANALYSIS_COMMANDS}}` 슬롯을 주석으로 치환한다. Ruff가 lint + format을 통합 처리하므로 별도 단계가 불필요.
> 각 슬롯은 단일 명령을 수용하며, 실패 시 즉시 중단(fail-fast)한다.

Execution order is fail-fast: stop at the first failure.

If the **test** step fails, consult `.claude/rules/test-modification.md` to determine
which tests need updating based on the code change type, then re-run the loop.

## Agent Self-Verification Rules
1. Never declare a task complete until the full loop passes.
2. If a step fails, fix the root cause — do not bypass with `--no-verify`, `# type: ignore` (except with a cited reason), or skipping tests.
3. After 3 consecutive failed attempts on the same step, escalate to the human instead of trying more aggressive fixes.
4. If the loop command itself is broken (infrastructure issue), report the infrastructure problem before attempting code fixes.

## CI Parity
The local verification loop MUST match the CI workflow exactly. Any divergence is a bug in one of them and must be resolved. `basedpyright` is the single source of truth for type checking in CI; `ty` is IDE-only and never runs in CI.
