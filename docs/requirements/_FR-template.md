# FR-XX: <one-line imperative title>

> **Copy this file.** Rename to `FR-XX-<slug>.md`, remove the leading
> underscore, fill in every section. Add the row to `RTM.md` in the
> same PR.

---

## Metadata

- **FR ID**: FR-XX
- **Status**: Draft / Design / Implementing / Done / Deprecated
- **GitHub Issue**: #NNN
- **Related ADRs**: ADR-NNN (optional)
- **Owner**: @github-handle
- **Created**: YYYY-MM-DD

## User story

As a **<actor>**, I want **<capability>**, so that **<outcome>**.

## Trigger

Who or what starts this? FastAPI route? Arq / Celery task? APScheduler
cron? Kafka consumer? CLI command (Typer)?

## Inputs

| Name | Python type | Validation | Source | Constraints |
|---|---|---|---|---|
| `example_id` | `UUID` | `Path(...)` | URL path param | must exist in `users` table |
| `payload` | `ExampleRequestSchema` | `Body(...)` | JSON request body | see Pydantic field constraints |

## Outputs

| Name | Python type | Consumer | Notes |
|---|---|---|---|
| `ExampleResponseSchema` | `response_model=ExampleResponseSchema` | HTTP 200 body | FastAPI returns Pydantic directly — no wrapper |

## Preconditions

What must be true **before** this runs? These become `Depends()`
factories, route-level `dependencies=[...]`, or guard clauses. Name
the code that enforces each.

- [ ] Caller is authenticated (`Depends(get_current_user)` verifies JWT)
- [ ] `example_id` exists in `users` (checked by
      `UserRepository.get_by_id`, raises `UserNotFoundException` if not)

## Postconditions

What must be true **after** this completes? These become assertions
in pytest tests.

- [ ] Response body matches `ExampleResponseSchema`
- [ ] Row inserted into `analytics_events` with
      `event_type='example_accessed'` (async session commits before return)
- [ ] Operation is **idempotent** — repeat calls with same inputs do
      not create duplicate rows

## Structured logic

Describe the flow in **structured English** — constrained grammar
(`IF … THEN … ELSE`, `FOR EACH`, `WHILE`, `RETURN`). No natural-language
ambiguity. An LLM implementing from this spec should produce one
compilable service function.

```
BEGIN FR-XX (in ExampleService.run, async, within AsyncSession context)
  VALIDATE input via Pydantic (automatic at the FastAPI layer)
  user = AWAIT userRepository.get_by_id(example_id)
  IF user IS NONE THEN
    RAISE UserNotFoundException(example_id)
  END IF
  IF user.is_blocked THEN
    RAISE ForbiddenException(reason="user blocked")
  END IF
  AWAIT analyticsEventsRepository.insert(event_type="example_accessed", user_id=user.id)
  RETURN ExampleResponseSchema.model_validate(user)
END FR-XX
```

Global exception handlers in `handlers/exception.py` convert each
`AppException` subclass to the correct HTTP status + `ErrorResponse`
payload.

## Decision table

**Only include this section if the logic has 3+ interacting conditions.**
One row per condition, one column per Rule. Y / N / — (don't care).

| Conditions                        | R1 | R2 | R3 | R4 |
|---|---|---|---|---|
| User exists                       | N  | Y  | Y  | Y  |
| User is blocked                   | —  | Y  | N  | N  |
| Premium feature requested         | —  | —  | Y  | N  |
| **Actions**                       |    |    |    |    |
| Raise `UserNotFoundException` (404) | X  |    |    |    |
| Raise `ForbiddenException` (403)  |    | X  |    |    |
| Raise `PermissionDeniedException` (403) |    |    | X  |    |
| Return `ExampleResponseSchema`    |    |    |    | X  |

**Test coverage rule**: one test per Rule column. 4 Rules = 4 tests
minimum. No Rule column may be untested.

## Exception handling

- **DB connection failure**: async session rolls back automatically;
  bubble to the global handler → 503 `SERVICE_UNAVAILABLE`
- **Pydantic validation failure**:
  `RequestValidationError` → global handler maps to `ErrorResponse`
  with HTTP 422
- **Concurrent modification**: use SQLAlchemy `with_for_update()` or
  version column; on conflict raise `ConflictException` → 409
- **External API timeout**: wrap `httpx.AsyncClient` calls with
  `timeout=` and a retry decorator (tenacity). On final failure,
  raise `AppException(status_code=503, error_code="UPSTREAM_UNAVAILABLE")`

## Test plan

| Level | Scenario | File |
|---|---|---|
| unit | happy path (pure function, mocked repo) | `tests/unit/test_example_service.py` |
| unit | each decision-table Rule (R1 … RN) | `tests/unit/test_example_service_rules.py` |
| integration | FastAPI route via `TestClient` + mocked service | `tests/integration/test_example_router.py` |
| snapshot (syrupy) | `ExampleResponseSchema` serialization shape | `tests/integration/test_example_snapshot.py` |
| architecture | Import Linter contracts (auto on `uv run lint-imports`) | `examples/.importlinter` + project's `.importlinter` |

## Open questions

<!-- Resolved questions become part of the spec above. -->

- [ ] ...
