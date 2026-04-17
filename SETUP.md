# Python Template — LLM Agent Setup Prompt

> This document instructs an autonomous coding agent (Claude Code / Cursor)
> to scaffold a new Python project from an empty directory to a green
> CI pipeline on GitHub.

## 1. Preface — LLM Agent Meta-Instructions

You are an autonomous coding agent. Execute this document Phase by Phase
from top to bottom.

### Execution Rules
- Use the Bash tool for shell commands. Use the Write tool for config files.
- Each Phase is **fail-fast**. On failure, consult the Troubleshooting
  section and retry up to **3 times** before escalating to the human.
- Never skip the **Local Verify** phase. Do not claim completion until CI
  shows green on the first push (use `gh run watch`).
- Use **pinned versions** from the Config Reference Appendix. Do not guess.
- Do not ask the human for input during execution except for:
  (a) GitHub repo name
  (b) visibility (private/public)
  (c) final approval before pushing

### Success Criteria
- [ ] GitHub repository created and first commit pushed
- [ ] All CI jobs pass on the first push
- [ ] CodeRabbit app connected (or fallback configured)
- [ ] Local `uv run ruff check . && uv run ruff format --check . && uv run basedpyright && uv run lint-imports && uv run pytest` passes from a fresh clone

## 2. Prerequisites
- `gh` CLI authenticated (`gh auth status`)
- `git` ≥ 2.40
- Python ≥ 3.13
- uv installed

## 3. Phase 0 — Repo Init

```bash
gh auth status || exit 1
mkdir {{PROJECT_NAME}} && cd {{PROJECT_NAME}}
git init -b main
gh repo create {{PROJECT_NAME}} --private --source=. --remote=origin
```

## 3.1 Phase 0.5 — Clone Template Reference

Throughout Phases 2~6 the agent copies files from `examples/`, `docs/`,
`.github/`, and other template-owned directories. In the `--source=.`
path used in Phase 0, the new repo is empty — these files do NOT exist
yet. Clone the template as a **read-only reference**:

```bash
gh repo clone llm-setup-templates/python-template /tmp/ref-python
```

Throughout this document, when instructed to copy from `examples/X`,
use `cp /tmp/ref-python/examples/X .` (not `cp examples/X .`).

Clean up after Phase 8:

```bash
rm -rf /tmp/ref-python
```

> **Alternative (`--template` path)**: If you started with
> `gh repo create --template ...` instead of Phase 0's `--source=.`, the
> template files are already in your repo and Phase 0.5 is not needed.
> However, the `--template` path has a drawback: GitHub auto-creates an
> "Initial commit" message that violates the Conventional Commits gate
> in Phase 8. For LLM autonomous flows, **`--source=.` (Phase 0) is the
> recommended path**.

## 4. Phase 1 — Choose Your Archetype & Scaffolding

### Phase 1 — Choose Your Archetype
Select one and follow the branch. The rest of SETUP.md applies identically.

- [ ] **FastAPI Service** (default)
      → Phase 2: `uv add fastapi uvicorn pydantic`
      → `src/my_project/main.py`: ASGI app (see examples/archetype-fastapi/)

- [ ] **Library / CLI**
      → Phase 2: `uv add typer rich`
      → `src/my_project/__init__.py`: public API with `__all__`
      → `src/my_project/cli.py`: typer app
      → `pyproject.toml [project.scripts]`: `my_project = "my_project.cli:main"`

- [ ] **Data-science** (numpy / pandas / scipy)
      → Phase 2: `uv add numpy pandas scipy`
      → `src/my_project/pipeline.py`: processing class
      → Phase 3: apply `examples/pyproject.scientific.toml` basedpyright relaxations
      → Do NOT use syrupy for floating-point tests; use `tests/regression/` with `numpy.testing.assert_allclose`

### Scaffolding Command (all archetypes)

You are already inside `{{PROJECT_NAME}}/` from Phase 0, so initialize the
current directory in place — do NOT pass a path to `uv init` (that would
nest `{{PROJECT_NAME}}/{{PROJECT_NAME}}/`).

```bash
uv init --package --python 3.13
```

Note: `uv init --package` derives the Python package name from the
**current directory name** by converting hyphens to underscores. So
`my-project/` → `src/my_project/`. The SNAKE_CASE package name is written
into `pyproject.toml` as `[project.scripts]` entry; remember it — every
example below that references `my_project` should read as "your actual
package name". Define it once:

```bash
PKG=$(basename "$PWD" | tr '-' '_')
echo "Using package: $PKG"
```

## 5. Phase 2 — DevDeps Installation

```bash
# Choose ONE archetype block:

# [FastAPI Service — default]
uv add fastapi uvicorn pydantic pydantic-settings
# FastAPI TestClient depends on httpx — add to dev deps below

# [Library / CLI]
uv add typer rich

# [Data-science]
uv add numpy pandas scipy

# All archetypes: dev dependencies
uv add --dev ruff basedpyright ty pytest pytest-cov syrupy pre-commit import-linter

# FastAPI archetype only: starlette TestClient requires httpx
uv add --dev httpx
```

## 6. Phase 3 — Config Files

Write the following config files (exact content in Appendix § Config Reference).

> **IMPORTANT**: `uv init --package` from Phase 1 already generated a
> `pyproject.toml` using `uv_build` as the build backend. You MUST
> **overwrite** (not merge) that file with the Appendix content below,
> which uses `hatchling`. After overwriting, re-run `uv sync` once.

- pyproject.toml — **replace** the uv-generated file; then substitute every `my_project` literal with `$PKG`
- .python-version
- .pre-commit-config.yaml
- .coderabbit.yaml
- .gitignore (see Appendix § .gitignore — `uv init` does not generate one)
- pyrightconfig.json — exclude `examples/` from basedpyright scan (see Appendix)
- .importlinter — architecture boundary contracts (see Appendix § .importlinter):
  `cp /tmp/ref-python/examples/.importlinter .`
  Then substitute every `my_project` literal with `$PKG`:
  `sed -i "s/my_project/$PKG/g" .importlinter`
- CLAUDE.md: replace `{{PROJECT_NAME}}` with the actual project name:
  `sed -i "s/{{PROJECT_NAME}}/$(basename "$PWD")/g" CLAUDE.md`

> **Data-science archetype note**: After writing `pyproject.toml`, apply
> `examples/pyproject.scientific.toml` basedpyright relaxations:
>
> ```
> # === Data-science archetype: basedpyright relaxation ===
> # numpy / pandas / scipy 기반 프로젝트는 [tool.pyright] 섹션에서 아래 3줄을 주석 해제하거나
> # examples/pyproject.scientific.toml의 [tool.pyright] 섹션으로 교체하세요.
> # FastAPI / Library archetype: 이 블록을 주석 유지 (strict 모드 기본값 유지).
> #
> # reportUnknownMemberType = false
> # reportUnknownArgumentType = false
> # reportUnknownVariableType = false
> ```

## 7. Phase 4 — Build / Run Scripts

```toml
[project.scripts]
my_project = "my_project.main:main"
```

> **Library/CLI archetype**: replace with `my_project = "my_project.cli:main"`

## 8. Phase 5 — CI Workflow

Write `.github/workflows/ci.yml` (exact content in Appendix § CI Reference).

## 8.5 Phase 5.5 — Documentation Scaffold

This phase installs the documentation tree and GitHub governance files.

### How installation works

When a project is created with `gh repo create --template
llm-setup-templates/python-template` (or by forking this repo), the
following are **already present in the working directory**:

```
.github/
├── ISSUE_TEMPLATE/{feature,bug,adr,config}.yml
├── PULL_REQUEST_TEMPLATE.md
├── CODEOWNERS                          # placeholder — customize
└── workflows/validate.yml

docs/
├── README.md                           # decision tree + navigation
├── requirements/
│   ├── RTM.md
│   └── _FR-template.md                 # Mini-Spec (Pydantic / SQLAlchemy / async idiom)
├── architecture/
│   ├── overview.md                     # C4 Lv1 (Core)
│   ├── containers.md                   # C4 Lv2 (Extended — FastAPI / SQLAlchemy / Redis)
│   ├── DFD.md                          # Data Flow Diagram (Extended)
│   └── decisions/
│       ├── README.md
│       ├── _ADR-template.md
│       └── _RFC-template.md
├── reports/                            # opt-in module
│   ├── README.md
│   ├── _spike-test-template.md
│   ├── _benchmark-template.md
│   ├── _api-analysis-template.md
│   └── _paar-template.md
├── briefings/                          # opt-in module
│   ├── README.md
│   └── _template/
└── data/
    └── dictionary.md                   # Extended — links entries to Pydantic / SQLAlchemy
```

The agent's job is not to generate these files — they ship with the
template. The agent's job is to **trim modules the human doesn't want**,
customize **placeholders**, and then register the decision.

### 8.5.1 Module selection

The docs/ structure has 4 modules: core (always), reports, briefings, extended.

**In autonomous/LLM mode** (default for this template): use `core` only.
Skip trimming the other modules if they don't exist yet (valid under the
`--source=.` path).

**In interactive mode**: ask the human to confirm the selection:

```
Documentation modules to keep (default = core only):
- core       [always kept]  FR / RTM / ADR / RFC / overview
- reports    [y/n]          portfolio / spike / benchmark / API / PAAR
- briefings  [y/n]          dated, frozen interview & talk archives
- extended   [y/n]          C4 Lv2 containers / DFD / Extended DD
```

| Module | Default | Include condition |
|--------|---------|-------------------|
| core | YES | always |
| reports | NO | user confirms OR `--with-reports` passed |
| briefings | NO | user confirms OR `--with-briefings` passed |
| extended | NO | user confirms OR `--with-extended` passed |

**Source-mode note**: If your repo came from Phase 0 `--source=.`, the
docs/ folder is empty by default. Copy from `/tmp/ref-python/docs/` in
core-only mode (see Phase 0.5). If you started from `--template`,
docs/ is pre-populated and 5.5 becomes trim-only.

### 8.5.2 Trim unwanted modules

```bash
# If reports is NOT wanted:
rm -rf docs/reports/

# If briefings is NOT wanted:
rm -rf docs/briefings/

# If extended is NOT wanted:
rm -f docs/architecture/containers.md docs/architecture/DFD.md
rm -rf docs/data/
```

### 8.5.3 Replace placeholders

- `.github/CODEOWNERS` — replace `@YOUR_ORG/*` with real team handles
  (or a single `* @YOUR_USERNAME` line for solo projects)
- `docs/README.md` — top-of-file project name and one-line description
- `docs/architecture/overview.md` — project name, actors, external
  systems in the Mermaid diagram
- `docs/architecture/containers.md` (if kept) — adjust container rows
  for your archetype (Library / CLI typically keeps only the API-like
  row; Data-science replaces them with a Pipeline runner row)
- `docs/requirements/RTM.md` — remove the example row; the table
  starts empty

### 8.5.4 Update the documentation map

Edit `.claude/rules/documentation.md` to remove module sections that
aren't installed. This keeps Claude's decision tree accurate when it
later asks "where does this new document go?"

### 8.5.5 Self-check

Run `bash validate.sh`. The template's own CI also runs it on every
push / PR (see `.github/workflows/validate.yml`). The extended checks
verify:

- regression guards for PR #7's lint-imports wiring (SETUP.md and
  CLAUDE.md must keep referencing `lint-imports` and `import-linter`)
- `.github/` and `docs/` Core file presence
- ADR lifecycle (five states) encoded in the decisions README
- PR template carries FR / ADR / RTM / Balancing disciplines
- Reports / Briefings / Extended modules are complete when present
  (partial installs are rejected)

---

## 9. Phase 6 — CodeRabbit Setup

1. Write `.coderabbit.yaml` (exact content in Appendix § CodeRabbit Reference).
2. Install CodeRabbit GitHub App: https://github.com/apps/coderabbitai
3. If CodeRabbit trial is unavailable, fall back to the Claude Code Review
   Action (Appendix § Fallback).

## 10. Phase 7 — Local Verify (fail-fast)

```bash
uv run ruff check . \
  && uv run ruff format --check . \
  && uv run basedpyright \
  && uv run lint-imports \
  && uv run pytest
```

> **Step order rationale**: Import Linter (`lint-imports`) runs between
> type checking and tests so architectural boundary violations
> (`services/` importing `sqlalchemy`, routers bypassing services) fail
> fast — before any test cost. Matches CI step order in Appendix § CI
> Reference.

### Fix permissions during verify

If a step fails, you MAY run the fix variant once, then re-run the check:

| Failed step | Allowed fix | Re-check |
|---|---|---|
| `uv run ruff check .` | `uv run ruff check --fix .` | `uv run ruff check .` |
| `uv run ruff format --check .` | `uv run ruff format .` | `uv run ruff format --check .` |

Fixes are part of the normal iteration loop. They do NOT count against the
3-attempt retry budget.

All checks must pass before Phase 8.

> **syrupy first run**: If snapshot files don't exist yet, run
> `uv run pytest --snapshot-update` once, then re-run without `--snapshot-update`.
>
> **Data-science archetype**: Do NOT use syrupy for floating-point tests.
> Use `numpy.testing.assert_allclose` with explicit tolerances in `tests/regression/`.

## 11. Phase 8 — First Push + CI Green

### 11.1 Initial commit (required before Gate 1)

Gate 1 calls `git rev-parse --abbrev-ref HEAD` which requires at least
one commit to exist. On a fresh `git init` repo there is no HEAD yet,
so stage and commit all scaffolded files first:

```bash
git add .
git commit -m "feat(scaffold): initial project setup"
```

### 11.2 Git Safety Gate (MANDATORY — run before push)

```bash
# Gate 1: branch check
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" = "main" ]; then
  echo "BLOCKED: direct commit on main. Moving to feat/initial-setup."
  git branch feat/initial-setup && git checkout feat/initial-setup
fi

# Gate 2: commit message convention
INVALID=$(git log --format=%s -10 | \
  grep -vE '^(feat|fix|docs|chore|refactor|test|ci)(\([a-z0-9-]+\))?: .+' || true)
if [ -n "$INVALID" ]; then
  echo "BLOCKED: commit message convention violation:"
  echo "$INVALID"
  echo "Fix: git reset --soft HEAD~N and rewrite commits. DO NOT force push."
  exit 1
fi

# Gate 3: uncommitted changes
git diff --quiet && git diff --cached --quiet || {
  echo "BLOCKED: uncommitted changes exist."
  exit 1
}
```

### 11.3 Push + watch CI

The CI workflow triggers on `push` to `main` and on `pull_request` targeting
`main`. On a brand-new repo created via `gh repo create --source=. --remote=origin`,
the remote has no `main` yet — you must seed it by pushing your feature branch
commit into `main`:

```bash
# First push: seed remote main from the feature branch commit
git push origin $(git rev-parse --abbrev-ref HEAD):main

# Subsequent pushes: push the feature branch normally
git push -u origin $(git rev-parse --abbrev-ref HEAD)

gh run watch
```

### 11.4 Success Declaration

Only after `gh run watch` reports all jobs green, you may report the task
as complete to the human.

## 12. Troubleshooting

| Problem | Cause | Solution |
|---------|-------|----------|
| `uv: command not found` | uv not installed | `curl -LsSf https://astral.sh/uv/install.sh \| sh` then restart shell |
| `Python 3.13 not found` | Python 3.13 not installed | `uv python install 3.13` |
| `basedpyright: reportUnknownMemberType` mass errors | numpy/scipy incomplete stubs | Data-science archetype → apply `examples/pyproject.scientific.toml` |
| `syrupy: snapshot file missing` — test FAILED | Snapshot not yet generated | `uv run pytest --snapshot-update` once then re-run (floating-point results: use `numpy.testing.assert_allclose` instead) |
| `ruff check .` vs `ruff check.` | Missing space (research.md source bug) | Always `ruff check .` (space before dot is required) |

## 13. Essential Checklist

- [ ] `gh auth status` passed
- [ ] Python version verified (≥ 3.13)
- [ ] Scaffolding command ran in an empty or newly-created directory
- [ ] All config files written
- [ ] `uv run ruff check . && uv run ruff format --check . && uv run basedpyright && uv run lint-imports && uv run pytest` passes locally
- [ ] Git Safety Gate passed
- [ ] `gh run watch` shows green CI
- [ ] CodeRabbit app installed or fallback configured

## 14. Config Reference Appendix

### § Pinned Versions

| Tool | Version |
|------|---------|
| ruff | 0.15.x |
| basedpyright | 1.39+ |
| pytest | 9.0.3 |
| pytest-cov | 7.1.0 |
| syrupy | 5.1.0 |
| pre-commit | 4.5.x |
| import-linter | 2.1+ |

### § Config File Contents

#### pyproject.toml

> Replace every `my_project` below with your actual SNAKE_CASE package name
> (value of `$PKG`). A quick sed after writing:
> `sed -i "s/my_project/$PKG/g" pyproject.toml`

```toml
[project]
name = "my_project"
version = "0.1.0"
description = "2026 Python Fail-Fast Scaffolded Project for LLM Agents"
readme = "README.md"
requires-python = ">=3.13"
dependencies = [
    # FastAPI archetype default — remove for Library/Data-science
    "fastapi>=0.115.0",
    "uvicorn>=0.32.0",
    "pydantic>=2.9.0",
    "pydantic-settings>=2.5",
]

[project.scripts]
my_project = "my_project.main:main"

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[dependency-groups]
dev = [
    "ruff>=0.15.0",
    "basedpyright>=1.39.0",
    "ty>=0.0.29",
    "pytest>=9.0.3",
    "pytest-cov>=7.1.0",
    "syrupy>=5.1.0",
    "pre-commit>=4.5.0",
    "import-linter>=2.1",
    # FastAPI archetype: TestClient requires httpx (starlette dep)
    "httpx>=0.28.0",
]

[tool.ruff]
target-version = "py313"
line-length = 88
src = ["src", "tests"]
exclude = ["examples"]

[tool.ruff.lint]
select = ["E", "W", "F", "I", "UP", "B", "S", "PERF", "PD", "NPY", "RUF"]
ignore = ["E501"]

[tool.ruff.lint.per-file-ignores]
# tests use bare `assert` (pytest idiom); S101 is a bandit rule meant for prod code.
"tests/**/*.py" = ["S101"]

[tool.ruff.format]
quote-style = "double"
indent-style = "space"

[tool.pyright]
pythonVersion = "3.13"
typeCheckingMode = "strict"
reportMissingTypeStubs = true
reportEmptyAbstractUsage = "error"
# reportUnknownMemberType = false   # data-science archetype only
# reportUnknownArgumentType = false # data-science archetype only
# reportUnknownVariableType = false # data-science archetype only

[tool.ty.rules]
call-non-callable = "error"
override-of-final-method = "error"
ambiguous-protocol-member = "warn"

[tool.pytest.ini_options]
minversion = "9.0"
addopts = "--cov=src/my_project --cov-report=term-missing --cov-fail-under=60 -v"
testpaths = ["tests"]
```

#### .python-version

```
3.13
```

#### .pre-commit-config.yaml

```yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.15.0
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format

  - repo: local
    hooks:
      - id: basedpyright
        name: basedpyright type check
        language: system
        entry: uv run basedpyright
        types: [python]
        pass_filenames: false
```

> **Note on `__snapshots__/`**: syrupy snapshot directories are git-tracked
> (do NOT add to `.gitignore`). Snapshots are test contracts and must be
> reviewed in PRs. This is the official syrupy recommendation.

#### .gitignore

`uv init` does not generate a `.gitignore`. Write this file in Phase 3:

```
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
build/
dist/
*.egg-info/
*.egg
.venv/
venv/

# Testing & coverage
.pytest_cache/
.ruff_cache/
.coverage
.coverage.*
htmlcov/
coverage.xml

# Type checkers
.basedpyright/
.mypy_cache/
.pyright/

# IDE
.vscode/
.idea/
*.swp

# OS
.DS_Store
Thumbs.db
```

#### pyrightconfig.json

> The `examples/` directory contains reference code that may not pass
> basedpyright strict mode. Exclude it from type checking:

```json
{
  "exclude": ["examples", ".venv"]
}
```

### § .importlinter Reference

Copy from the template reference and substitute the package name:

```bash
cp /tmp/ref-python/examples/.importlinter .
sed -i "s/my_project/$PKG/g" .importlinter
```

Full content of `examples/.importlinter` (for reference):

```ini
[importlinter]
root_package = my_project

[importlinter:contract:layered-architecture]
name = Layered Architecture
type = layers
layers =
    my_project.routers
    my_project.services
    my_project.repositories

[importlinter:contract:service-purity]
name = Service Layer Purity
type = forbidden
source_modules =
    my_project.services
forbidden_modules =
    sqlalchemy
    fastapi
    httpx
```

> **FastAPI archetype note**: The `layered-architecture` contract enforces
> `routers → services → repositories` import direction.
> The `service-purity` contract prohibits framework imports in the service
> layer so business logic stays framework-agnostic.

### § CI Reference

```yaml
name: Continuous Integration (Fail-Fast)

on:
  push:
    branches: ["main"]
  pull_request:
    branches: ["main"]

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  static-analysis-and-typing:
    name: Lint, Format & Type Checking
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4

      - name: Install uv
        uses: astral-sh/setup-uv@v5
        with:
          enable-cache: true
          cache-dependency-glob: "uv.lock"

      - name: Set up Python environment
        uses: actions/setup-python@v5
        with:
          python-version-file: ".python-version"

      - name: Install dependencies via uv
        run: uv sync --all-extras --dev

      - name: Lint codebase with Ruff
        run: uv run ruff check .

      - name: Check Formatting with Ruff
        run: uv run ruff format --check .

      - name: Type check with basedpyright
        run: uv run basedpyright

  testing:
    name: Unit & Snapshot Tests
    runs-on: ubuntu-latest
    needs: static-analysis-and-typing
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4

      - name: Install uv
        uses: astral-sh/setup-uv@v5
        with:
          enable-cache: true
          cache-dependency-glob: "uv.lock"

      - name: Set up Python environment
        uses: actions/setup-python@v5
        with:
          python-version-file: ".python-version"

      - name: Install dependencies via uv
        run: uv sync --all-extras --dev

      - name: Run Pytest Test Suite
        run: uv run pytest
```

### § CodeRabbit Reference

```yaml
language: "ko-KR"
tone_instructions: "객관적이고 전문적인 시니어 소프트웨어 엔지니어의 톤을 유지하세요. 띄어쓰기나 라인 길이와 같은 사소한 스타일 이슈는 지적하지 말고, 시스템 아키텍처와 논리 결함 탐지에 집중하세요."

path_instructions:
  - path: "src/**/*.py"
    instructions: |
      1. Fail-Fast 원칙 준수 여부: 예외 처리 과정에서 에러를 조용히 넘기지(pass) 않고 명시적으로 발생(raise)시키고 있는지 점검하세요.
      2. 타입 안정성: basedpyright strict 모드에 부합하도록 typing 명시가 누락되었거나 Any 타입이 남용된 곳을 지적하세요.
      3. 런타임 성능 및 부작용: 불필요한 가변 객체의 기본 인자 사용, 비효율적인 순회 루프(Ruff PERF 위반), 데이터프레임 inplace=True 등 구조적 성능 이슈를 점검하세요.
      4. 포매팅(스타일) 무시: 큰따옴표/작은따옴표, 들여쓰기 등은 Ruff 포매터가 통제하므로 리뷰 코멘트로 남기지 마십시오.

  - path: "tests/**/*.py"
    instructions: |
      1. 테스트의 건전성: Syrupy 스냅샷 테스트의 --snapshot-update 남용 여부를 검증하고, 스냅샷 변경의 합리성을 분석하세요.
      2. 엣지 케이스 커버리지: 경계값 조건과 예외 상황 시나리오가 충분히 커버되었는지 점검하세요.

review:
  auto_review: true
  enable_comments: true
  ignore_formatting: true
```

### § Fallback — Claude Code Review Action

```yaml
# Fallback when CodeRabbit is unavailable
name: Claude Code Review

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  claude-review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run Claude Code Review
        uses: anthropics/claude-code-action@beta
        with:
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
```

### § Placeholder Index

All `{{...}}` placeholders in this template (enumerated — NOT a placeholder itself):

| Placeholder | Scope | Filled by | Example |
|---|---|---|---|
| `{{PROJECT_NAME}}` | Phase 0 + Phase 1 | user input at runtime | `my_project` |
