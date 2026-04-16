# Test Modification Rules

## When to modify tests

Every code change MUST be accompanied by corresponding test changes.
Use this table to determine which test layers are affected:

| Code Change Type | Affected Test Layer | Required Action |
|-----------------|--------------------|-----------------| 
| API endpoint added | unit + integration + snapshot | Create new test file(s), run `--snapshot-update` |
| Function signature changed | unit (direct) + integration (indirect) | Update existing assertions and fixtures |
| DB schema changed | integration | Update fixtures/factories, add migration test |
| Business logic modified | unit + property (if exists) | Update assertions, add edge case tests |
| Dependency version bumped | snapshot (may break) | Review diff → intentional = `--update`; unexpected = fix code |
| Config / env var changed | integration + smoke | Update environment fixtures |
| **Refactoring (behavior unchanged)** | **none** | **Do NOT modify tests — if they break, the refactoring is wrong** |

## Test modification checklist (5 steps)

For every code change, follow this sequence:

1. **Identify affected layers** — Use the mapping table above. If unsure, err on the side of more layers.
2. **Run existing tests first** — `uv run pytest` before any test changes. This establishes which tests break from your code change vs. which were already broken.
3. **Modify tests to match new behavior** — Update assertions, fixtures, mocks. Add new test files for new functionality. Follow the AAA pattern (Arrange-Act-Assert).
4. **Run verification loop** — Full `ruff check` + `basedpyright` + `pytest` pass required.
5. **Review test diff** — `git diff tests/` must make sense relative to the code change. If the test diff is larger than the code diff, reconsider your approach.

## Snapshot management (syrupy)

**NEVER run `--snapshot-update` blindly.**

When a snapshot test fails:

```
1. Read the failure diff carefully
2. Ask: "Is this change intentional — did I deliberately change the output?"
   → YES: run `uv run pytest --snapshot-update`, then `git diff` the .ambr files
   → NO:  the code change introduced a bug — fix the code, not the snapshot
3. After --snapshot-update, review the git diff of snapshot files
   → If the diff looks wrong, revert and fix the code instead
```

## Prohibitions

- **No `--snapshot-update` without reading the diff first**
- **No deleting tests to make CI green** — fix the code or update the test correctly
- **No `# type: ignore` / `noqa` to suppress test failures** — these mask real bugs
- **No skipping tests** (`@pytest.mark.skip`) without a documented reason and issue link
- **Refactoring PRs must not change test assertions** — if a test breaks during refactoring, the refactoring changed behavior

## New feature test requirements

When adding a new feature (endpoint, service, utility):

- **Minimum**: 1 unit test covering the happy path + 1 edge case
- **Recommended**: integration test if the feature touches I/O (DB, HTTP, filesystem)
- **Snapshot**: if the feature produces structured output (API response, serialized data), add a snapshot test
- Follow existing test file naming: `tests/unit/test_{module}.py`, `tests/integration/test_{module}.py`
