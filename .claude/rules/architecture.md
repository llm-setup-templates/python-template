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
src/
└── my_project/
    ├── __init__.py      ← public API surface (define __all__)
    ├── main.py          ← FastAPI ASGI app entry point
    ├── router/          ← FastAPI route handlers (no business logic)
    ├── service/         ← business logic (no DB calls)
    └── repository/      ← DB access layer only
tests/
└── my_project/
    ├── conftest.py
    └── test_*.py
```

### Public API (`__init__.py`)
- Every `__init__.py` MUST define `__all__` listing exported symbols
- Internal modules (prefixed `_`) MUST NOT appear in `__all__`
- External callers import only from `my_project` (top-level), never from `my_project.internal`

### Import Direction (layering — FastAPI archetype)
```
router → service → repository
       ↘ (shared domain types only)
```
- `router` MAY import `service`, MUST NOT import `repository` directly
- `service` MAY import `repository`, MUST NOT import `router`
- Circular imports are a hard error (Ruff RUF rules)

### Data-science archetype layout
```
src/my_project/
├── __init__.py
└── pipeline.py      ← processing class, numpy/pandas types
tests/regression/    ← floating-point regression tests (no syrupy)
```

## Universal Principles
- Dependency direction: outer layers may depend on inner layers, never reverse
- Public API minimization: expose the smallest surface that callers need
- No "util dump" packages — every file has a single responsibility
