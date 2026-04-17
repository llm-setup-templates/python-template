# Data Dictionary

> Extended Data Dictionary — every named data element in the system
> linked to the **live Pydantic schema or SQLAlchemy model** that
> defines it. The code is the source of truth; this file is the
> index into the code.

## How this file is structured

Each row points to a Pydantic schema (`schemas/`) for inbound /
outbound shapes, or to a SQLAlchemy model (`models/`) for persisted
shapes. The model or schema is authoritative for the type, constraints,
and defaults via field annotations (`Field(...)`, `Annotated[...,
Field(...)]`, `@field_validator`, or SQLAlchemy `Mapped[...]` +
`Column(...)` metadata). This file adds the **business-level** context
(ownership, policy, rationale) that doesn't belong in the code.

**Never duplicate field definitions here.** If a reader needs the
exact type or regex, they follow the link. Duplication is what makes
data dictionaries rot.

## Data elements

| Element | Source of truth | DFD flow | Owner | Policy notes |
|---|---|---|---|---|
| `User` (wire) | `schemas/user.py` § `UserRead` | EXT-01 → 1.0 | auth-team | PII — never logged; `EmailStr`, `min_length=1` |
| `User` (persisted) | `models/user.py` § `User(Base)` | D1 | auth-team | `email` unique index, soft-delete via `deleted_at` |
| `Session` | `models/session.py` § `Session(Base)` | 1.0 → D1 | auth-team | 24h TTL; cleanup by scheduled worker |
| `Article` | `schemas/article.py` § `ArticleRead` | EXT-02 → 2.0 | content-team | cached 1h via `@cached` on service method |

## Notation carry-over from structured analysis

The 1978 DeMarco notation (`= + [ | ] { } ( ) ** **`) isn't used
directly — Pydantic / SQLAlchemy express all of it more clearly:

| DeMarco | Pydantic / SQLAlchemy equivalent |
|---|---|
| `=` definition | `class X(BaseModel): ...` or `class X(Base): __tablename__ = ...` |
| `+` composition | fields of the model |
| `[ a \| b ]` selection | `Literal["a", "b"]` or `enum.Enum` subclass |
| `{ a }` iteration | `list[A]` with `Field(..., min_length=0)` |
| `(a)` optional | `Optional[A]` / `A \| None` — default `None` |
| `** comment **` | `Field(..., description="...")` or docstring |

Business rules that annotations can't express (e.g. "balance must
equal sum of transactions") belong as `@model_validator(mode="after")`
on Pydantic models or as SQLAlchemy `@validates(...)` decorators.
Reference the rule from this file with a one-line note.

## Cross-cutting policies

Not every field needs a table row — but policies that apply across
many fields do:

- **Timestamps**: every persisted row has `created_at` / `updated_at`
  columns with `server_default=func.now()` and `onupdate=func.now()`.
  UTC only; never trust client-supplied timestamps
- **IDs**: primary keys are `UUID` (`uuid4()`) unless an ADR
  documents an exception. Do not expose internal integer IDs in API
  responses
- **Currency**: store as `Decimal` with fixed precision + scale
  (`Numeric(19, 4)`); never `Float`. Format at the API boundary, not
  in domain models
- **Email**: store normalized lowercase (strip + `.lower()` on write
  via Pydantic `@field_validator`); unique index in DB
- **Enums**: Python `enum.Enum` subclass persisted as strings
  (`sqlalchemy.Enum(MyEnum, name="my_enum")`) — never raw ints,
  which break when a new value is inserted

## When to add a row

- A new domain-level entity appears in the system
- A field's **policy** changes (even if the Python type doesn't)
- A field crosses a trust boundary (PII, payment, auth token) and
  needs handling rules documented

## When NOT to add a row

- Every internal helper Pydantic model — those are local to a router
  or service
- Repository internal column detail (`version`, `deleted_at`, etc.)
  covered by cross-cutting policies above
- Derived / computed fields that don't persist — document them in
  the FR file, not here
