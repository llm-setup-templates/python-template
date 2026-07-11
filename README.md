# Python Template — LLM-Agent-Ready Scaffolding

[한국어 README](./README.ko.md)

> An opinionated Python 3.13 project template. Clone it, run one script, get a
> project scaffolded to your archetype of choice — with a green CI pipeline.

## Quick Start

```bash
git clone https://github.com/llm-setup-templates/python-template my-app
cd my-app
bash ./scaffold.sh --pkg my_app --archetype fastapi
uv sync && uv run pytest
```

> Run under **Bash** (Git Bash / WSL on Windows). The `bash` prefix is
> load-bearing — `.\scaffold.sh` in PowerShell silently no-ops in headless
> contexts (CI, agent sandboxes) and may not execute the script at all in
> interactive PowerShell. scaffold.sh's internal guard catches dash/sh/zsh
> invocations, but PowerShell bypasses the script body entirely. See
> [RATIONALE.md § PowerShell Silent-No-Op](./RATIONALE.md).

See [SETUP.md](SETUP.md) for all options (library / data-science archetypes,
doc module selection, optional GitHub publish step) and
[ADR-002](docs/architecture/decisions/ADR-002-clone-script-scaffolding.md)
for the architecture rationale.

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

Section 3 (Archetypes) of SETUP.md asks you to pick one:

| If your project is... | Pick | Because |
|---|---|---|
| An HTTP API with DTOs, database, and business logic | **FastAPI Service** | bundles routers/services/repositories + AppException hierarchy + Loguru + ErrorResponse schema |
| A reusable package others will `pip install` (SDK, CLI tool, utility lib) | **Library / CLI** | bundles `__all__` public API + typer CLI entry point + `[project.scripts]` |
| Scientific or analytical work with numpy, pandas, scipy | **Data-science** | relaxes basedpyright strict where stubs are absent; uses numpy.testing for floating-point regression while keeping syrupy for other snapshots |

Not sure? Start with **Library / CLI** -- it is the simplest. You can migrate between archetypes later, but picking right upfront saves an hour.

---

## What's inside

- Setup flow: [SETUP.md](./SETUP.md) -- the LLM agent reads this top-to-bottom (Phase 0 and numbered sections 1-8)
- AI agent rules: [AGENTS.md](./AGENTS.md) -- tech stack, primary commands, verification checklist (Claude Code loads it via the CLAUDE.md import shell)
- Architecture boundaries: [.agents/rules/architecture.md](./.agents/rules/architecture.md) -- src layout, import directions, exception hierarchy
- Verification loop: [.agents/rules/verification-loop.md](./.agents/rules/verification-loop.md) -- the 6-slot fail-fast sequence
- Test modification rules: [.agents/rules/test-modification.md](./.agents/rules/test-modification.md) -- when tests must change and how
- Documentation modules: [.agents/rules/documentation.md](./.agents/rules/documentation.md) -- FR / RTM / ADR / RFC / reports
- Requirements traceability: [docs/requirements/RTM.md](./docs/requirements/RTM.md) -- linted by `scripts/rtm-lint.sh` in `validate.sh` and, in generated projects, by `.github/workflows/rtm.yml`

---

## Available skills

Skills are Claude Code agent prompts in `.claude/skills/`. Each skill is invoked with `/skill-name`.

- **`claude-md-reviewer`** (`.claude/skills/claude-md-reviewer/`) — Reviews the AGENTS.md rules body (and its CLAUDE.md import shell) for completeness and consistency.
- **`tdd`** (`.claude/skills/tdd/`) — Test-driven development with red-green-refactor.
  Vendored verbatim from mattpocock/skills (MIT). See `UPSTREAM.md` + `_local-addendum.md`.
- **`office-hours-ddd-discovery`** (`.claude/skills/office-hours-ddd-discovery/`) —
  Six forcing questions adapted for DDD bounded context discovery. Adapted from
  garrytan/gstack (MIT). Note: Python ships this skill without a companion 6Q×DDD walkthrough doc.

---

## Related templates

- [typescript-template](https://github.com/llm-setup-templates/typescript-template) -- Next.js 16 + FSD 5 layers
- [spring-template](https://github.com/llm-setup-templates/spring-template) -- Spring Boot 3 + layered architecture

---

## Advanced

- [RATIONALE.md](./RATIONALE.md) — why this template picked these specific choices, with comparisons to alternative templates (snapshot as of 2026-04)

---

## License

MIT.
