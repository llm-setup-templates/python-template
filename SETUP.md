# Python Template — Setup Guide

> Clone this template, run one script, get a Python project scaffolded to
> your archetype of choice with a green CI pipeline. See [ADR-002](docs/architecture/decisions/ADR-002-clone-script-scaffolding.md)
> for the architecture rationale.

## 1. Quick Start (three commands)

```bash
git clone https://github.com/llm-setup-templates/python-template my-app
cd my-app
bash ./scaffold.sh --pkg my_app --archetype fastapi
```

> **Run under Bash** — not PowerShell or cmd.exe. On Windows this means
> Git Bash, WSL, or any shell where `bash --version` prints a version.
> scaffold.sh contains an interpreter guard that refuses to run under
> non-bash interpreters (prevents silent-success failures where `.sh`
> file associations return exit 0 without executing the script body —
> observed in the e2e24 PowerShell dry run).

Then verify locally:

```bash
uv sync --all-extras --dev
uv run ruff check . && uv run ruff format --check . \
  && uv run basedpyright && uv run lint-imports && uv run pytest
git add .
git commit -m "feat(scaffold): initial project setup"
```

## 2. scaffold.sh Reference

```
Usage: ./scaffold.sh --pkg <snake_case> [options]

Required:
  --pkg <name>           Python package name (snake_case, e.g. my_app)

Optional:
  --archetype <type>     fastapi (default) | library | data-science
  --doc-modules <list>   comma-separated from {core,reports,briefings,extended}
                         default: core. 'core' is mandatory.
  --dry-run              Print planned actions without writing.
  -h, --help             Print this usage.
```

**What scaffold.sh does** (8 stages, see [ADR-002](docs/architecture/decisions/ADR-002-clone-script-scaffolding.md)):

| Stage | Action |
|---|---|
| A | Remove template-only files (`validate.sh`, `.github/workflows/validate.yml`, template dependabot, `RATIONALE.md`, `test/`, ADR-002). Keeps `.claude/` (agent rules) + `examples/` (used by Stage B). |
| B | Select archetype-specific pyproject.toml / .importlinter / src/ / tests/ from `examples/archetype-<type>/`. |
| C | Copy archetype files + shared configs (`ci.yml`, `.pre-commit-config.yaml`, `.python-version`, `.gitignore`) to repo root. |
| D | Substitute `my_project` → `$PKG` in pyproject, importlinter, and all .py files. Substitute `{{REPO_NAME}}` → `$(basename $PWD)` in CLAUDE.md. Rename `src/my_project/` → `src/$PKG/`. |
| E | Trim unselected doc modules (rm `docs/reports/`, `docs/briefings/`, or `docs/architecture/containers.md + DFD.md + docs/data/` as requested). |
| F | Remove `examples/` (no longer needed in derived repo). |
| G | `rm -rf .git && git init -b main` (fresh history — template history is not inherited). |
| H | Print next steps + self-delete (on Linux/macOS; Windows Git Bash requires manual `rm scaffold.sh`). |

**Single-use**: scaffold.sh runs once on a freshly cloned template. It detects
the presence of `validate.sh` as a freshness marker; if `validate.sh` is missing
(because a previous scaffold run removed it), the script refuses to run and
instructs you to re-clone.

## 3. Archetypes

### fastapi (default)

Production-grade FastAPI service with:
- `src/$PKG/{core,handlers,routers,services,repositories,schemas}/` — layered architecture
- `core/` — settings, exception hierarchy, logging, ContextVar
- Loguru structured logging (JSON/console by env)
- ErrorResponse + 4 global exception handlers
- Import Linter layered contract (routers → services → repositories)

### library

Library / CLI project using Typer + Rich:
- `src/$PKG/{cli,core}.py`
- `tests/test_smoke.py` — basic import smoke tests
- Import Linter core-purity contract (forbids framework deps in core)

### data-science

Numpy / Pandas / Scipy pipeline project:
- `src/$PKG/pipeline.py`
- `tests/regression/` — floating-point regression tests (use `numpy.testing.assert_allclose`, NOT syrupy)
- basedpyright relaxation (`reportUnknownMemberType = false` etc) — scientific stubs are incomplete
- Import Linter pipeline-isolation contract

## 4. Publish to GitHub (optional)

scaffold.sh does **not** create a GitHub repository — that's a separate
step, decoupled from scaffolding. This lets scaffold.sh work in offline
environments, self-hosted GitLab mirrors, or air-gapped CI.

To publish after scaffolding + first commit:

```bash
gh auth status
gh repo create <repo-name> --private --source=. --remote=origin
git push -u origin main
```

### First-push CI recovery

If `git push` does not automatically trigger a CI run on `main` (race with
GitHub's default-branch bootstrap on brand-new repos), trigger manually:

```bash
gh workflow run ci.yml --ref main
gh run watch
```

`workflow_dispatch` is wired into `ci.yml` expressly for this recovery case.

## 5. Verification

Full local verification loop:

```bash
uv run ruff check . \
  && uv run ruff format --check . \
  && uv run basedpyright \
  && uv run lint-imports \
  && uv run pytest
```

Runs in CI (`.github/workflows/ci.yml`) on every push to `main` and every PR.

## 6. CODEOWNERS customization

**Required before enabling branch protection reviews.** `.github/CODEOWNERS`
ships with three placeholder groups:

- `@YOUR_ORG/engineering` — default owner (wildcard fallback)
- `@YOUR_ORG/architects` — decisions, `core/`, Import Linter contracts
- `@YOUR_ORG/devops` — CI/CD, dependency surface, Python version pin

Sweep substitution:

```bash
# Solo project:
sed -i "s|@YOUR_ORG/[a-z-]*|@YOUR_USERNAME|g" .github/CODEOWNERS

# Team project (example):
sed -i "s|@YOUR_ORG/engineering|@my-team/eng|g;
        s|@YOUR_ORG/architects|@my-team/architects|g;
        s|@YOUR_ORG/devops|@my-team/platform|g" .github/CODEOWNERS

# Verify:
grep -n "YOUR_ORG\|YOUR_USERNAME" .github/CODEOWNERS  # must be empty
```

## 7. Troubleshooting

| Problem | Cause | Solution |
|---------|-------|----------|
| `scaffold.sh: /bin/bash^M: bad interpreter` | CRLF line endings (Windows) | `dos2unix scaffold.sh` or re-clone with `core.autocrlf=false` |
| `ERROR: validate.sh not found` | scaffold.sh already ran once | Re-clone the template — scaffold.sh is single-use |
| `ERROR: scaffold.sh must be executed by Bash.` | Invoked via PowerShell / cmd / sh (silent-success scenario blocked) | Prefix `bash`: `bash ./scaffold.sh --pkg ... --archetype ...`. On Windows use Git Bash or WSL. |
| `uv: command not found` | uv not installed | `curl -LsSf https://astral.sh/uv/install.sh \| sh` then restart shell |
| `Python 3.13 not found` | Python 3.13 missing | `uv python install 3.13` |
| `basedpyright: reportUnknownMemberType` errors (numpy/pandas) | Wrong archetype used | Re-scaffold with `--archetype data-science` |
| `lint-imports: Missing layer 'my_project.routers'` | Library/Data-science archetype using fastapi .importlinter | Re-scaffold with correct `--archetype` (scaffold picks the right one) |
| `uv sync` reports `invalid utf-8` on README or config files | Files written with Windows PowerShell UTF-16 BOM | Re-clone in Git Bash / Linux / WSL bash. scaffold.sh + git together produce UTF-8 no-BOM output. |
| `git push` succeeds but `gh run list` empty | Push-to-main race with default-branch bootstrap | `gh workflow run ci.yml --ref main` (workflow_dispatch is wired in ci.yml) |
| `rm -- "$0"` warning after scaffold | Windows file lock on scaffold.sh | Harmless — delete manually: `rm scaffold.sh` |

## Appendix A. Prerequisites

- `git` ≥ 2.40
- `bash` ≥ 4.0 (Git Bash on Windows / Linux bash / macOS bash via `brew install bash`)
- `uv` (Python package manager) — install: `curl -LsSf https://astral.sh/uv/install.sh | sh`
- `gh` (GitHub CLI) — **optional**, only needed to publish to GitHub

## Appendix B. Placeholder Index

| Placeholder | Scope | Filled by | Case / Format | Example |
|---|---|---|---|---|
| `{{REPO_NAME}}` | `CLAUDE.md` title | scaffold.sh Stage D | hyphen-case (directory basename) | `my-awesome-app` |

`$PKG` is **not a placeholder** — it's the `--pkg` flag value passed to
scaffold.sh, substituted into `pyproject.toml`, `.importlinter`, and all
`.py` files during Stage D.

See [ADR-002](docs/architecture/decisions/ADR-002-clone-script-scaffolding.md)
for why the pre-Phase-13 PROJECT_NAME / VISIBILITY placeholders were removed
(answer: they were Phase 0 `gh repo create` inputs, which now live in the
optional § 4 Publish step, not the scaffolding path).
