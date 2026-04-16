# Architecture Rules — Python

## Required Content per Language Template

Each derived `architecture.md` MUST specify:
1. **Directory layout** — top-level folders and their responsibilities
2. **Module boundaries** — what can import what (import direction)
3. **Public API surface** — how modules expose symbols
   - Python: `__init__.py` public API + `__all__`
4. **Circular dependency policy** — absolute prohibition
5. **Cross-layer access rules** — which layers may talk to which

## Python Module Export Rules

### Directory Layout (src/ layout enforced by `uv init --package`)
```
src/my_project/
├── __init__.py
├── main.py              ← FastAPI app + lifespan + middleware + handler registration
├── core/                ← settings, DB, exception hierarchy, logging, security
│   ├── __init__.py
│   ├── config.py        ← pydantic-settings based env config
│   ├── database.py      ← AsyncSession factory
│   ├── exceptions.py    ← AppException + HTTP status subclass hierarchy
│   ├── logging.py       ← Loguru setup (env-aware JSON/console)
│   └── context.py       ← ContextVar (trace_id, user_id)
├── handlers/            ← Global exception handlers (4 types)
│   └── exception.py
├── dependencies/        ← FastAPI Depends factories
├── middleware/           ← CORS, timing, logging, gzip
├── routers/             ← HTTP handlers (no business logic)
├── schemas/             ← Pydantic DTOs + ErrorResponse
│   └── error.py
├── services/            ← Business logic
├── repositories/        ← DB access layer
└── models/              ← SQLModel entities
```

### Public API (`__init__.py`)
- Every `__init__.py` MUST define `__all__` listing exported symbols
- Internal modules (prefixed `_`) MUST NOT appear in `__all__`
- External callers import only from `my_project` (top-level), never from `my_project.internal`

### Import Direction (layering — FastAPI archetype)
```
routers → services → repositories  (existing, maintained)
         ↘ schemas (shared DTOs)
core ← (importable by all layers)
handlers ← core.exceptions
dependencies ← core, services

FORBIDDEN:
- services → sqlalchemy, fastapi (business logic must be framework-agnostic)
- routers → repositories (must go through services)
- schemas → repositories, routers
- models → routers, services
```

### Data-science archetype layout
```
src/my_project/
├── __init__.py
└── pipeline.py      ← processing class, numpy/pandas types
tests/regression/    ← floating-point regression tests (no syrupy)
```

## [CRITICAL] AI Agent Architectural Constraints — Python / FastAPI

### 1. Response Pattern (FastAPI standard — different from Spring!)
- Success: `response_model=UserRead` returns Pydantic schema **directly** — no wrapper needed.
- Error: `ErrorResponse` schema (error_code, message, trace_id, details) unified via global handlers.
- NEVER return raw `dict` from route handlers.

### 2. Exception Pattern (HTTP status-based class hierarchy)
- NEVER raise `fastapi.HTTPException` in service/repository layers.
- Use custom exceptions from `core/exceptions.py`:
  - `AppException` (base, 500) → `BadRequestException` (400) → `InvalidInputException`
  - `UnauthorizedException` (401) → `InvalidCredentialsException`, `TokenExpiredException`
  - `ForbiddenException` (403) → `PermissionDeniedException`
  - `NotFoundException` (404) → `UserNotFoundException`
  - `ConflictException` (409) → `DuplicateResourceException` → `EmailAlreadyExistsException`
- 4 global handlers: AppException / RequestValidationError / StarletteHTTPException / unhandled

### 3. Layer Dependency Isolation
- `services/` MUST NOT import `sqlalchemy`, `fastapi`, `httpx`.
- Import Linter contracts (see `examples/.importlinter`) define these boundaries.

### 4. Observability Isolation
- `print()` and `pprint()` are banned (Ruff T201).
- Use Loguru: `from loguru import logger`. Initialization only in `core/logging.py`.

### 5. Required Execution Sequence
1. IDENTIFY: router? service? repository? core? handler?
2. SEARCH: `grep -r "similar pattern" src/`
3. VERIFY: `uv run lint-imports` (when configured)
4. PUBLIC API: `from my_project.core.exceptions import NotFoundException`

## Universal Principles
- Dependency direction: outer layers may depend on inner layers, never reverse
- Public API minimization: expose the smallest surface that callers need
- No "util dump" packages — every file has a single responsibility
