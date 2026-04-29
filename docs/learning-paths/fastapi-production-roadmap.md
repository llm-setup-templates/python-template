# FastAPI Production Roadmap — User Onboarding

> **Audience**: developers who scaffolded a FastAPI project from
> `python-template` (`bash ./scaffold.sh fastapi`) and want a clear
> sequence of "what to add next" to reach a production-grade service.
> **Not the template's responsibility** — this document is a curated path,
> not a hard guarantee. Treat it as a checklist you grow into.
>
> **Last validated**: 2026-04-29 against `examples/archetype-fastapi/`
> at branch `main`.

The template gives you a **DB-free, auth-free minimal scaffold**:
Loguru-based logging, Trace-ID `ContextVar`, global exception handlers,
empty `services/` / `repositories/` / `routers/` packages, and
basedpyright + ruff + pytest-cov 60 % gates. Everything below is what
you (the project owner) layer on top.

The 4-part / 7-day structure mirrors the curriculum sequencing from the
[원투코딩 FastAPI 취업 마스터코스](https://onetwocoding.com), which the
template's archetype was tested against. You can pick any reference
material — what matters is the *order*: foundations → security →
operations → deployment.

---

## Template Boundary: scaffold vs user adds

| Layer | What `scaffold.sh fastapi` already gives you | What you add (and where this doc points to) |
|---|---|---|
| **Project skeleton** | `src/my_project/{core,services,repositories,routers,handlers}` | Domain models, route handlers, business logic |
| **Logging** | `core/logging.py` (Loguru env-aware console + JSON + rotation) | Custom log fields per domain |
| **Trace ID** | `core/context.py` (`ContextVar` + Loguru `bind`) — middleware not yet wired | Trace-ID middleware (Day 3 / Part 3) |
| **Error handling** | `core/exceptions.py` + `handlers/exception.py` (global handler) | Domain-specific exception subclasses |
| **Config** | `pydantic-settings` baseline | Per-env `.env` + secret loaders |
| **DB / ORM** | ❌ none | SQLModel + AsyncSession (Day 1 / Part 1) |
| **Auth** | ❌ none | Argon2 + JWT + RBAC (Day 4–5 / Part 2) |
| **Cache / Queue** | ❌ none | Redis + Celery (Day 6 / Part 3) |
| **Deploy** | ❌ none | Docker + AWS EC2/RDS + GitHub Actions (Part 4) |
| **CI / quality gates** | basedpyright strict, ruff, pytest-cov ≥ 60 %, import-linter | Domain test fixtures, integration suite |

> **Why DB-free / auth-free by default?** The template is the *common
> denominator* across FastAPI projects. Database choice (PostgreSQL vs
> MongoDB vs DuckDB) and auth choice (JWT vs sessions vs OAuth) are
> opinionated decisions that don't generalize. Forcing one on every
> derived project would make the template misfit half its users.

---

## Part 1 — Foundations (Day 1–3)

| Day | Topic | Pages (course) | Template covers | You add |
|---|---|---|---|---|
| **D1** | Routing, Pydantic, Swagger, DI | p.12–80 | Routers package, FastAPI app entry | Endpoint contracts, request/response DTOs |
| **D2** | SQLModel + AsyncSession, indexes | p.81–123 | — | DB session factory, repositories layer |
| **D3** | Migrations, schema versioning | p.124–158 | — | Alembic config, baseline migration |

**Suggested order**: get a single endpoint returning a static response →
plug DB session into one repository → wire one route end-to-end → add
the test that proves the round-trip.

---

## Part 2 — Security & Performance (Day 4–5)

| Day | Topic | Pages | Template covers | You add |
|---|---|---|---|---|
| **D4** | Password hashing, JWT auth | p.218–237 | — | Argon2 hashing helper, JWT issuer/verifier, `/auth/login`, `/auth/refresh` |
| **D5** | Role/Permission, RBAC | p.240–263 | — | `Role` / `Permission` enums, dependency-injected guard, RBAC tests |

**Order rationale**: never start RBAC before authentication is solid.
"Who is this user?" must answer correctly before "what can this user do?"
makes any sense.

> **Anti-pattern from the course**: do not store `role` directly on the
> JWT payload as a single string. Pass a `permissions` claim with the
> resolved set, or query at request time. Future-you renaming roles
> will thank you.

---

## Part 3 — Operations (Day 6–7)

| Day | Topic | Pages | Template covers | You add |
|---|---|---|---|---|
| **D6** | Celery + Redis, background tasks | p.426–452 | — | Celery worker, broker config, idempotent task design |
| **D7** | N+1 query fixes, perf hot paths | p.471–481 | — | Eager loading config, slow-query log review |

**Why Celery, not BackgroundTasks?** FastAPI's `BackgroundTasks` runs in
the same process — fine for fire-and-forget side effects, never for
work that must survive a process restart. Celery is the durable
boundary.

**Tracing during operations**: this is where `core/context.py`'s
Trace-ID `ContextVar` actually pays off. Wire a middleware that reads
`X-Request-Id` (or generates one), sets the `ContextVar`, and Loguru's
`bind` will tag every log line for that request. You will need it the
first time a user reports "this one request was slow."

---

## Part 4 — Deployment (Day 7+)

| Topic | Pages | Template covers | You add |
|---|---|---|---|
| IAM + EC2 baseline | p.482–550 | — | Bastion host, key rotation policy |
| VPC + RDS | p.551–620 | — | Private subnet, security group rules |
| Docker + Compose | p.621–680 | — | `Dockerfile`, `docker-compose.yml` for local parity |
| GitHub Actions CI/CD | p.681–705 | 2-job CI baseline | Deploy job, secrets, blue/green or rolling strategy |

> **Note**: the template's CI is a quality gate (lint + test + types),
> not a deployment pipeline. Deployment is intentionally out of scope —
> too many viable shapes (ECS, EKS, Heroku, Fly, self-hosted).

---

## How to use this doc

- **As a checklist**: tick off layers as you implement them.
- **As a hand-off**: link this doc to new contributors so they
  understand *what the template intentionally left out*.
- **As a stop sign**: if you find yourself re-implementing logging /
  exceptions / Trace-ID, check `core/` first — odds are the template
  already shipped what you need.

This roadmap is intentionally not pinned to a specific course version —
it covers the structural sequence. For concrete code samples and
detailed walk-throughs, the course PDF in your `12_courses/` workspace
(or any equivalent reference) is the source of truth.

---

## See also

- [SETUP.md](../../SETUP.md) — scaffold.sh usage and post-Phase-13 architecture
- [RATIONALE.md § Template Boundary](../../RATIONALE.md#template-boundary-what-the-scaffold-covers-vs-what-users-add)
- [examples/archetype-fastapi/](../../examples/archetype-fastapi/) — the scaffolded shape
