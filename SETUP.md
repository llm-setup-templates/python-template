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
- [ ] Local `uv run ruff check . && uv run ruff format --check . && uv run basedpyright && uv run pytest` passes from a fresh clone

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

```bash
uv init {{PROJECT_NAME}} --package --python 3.13
cd {{PROJECT_NAME}}
```

## 5. Phase 2 — DevDeps Installation

```bash
# Choose ONE archetype block:

# [FastAPI Service — default]
uv add fastapi uvicorn pydantic

# [Library / CLI]
uv add typer rich

# [Data-science]
uv add numpy pandas scipy

# All archetypes: dev dependencies
uv add --dev ruff basedpyright ty pytest pytest-cov syrupy pre-commit
```

## 6. Phase 3 — Config Files

Write the following config files (exact content in Appendix § Config Reference):

- pyproject.toml
- .python-version
- .pre-commit-config.yaml
- .coderabbit.yaml

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

## 9. Phase 6 — CodeRabbit Setup

1. Write `.coderabbit.yaml` (exact content in Appendix § CodeRabbit Reference).
2. Install CodeRabbit GitHub App: https://github.com/apps/coderabbitai
3. If CodeRabbit trial is unavailable, fall back to the Claude Code Review
   Action (Appendix § Fallback).

## 10. Phase 7 — Local Verify (fail-fast)

```bash
uv run ruff check . && uv run ruff format --check . && uv run basedpyright && uv run pytest
```

All checks must pass before Phase 8.

> **syrupy first run**: If snapshot files don't exist yet, run
> `uv run pytest --snapshot-update` once, then re-run without `--snapshot-update`.
>
> **Data-science archetype**: Do NOT use syrupy for floating-point tests.
> Use `numpy.testing.assert_allclose` with explicit tolerances in `tests/regression/`.

## 11. Phase 8 — First Push + CI Green

### 11.1 Git Safety Gate (MANDATORY — run before push)

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

### 11.2 Push + watch CI

```bash
git push -u origin $(git rev-parse --abbrev-ref HEAD)
gh run watch
```

### 11.3 Success Declaration

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
- [ ] `uv run ruff check . && uv run ruff format --check . && uv run basedpyright && uv run pytest` passes locally
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

### § Config File Contents

#### pyproject.toml

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
]

[tool.ruff]
target-version = "py313"
line-length = 88
src = ["src", "tests"]

[tool.ruff.lint]
select = ["E", "W", "F", "I", "UP", "B", "S", "PERF", "PD", "NPY", "RUF"]
ignore = ["E501"]

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
