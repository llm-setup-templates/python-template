#!/usr/bin/env bash
# E2E test for scaffold.sh. Usage: bash test/scaffold-e2e.sh [archetype]
#
# Copies the template to a temp dir (portable cp -r, no rsync), runs
# scaffold.sh with the given archetype, then verifies post-conditions.
# When uv is available, runs the full uv sync + ruff + basedpyright +
# lint-imports + pytest lifecycle to guard against scaffolded-output
# regressions.
set -euo pipefail

ARCHETYPE="${1:-fastapi}"
case "$ARCHETYPE" in
  fastapi|library|data-science) ;;
  *) echo "[e2e] invalid archetype: $ARCHETYPE (use fastapi|library|data-science)" >&2; exit 1 ;;
esac

TEMPLATE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMPDIR="$(mktemp -d -t scaffold-e2e-XXXXXX)"
trap 'rm -rf "$TMPDIR"' EXIT

echo "[e2e] template  : $TEMPLATE_ROOT"
echo "[e2e] tmpdir    : $TMPDIR"
echo "[e2e] archetype : $ARCHETYPE"

# 1. Copy template WITHOUT .git and test/ (portable, no rsync dependency)
DERIVED="$TMPDIR/my-test-app"
mkdir -p "$DERIVED"
cp -a "$TEMPLATE_ROOT/." "$DERIVED/"
rm -rf "$DERIVED/.git" "$DERIVED/test"

cd "$DERIVED"

# 2a. Runtime guard check: scaffold.sh must refuse non-bash invocation.
# We verify by spawning a fresh process WITHOUT BASH_VERSION in the env.
# `env -u BASH_VERSION bash` still re-sets BASH_VERSION on startup, so we
# use dash if available (POSIX, no BASH_VERSION). If dash is absent (common
# on Windows Git Bash), SKIP this sub-check — CI Linux always has dash.
if command -v dash >/dev/null 2>&1; then
  if dash scaffold.sh --pkg dummy_pkg --archetype fastapi >/dev/null 2>&1; then
    echo "FAIL: scaffold.sh ran under dash without BASH_VERSION — guard ineffective"
    exit 1
  fi
  # Confirm the script is still intact (guard exited cleanly, didn't partially scaffold)
  test -f validate.sh || { echo "FAIL: dash invocation partially scaffolded (validate.sh gone)"; exit 1; }
  test -f scaffold.sh || { echo "FAIL: dash invocation removed scaffold.sh"; exit 1; }
  echo "[e2e] runtime guard PASS — dash invocation rejected, template unchanged"
else
  echo "[e2e] dash not available — skipping runtime guard check (covered by V16 static + CI Linux)"
fi

# 2b. Run scaffold.sh (real)
bash scaffold.sh --pkg my_test_app --archetype "$ARCHETYPE"

# 3. Verify post-conditions
test -f pyproject.toml           || { echo "FAIL: pyproject.toml missing"; exit 1; }
grep -q '^name = "my_test_app"' pyproject.toml || { echo "FAIL: pyproject name not substituted"; exit 1; }
test -d "src/my_test_app"        || { echo "FAIL: src/my_test_app dir missing"; exit 1; }
test -d tests                    || { echo "FAIL: tests/ missing"; exit 1; }
test -f .importlinter            || { echo "FAIL: .importlinter missing"; exit 1; }
test -f .python-version          || { echo "FAIL: .python-version missing"; exit 1; }
test -f .gitignore               || { echo "FAIL: .gitignore missing"; exit 1; }
test -f .pre-commit-config.yaml  || { echo "FAIL: .pre-commit-config.yaml missing"; exit 1; }
test -f .github/workflows/ci.yml || { echo "FAIL: ci.yml missing"; exit 1; }

# Template-only files must be gone
test ! -f validate.sh                   || { echo "FAIL: validate.sh leaked"; exit 1; }
test ! -f .github/workflows/validate.yml || { echo "FAIL: validate.yml leaked"; exit 1; }
test ! -f .github/dependabot.yml        || { echo "FAIL: dependabot.yml leaked"; exit 1; }
test ! -d examples                       || { echo "FAIL: examples/ not removed"; exit 1; }
test ! -d "test"                         || { echo "FAIL: test/ dir leaked"; exit 1; }
# scaffold.sh self-delete: required on Linux (CI). On Windows it warns + continues.
if [[ "$(uname -s)" == Linux* || "$(uname -s)" == Darwin* ]]; then
  test ! -f scaffold.sh || { echo "FAIL: scaffold.sh not self-removed on Unix"; exit 1; }
fi

# .claude/ must be preserved (derived repo agent rules)
test -d .claude/rules || { echo "FAIL: .claude/rules/ missing"; exit 1; }
test -f .claude/rules/documentation.md || { echo "FAIL: .claude/rules/documentation.md missing"; exit 1; }

# Archetype-specific checks
case "$ARCHETYPE" in
  fastapi)
    grep -q '"fastapi' pyproject.toml     || { echo "FAIL: fastapi archetype missing fastapi dep"; exit 1; }
    test -d "src/my_test_app/routers"     || { echo "FAIL: fastapi archetype missing routers/"; exit 1; }
    test -d "src/my_test_app/services"    || { echo "FAIL: fastapi archetype missing services/"; exit 1; }
    grep -q 'layered-architecture' .importlinter || { echo "FAIL: fastapi archetype missing layered-architecture contract"; exit 1; }
    ;;
  library)
    if grep -q '"fastapi' pyproject.toml; then echo "FAIL: library archetype must NOT include fastapi dep"; exit 1; fi
    test -f "src/my_test_app/cli.py"      || { echo "FAIL: library archetype missing cli.py"; exit 1; }
    test -f "src/my_test_app/core.py"     || { echo "FAIL: library archetype missing core.py"; exit 1; }
    test -f "tests/test_smoke.py"         || { echo "FAIL: library archetype missing smoke test"; exit 1; }
    grep -q 'core-purity' .importlinter   || { echo "FAIL: library archetype missing core-purity contract"; exit 1; }
    ;;
  data-science)
    grep -qE 'numpy|pandas|scipy' pyproject.toml || { echo "FAIL: data-science archetype missing scientific deps"; exit 1; }
    grep -q 'reportUnknownMemberType = false' pyproject.toml || { echo "FAIL: data-science pyright relaxation missing"; exit 1; }
    test -f "src/my_test_app/pipeline.py" || { echo "FAIL: data-science archetype missing pipeline.py"; exit 1; }
    grep -q 'pipeline-isolation' .importlinter || { echo "FAIL: data-science archetype missing pipeline-isolation contract"; exit 1; }
    ;;
esac

# CLAUDE.md {{REPO_NAME}} substitution
if ! grep -q '^# my-test-app' CLAUDE.md; then
  echo "FAIL: CLAUDE.md {{REPO_NAME}} not substituted (expected '# my-test-app')"
  exit 1
fi
if grep -q '{{REPO_NAME}}' CLAUDE.md; then
  echo "FAIL: CLAUDE.md still contains {{REPO_NAME}} placeholder"
  exit 1
fi

echo "[e2e] structural checks PASS"

# 4. uv lifecycle (if uv available)
if command -v uv >/dev/null 2>&1; then
  echo "[e2e] running uv sync + full verify loop..."
  uv sync --all-extras --dev
  uv run ruff check .
  uv run ruff format --check .
  uv run basedpyright
  uv run lint-imports
  uv run pytest
  echo "[e2e] uv lifecycle PASS"
else
  echo "[e2e] uv not installed — structural checks only. Install: curl -LsSf https://astral.sh/uv/install.sh | sh"
fi

echo "[e2e] PASS: $ARCHETYPE"
