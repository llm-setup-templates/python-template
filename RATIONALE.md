# RATIONALE — Why python-template made these choices

> **Snapshot as of 2026-04.** External template references (mpuig,
> smartwhale8, cookiecutter-uv) are frozen at the date this document was
> written. They may diverge or become stale. If you are evaluating whether
> to adopt this template in 2027+, treat the comparison sections as
> historical context, not current ground truth.

**Who should read this**: advanced users who have seen several Python
templates and want to know **why this one picked the specific stack it
did**. If you're just deciding whether this template is for you, read
[README.md](./README.md) instead — that has the 30-second fit check.

---

## Feature Matrix

The table below compares this template against three alternatives that
were evaluated before the design was finalized.

| Feature | mpuig/claude-code-py-template | smartwhale8/claude-playbook | fpgmaas/cookiecutter-uv | **This template** |
|---------|:-----:|:-----------:|:---------------:|:-----------------:|
| LLM fail-fast meta-instructions | N | Partial | N | Y |
| Non-interactive scaffolding | N | N | **N (interactive)** | Y |
| 2-job CI + needs gate + concurrency cancel | N | Unknown | Partial | Y |
| CodeRabbit path_instructions | N | N | N | Y |
| basedpyright strict CI | N | N | N | Y |
| 3 archetype branching | N | N | N | Y |
| Git safety gate bash block | N | Unknown | N | Y |
| 3-language unified skeleton | N | N | N | Y |
| Scientific basedpyright preset | N | N | N | Y |

---

## Alternatives considered

### mpuig/claude-code-py-template

mpuig's template is a **PoC orchestrator**, not a scaffolding template.
It provides slash-command agents that build a proof-of-concept from
requirements. It has:

- No `.github/workflows/` CI
- No CodeRabbit integration
- No basedpyright (uses mypy)
- No Git safety gate
- No non-interactive `uv init` automation

This template's purpose — "empty directory → CI green, non-interactively"
— is simply out of scope for mpuig. The two templates answer different
questions: mpuig answers "build me a working PoC from a description",
this template answers "give me a production-grade project scaffold that a
CI system can verify on the first push".

### smartwhale8/claude-playbook

smartwhale8/claude-playbook is a **language-neutral `.claude/` template**.
It provides a production-ready `.claude/rules/` + skills + agents
structure, but:

- No Python-specific tooling (Ruff, basedpyright, uv, pytest)
- No SETUP.md phase document to drive scaffolding
- No CI template, no archetype branching
- Requires manual adaptation for every language

This template provides the Python-specific layer that claude-playbook
intentionally omits. The two are complementary rather than competing:
claude-playbook is a good foundation for the `.claude/` configuration
layer, while this template adds the Python toolchain and agent-executable
setup flow on top.

### fpgmaas/cookiecutter-uv

cookiecutter-uv is **interactive-only** — `cookiecutter.json` requires
interactive user prompts, which directly conflicts with LLM agent
non-interactive execution. Additionally:

- Uses tox + Makefile (not uv-native CI)
- No CodeRabbit `.coderabbit.yaml`
- No basedpyright (offers mypy/ty as interactive choice)
- No LLM meta-instructions
- No Git safety gate

The interactive prompt model is a fundamental design choice, not a
missing feature. Adding non-interactive support would require replacing
the entire cookiecutter interpolation layer. For human-driven project
creation where interactivity is acceptable, cookiecutter-uv is a
reasonable choice; for agent-driven pipelines it is not.

---

## Why these pinned versions

### Python 3.13

Python 3.13 introduced free-threaded mode (PEP 703) and improved error
messages. More importantly: choosing 3.13 means the template gets to use
3.12+ syntax (PEP 695 type aliases) and deprecates patterns that were
removed or warned against in 3.12. Pinning to an older version would
require "compatibility shims" that obscure idiomatic modern Python from
the LLM agent.

### basedpyright (strict) over mypy

- mypy is **slower** — a project with 50 files takes noticeably longer in CI
- plain pyright (not `strict`) lets too much through: implicit `Any`,
  missing return types, and untyped function parameters all pass silently
- basedpyright strict applies strict type checking that catches real bugs
  before runtime: `Unknown` propagation, missing `__all__` exports, and
  inferred-`Any` function calls

The cost is real: basedpyright strict requires annotating functions that
mypy would accept without annotations. That cost is intentional — this
template treats strict types as a non-negotiable invariant, not a
nice-to-have.

### ty (IDE only, not in CI)

ty is Astral's new type checker, currently in alpha. It is significantly
faster than basedpyright for interactive use (sub-second feedback in
editors). However, its output is not yet stable enough for a CI gate:
false positives and missing checks make it unsuitable as the single
source of truth for a PR workflow. The split — `ty` in the editor,
`basedpyright` in CI — gives developers fast feedback without
compromising the CI gate.

### Ruff over black + isort + flake8

Three tools means three configuration surfaces that can diverge. Ruff
handles formatting (equivalent to black), import sorting (equivalent to
isort), and linting (equivalent to flake8 + many plugins) from a single
`[tool.ruff]` section in `pyproject.toml`. The 11-rule select in this
template (`E,F,I,UP,B,S,PERF,PD,NPY,RUF`) covers style, imports,
upgrades, bugbear, security, performance, pandas-specific, numpy-specific,
and Ruff-specific rules — coverage that would require six separate plugins
under the old stack.

### uv over pip + poetry

- pip lacks a lockfile format — `requirements.txt` pinning is fragile
- poetry is slow (dependency resolver) and uses a different lockfile
  format than the stdlib/uv ecosystem
- uv resolves in milliseconds, generates a standards-compatible lockfile
  (`uv.lock`), and integrates with `pyproject.toml` directly
- `uv init --package` with `src/` layout is a single command vs. manual
  directory creation + `setup.cfg` with pip

The `src/` layout choice (produced by `uv init --package`) is not
aesthetic: it prevents accidental imports of in-tree code during testing,
which is a real class of bug where `pytest` discovers the local module
instead of the installed package.

### Import Linter over runtime checks

Architecture boundaries (`routers/ → services/ → repositories/`) are
only useful if they are enforced. Runtime enforcement (raising at import
time) fails too late — CI must catch boundary violations before a PR
merges. Import Linter runs as a static check and fails the CI pipeline if
any configured boundary is violated. The contracts in `examples/.importlinter`
(with `include_external_packages = True`) also prevent service layers from
importing framework dependencies directly, keeping business logic
framework-agnostic.

---

## Rejected alternatives (summary)

| Decision | Chosen | Rejected | Reason |
|---|---|---|---|
| Type check | basedpyright strict (CI) + ty (IDE) | mypy | Speed + strict default catches more bugs |
| Lint + format | Ruff (unified) | black + isort + flake8 | Single config, faster, broader rule coverage |
| Package manager | uv | pip, poetry | Lockfile + speed + `src/` layout integration |
| Architecture enforcement | Import Linter (static) | Runtime checks, convention | CI catches boundary violations before merge |
| Non-interactive scaffolding | SETUP.md phase doc | cookiecutter interactive | Agent-executable without user prompts |
| CI template | 2-job (lint-type-test / build-push) | Single-job | Fail-fast on type errors without running build |
| PR review | CodeRabbit `.coderabbit.yaml` | Manual, Reviewdog | Path-specific instructions for LLM context |

---

## Core differentiator

This template is part of `llm-setup-prompts` — a **3-language unified
scaffolding workspace** (TypeScript + Spring + Python). All three
language templates share the same 14-section SETUP.md skeleton,
`.claude/rules/` structure, and Git workflow conventions. That
cross-language consistency is the feature that none of the three
competitor templates above can replicate — they are each single-language
solutions with no shared skeleton or cross-language convention.

---

## See also

- [README.md](./README.md) — 30-second fit check and quick start
- [SETUP.md](./SETUP.md) — scaffold.sh usage guide (post-Phase-13 architecture)
- [ADR-002](./docs/architecture/decisions/ADR-002-clone-script-scaffolding.md)
  — why the pre-Phase-13 14-phase SETUP.md flow was replaced with clone + script
- [CLAUDE.md](./CLAUDE.md) — AI agent rules for derived projects
- External references (snapshot as of 2026-04):
  - [mpuig/claude-code-py-template](https://github.com/mpuig/claude-code-py-template)
  - [smartwhale8/claude-playbook](https://github.com/smartwhale8/claude-playbook)
  - [fpgmaas/cookiecutter-uv](https://github.com/fpgmaas/cookiecutter-uv)

---

## Clone + Script Architecture (Phase 13, 2026-04-23)

See [ADR-002](./docs/architecture/decisions/ADR-002-clone-script-scaffolding.md)
for the full decision record. One-sentence summary: Phase 12 Fix 1–6 accumulated
environment-specific workarounds because **template file acquisition was coupled
to GitHub CLI availability**. Phase 13 decouples them — `git clone` gets the
files, `./scaffold.sh` customizes, and `gh repo create` is an optional separate
step. Direct driver: Codex e2e23 dry run (2026-04-23) spent 2m 26s unable to
locate Windows `gh.exe` from its Linux sandbox and never reached Phase 1.
