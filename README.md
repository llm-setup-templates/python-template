# Python Template — LLM-Agent-Ready Scaffolding

[한국어 README](./README.ko.md)

> An opinionated Python 3.13 project template designed for LLM coding agents
> (Claude Code / Cursor) to scaffold from an empty directory to a green GitHub
> Actions CI — without human intervention mid-setup.

**Empirically verified**: SETUP.md alone drives Claude Code → green CI in 35 min
([proof run](https://github.com/KWONSEOK02/llm-setup-e2e17-python/actions/runs/24566234342)).

---

## Why this template exists

Python project scaffolding is a decision maze: which type checker, which test runner,
which import linter, which formatter, which src layout. This template picks **one
defensible answer for each** and ships a SETUP.md the agent can execute directly.

**Pinned choices** (with reasoning):

| Layer | Choice | Why (rejected alternatives) |
|---|---|---|
| Type check | basedpyright (strict, CI) + ty (IDE) | mypy is slower; plain pyright without strict lets too much through |
| Lint + format | Ruff (E,F,I,UP,B,S,PERF,PD,NPY,RUF) | black + isort + flake8 = 3 tools, 3 ways to configure them wrong |
| Import linter | import-linter with include_external_packages | prevents `services/` from importing `sqlalchemy` directly |
| Runtime / package mgr | uv (not pip) | lockfile, reproducibility, speed |
| Layout | `src/my_project/` | prevents accidental import of in-tree code — a real bug source |
| Archetype | FastAPI / Library-CLI / Data-science | pick the one that fits; see below |

---

## Who should use this

**Persona 1 — Solo developer or small team starting a new Python service**
- What it solves: "what do I pin? what CI do I run? what architecture do I enforce?"
- What it does NOT solve: domain modeling decisions, infrastructure choices (DB, message broker)

**Persona 2 — LLM-assisted development (Claude Code, Cursor)**
- What it solves: the agent gets a fail-fast SETUP.md, retry budgets, verification loops, and zero ambiguity about "which formatter"
- What it does NOT solve: the agent still needs you to pick the archetype, project name, and business domain

**Persona 3 — Team migrating toward strict typing and enforced module boundaries**
- What it solves: basedpyright strict in CI + Import Linter contracts give concrete failures to work through
- What it does NOT solve: the refactoring itself; this template defines the target state, not the migration path

**Persona 4 — Instructor or student setting up a reproducible Python course project**
- What it solves: every student gets identical tooling; "works on my machine" is minimized
- What it does NOT solve: curriculum design or assignment grading

---

## Who should NOT use this

- You need Python <= 3.10 -> this template requires 3.13
- You prefer Poetry or PDM over uv -> swapping out uv touches roughly 40% of the SETUP
- You want a batteries-included MVC framework (Django) -> this targets FastAPI, library, and data-science archetypes, not Django
- You need Windows-first native builds -> CI and Docker paths assume Linux runners

---

## Quick fit check

Answer these three questions:

1. **Python version >= 3.13?** No -> skip this template.
2. **Willing to run basedpyright strict from day one?** (It will fail on common patterns you need to learn to avoid.) No -> use a different template.
3. **Happy with uv as your single package manager?** (No mixing with pip or conda.) No -> fork and swap uv out, or pick a different template.

All three yes -> read [SETUP.md](./SETUP.md).

---

## Archetype selection

Phase 1 of SETUP.md asks you to pick one:

| If your project is... | Pick | Because |
|---|---|---|
| An HTTP API with DTOs, database, and business logic | **FastAPI Service** | bundles routers/services/repositories + AppException hierarchy + Loguru + ErrorResponse schema |
| A reusable package others will `pip install` (SDK, CLI tool, utility lib) | **Library / CLI** | bundles `__all__` public API + typer CLI entry point + `[project.scripts]` |
| Scientific or analytical work with numpy, pandas, scipy | **Data-science** | relaxes basedpyright strict where stubs are absent; swaps syrupy for numpy.testing |

Not sure? Start with **Library / CLI** -- it is the simplest. You can migrate between archetypes later, but picking right upfront saves an hour.

---

## What's inside

- Setup flow: [SETUP.md](./SETUP.md) -- the LLM agent reads this top-to-bottom (14 phases)
- AI agent rules: [CLAUDE.md](./CLAUDE.md) -- tech stack, primary commands, verification checklist
- Architecture boundaries: [.claude/rules/architecture.md](./.claude/rules/architecture.md) -- src layout, import directions, exception hierarchy
- Verification loop: [.claude/rules/verification-loop.md](./.claude/rules/verification-loop.md) -- the 6-slot fail-fast sequence
- Test modification rules: [.claude/rules/test-modification.md](./.claude/rules/test-modification.md) -- when tests must change and how
- Documentation modules: [.claude/rules/documentation.md](./.claude/rules/documentation.md) -- FR / RTM / ADR / RFC / reports

---

## Related templates

- [typescript-template](https://github.com/llm-setup-templates/typescript-template) -- Next.js 15 + FSD 5 layers
- [spring-template](https://github.com/llm-setup-templates/spring-template) -- Spring Boot 3 + layered architecture

---

## Advanced

- [RATIONALE.md](./RATIONALE.md) — why this template picked these specific choices, with comparisons to alternative templates (snapshot as of 2026-04)

---

## License

MIT.
