# python-template

> LLM-agent-driven project scaffolding template for Python 3.13.
> Hand `SETUP.md` to Claude Code / Cursor and get a green CI pipeline on GitHub.

[![CI](https://github.com/gs071 (개인) 또는 조직명/python-template/actions/workflows/ci.yml/badge.svg)](https://github.com/gs071 (개인) 또는 조직명/python-template/actions/workflows/ci.yml)
[![CodeRabbit](https://img.shields.io/badge/CodeRabbit-Active-brightgreen)](https://coderabbit.ai)
[![License](https://img.shields.io/badge/License-MIT-blue)](LICENSE)

## Purpose

A 2026-caliber Python project setup prompt for LLM agents (Claude Code / Cursor). Covers three archetypes — FastAPI service, Library/CLI, and Data-science — using uv, Ruff, basedpyright strict, syrupy, and a 2-job GitHub Actions CI pipeline with CodeRabbit integration. All steps are non-interactive and fail-fast, so the agent completes setup from an empty directory to CI green on the first push without human intervention.

## Who is this for
- Developers using Claude Code / Cursor who want a reproducible Python project scaffold
- Students / teams learning modern Python tooling in one shot
- Teams migrating from black+isort+mypy to the 2026 Ruff+basedpyright stack

## Quick Start

```bash
# 1. Fork or clone this template into your target workspace

# 2. Choose archetype (see SETUP.md Phase 1)
#    FastAPI Service (default) / Library CLI / Data-science

# 3. Hand SETUP.md to Claude Code
# Ask: "Please set up a new Python project using SETUP.md"
# The agent executes Phase 0 → Phase 8 non-interactively.
# All phases are fail-fast; CI goes green on first push.

# Manual equivalent (FastAPI archetype):
uv init my_project --package --python 3.13
cd my_project
uv add fastapi uvicorn pydantic pydantic-settings
uv add --dev ruff basedpyright ty pytest pytest-cov syrupy pre-commit
```

## What's Inside
- `SETUP.md` — the main prompt (14 sections)
- `CLAUDE.md` — base CLAUDE.md for the generated project
- `.claude/rules/` — modular AI behavior rules (code-style, git, architecture, verification)
- `examples/` — ready-to-copy config file snippets
  - `pyproject.toml` — full integrated config (Ruff 11-rule select, basedpyright strict, pytest cov-fail-under=60)
  - `pyproject.scientific.toml` — Data-science archetype basedpyright relaxation preset
  - `.python-version`, `.pre-commit-config.yaml`, `ci.yml`, `.coderabbit.yaml`
  - `archetype-fastapi/` — FastAPI ASGI app + TestClient fixture + health check test
  - `archetype-library/` — Library/CLI with typer app + `__all__` public API
  - `archetype-data-science/` — numpy/pandas pipeline + `tests/regression/` (no syrupy)

## Phase Overview (14 sections in SETUP.md)
1. Preface + LLM meta-instructions
2. Prerequisites
3. Phase 0 — Repo Init
4. Phase 1 — Archetype Selection + Scaffolding
5. Phase 2 — DevDeps (archetype-specific)
6. Phase 3 — Config Files
7. Phase 4 — Scripts
8. Phase 5 — CI Workflow
9. Phase 6 — CodeRabbit
10. Phase 7 — Local Verify
11. Phase 8 — First Push + CI Green
12. Troubleshooting
13. Essential Checklist
14. Config Reference Appendix

## Coverage Ramp Guide

This template defaults to `--cov-fail-under=60` (initial adoption baseline).

| Stage | Threshold | How |
|-------|-----------|-----|
| Initial | 60% | This template default |
| Intermediate | 70% | After first sprint, raise in pyproject.toml |
| Target | 80% | research.md §6.1 recommendation — mature projects |

Strategy: raise by 10%p per sprint via PR. Once at 80%, switch from numeric target to "new code must ship with tests" policy.

## Why this template exists

### Why not mpuig/claude-code-py-template?

mpuig's template is a **PoC orchestrator**, not a scaffolding template. It provides slash-command agents that build a proof-of-concept from requirements. It has:
- No `.github/workflows/` CI
- No CodeRabbit integration
- No basedpyright (uses mypy)
- No Git safety gate
- No non-interactive `uv init` automation

This template's purpose — "empty directory → CI green, non-interactively" — is simply out of scope for mpuig.

### Why not smartwhale8/claude-playbook?

smartwhale8/claude-playbook is a **language-neutral `.claude/` template**. It provides a production-ready `.claude/rules/` + skills + agents structure, but:
- No Python-specific tooling (Ruff, basedpyright, uv, pytest)
- No SETUP.md phase document to drive scaffolding
- No CI template, no archetype branching
- Requires manual adaptation for every language

This template provides the Python-specific layer that claude-playbook intentionally omits.

### Why not fpgmaas/cookiecutter-uv?

cookiecutter-uv is **interactive-only** — `cookiecutter.json` requires interactive user prompts, which directly conflicts with LLM agent non-interactive execution. Additionally:
- Uses tox + Makefile (not uv-native CI)
- No CodeRabbit `.coderabbit.yaml`
- No basedpyright (offers mypy/ty as interactive choice)
- No LLM meta-instructions
- No Git safety gate

### Feature Matrix Summary

| Feature | mpuig | smartwhale8 | cookiecutter-uv | **This template** |
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

### Core differentiator

This template is part of `llm-setup-prompts` — a **3-language unified scaffolding workspace** (TypeScript + Spring + Python). All three language templates share the same 14-section SETUP.md skeleton, `.claude/rules/` structure, and Git workflow conventions. That cross-language consistency is the feature that none of the three competitors above can replicate.

## Extension & Customization
See `.claude/rules/architecture.md` for archetype-specific module layout rules.
For Data-science: use `examples/pyproject.scientific.toml` to relax basedpyright strict for numpy/scipy stub gaps.

## License
MIT
