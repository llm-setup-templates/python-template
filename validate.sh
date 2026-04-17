#!/usr/bin/env bash
# Static verification for python-template.
# Mirrors typescript-template and spring-template validate.sh layout.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0
FAIL=0

pass() { echo "PASS [$1] $2"; PASS=$((PASS + 1)); }
fail() { echo "FAIL [$1] $2"; FAIL=$((FAIL + 1)); }

check_absent() {
  local id="$1" desc="$2" file="$3" pattern="$4"
  if [ -f "$file" ] && grep -qE "$pattern" "$file"; then
    fail "$id" "$desc — forbidden pattern found in $file: $pattern"
  else
    pass "$id" "$desc (forbidden pattern absent)"
  fi
}

check_present_eq() {
  local id="$1" desc="$2" actual="$3" expected="$4"
  if [ "$actual" = "$expected" ]; then
    pass "$id" "$desc (got: $actual)"
  else
    fail "$id" "$desc (expected: $expected, got: $actual)"
  fi
}

check_gte() {
  local id="$1" desc="$2" actual="$3" minimum="$4"
  if [ "$actual" -ge "$minimum" ]; then
    pass "$id" "$desc (got: $actual >= $minimum)"
  else
    fail "$id" "$desc (expected >= $minimum, got: $actual)"
  fi
}

echo "=== V1: SETUP.md residual placeholders (excl PROJECT_NAME) ==="
V1_COUNT=$(grep -oE '\{\{[A-Z_]+\}\}' "$ROOT/SETUP.md" | grep -v 'PROJECT_NAME' | wc -l | tr -d ' ')
check_present_eq "V1" "SETUP.md residual placeholders" "$V1_COUNT" "0"

echo ""
echo "=== V2: Required files exist (original set + Phase 5.5 Core) ==="
REQUIRED=(
  SETUP.md CLAUDE.md README.md
  .claude/rules/architecture.md .claude/rules/code-style.md
  .claude/rules/git-workflow.md .claude/rules/test-modification.md
  .claude/rules/verification-loop.md
  .claude/rules/documentation.md
  examples/ci.yml examples/pyproject.toml examples/.pre-commit-config.yaml
  examples/.importlinter examples/.python-version
  .github/ISSUE_TEMPLATE/feature.yml .github/ISSUE_TEMPLATE/bug.yml
  .github/ISSUE_TEMPLATE/adr.yml .github/ISSUE_TEMPLATE/config.yml
  .github/PULL_REQUEST_TEMPLATE.md .github/CODEOWNERS
  .github/workflows/validate.yml
  docs/README.md
  docs/requirements/RTM.md docs/requirements/_FR-template.md
  docs/architecture/overview.md
  docs/architecture/decisions/README.md
  docs/architecture/decisions/_ADR-template.md
  docs/architecture/decisions/_RFC-template.md
)
for f in "${REQUIRED[@]}"; do
  if [ -f "$ROOT/$f" ]; then
    pass "V2" "$f"
  else
    fail "V2" "$f missing"
  fi
done

echo ""
echo "=== V3: ci.yml step order + lint-imports present ==="
V3_CHECKOUT=$(grep -n "actions/checkout@v4" "$ROOT/examples/ci.yml" | head -1 | cut -d: -f1)
V3_LINT_IMPORTS=$(grep -c "lint-imports" "$ROOT/examples/ci.yml" || echo 0)
if [ -n "$V3_CHECKOUT" ]; then
  pass "V3a" "ci.yml has actions/checkout (line $V3_CHECKOUT)"
else
  fail "V3a" "ci.yml missing actions/checkout"
fi
check_gte "V3b" "ci.yml runs uv run lint-imports" "$V3_LINT_IMPORTS" "1"

echo ""
echo "=== V4: regression guards (PR #7 lint-imports wiring) ==="
# SETUP.md must reference lint-imports in Local Verify, Success Criteria,
# and Essential Checklist. CLAUDE.md must reference it too.
V4_SETUP_LI=$(grep -c "lint-imports" "$ROOT/SETUP.md" || echo 0)
V4_CLAUDE_LI=$(grep -c "lint-imports" "$ROOT/CLAUDE.md" || echo 0)
V4_SETUP_DEPS=$(grep -c "import-linter" "$ROOT/SETUP.md" || echo 0)
check_gte "V4a" "SETUP.md references lint-imports (>= 3: Success Criteria + Phase 7 + Checklist)" "$V4_SETUP_LI" "3"
check_gte "V4b" "CLAUDE.md Primary Commands reference lint-imports" "$V4_CLAUDE_LI" "1"
check_gte "V4c" "SETUP.md references import-linter (Phase 2 devDeps + Appendix pyproject)" "$V4_SETUP_DEPS" "2"

echo ""
echo "=== V5: ADR template encodes 5-state lifecycle ==="
V5_STATES=0
for state in Proposed Accepted Rejected Deprecated Superseded; do
  if grep -q "$state" "$ROOT/docs/architecture/decisions/README.md"; then
    V5_STATES=$((V5_STATES + 1))
  fi
done
check_present_eq "V5" "ADR lifecycle states" "$V5_STATES" "5"

echo ""
echo "=== V6: PR template has required discipline sections ==="
V6_REFS=0
for pattern in "FR:" "ADR:" "RTM discipline" "Balancing Rule"; do
  if grep -q "$pattern" "$ROOT/.github/PULL_REQUEST_TEMPLATE.md"; then
    V6_REFS=$((V6_REFS + 1))
  fi
done
check_present_eq "V6" "PR template references (FR / ADR / RTM / Balancing)" "$V6_REFS" "4"

echo ""
echo "=== V7: Reports opt-in module consistency ==="
if [ -d "$ROOT/docs/reports" ]; then
  V7_FILES=0
  for f in README.md _spike-test-template.md _benchmark-template.md _api-analysis-template.md _paar-template.md; do
    if [ -f "$ROOT/docs/reports/$f" ]; then
      V7_FILES=$((V7_FILES + 1))
    fi
  done
  check_present_eq "V7" "Reports module completeness (all 5 files)" "$V7_FILES" "5"
else
  echo "SKIP [V7] Reports module not installed"
fi

echo ""
echo "=== V8: Briefings opt-in module consistency ==="
if [ -d "$ROOT/docs/briefings" ]; then
  V8_FILES=0
  for f in README.md _template/CLAUDE.md _template/README.md _template/slide-outline.md _template/talking-points.md _template/decisions-checklist.md _template/open-questions.md; do
    if [ -f "$ROOT/docs/briefings/$f" ]; then
      V8_FILES=$((V8_FILES + 1))
    fi
  done
  check_present_eq "V8" "Briefings module completeness (all 7 files)" "$V8_FILES" "7"
else
  echo "SKIP [V8] Briefings module not installed"
fi

echo ""
echo "=== V9: Extended opt-in module consistency ==="
V9_PRESENT=0
for f in docs/architecture/containers.md docs/architecture/DFD.md docs/data/dictionary.md; do
  if [ -f "$ROOT/$f" ]; then
    V9_PRESENT=$((V9_PRESENT + 1))
  fi
done
if [ "$V9_PRESENT" = "3" ]; then
  pass "V9" "Extended module installed (3/3)"
elif [ "$V9_PRESENT" = "0" ]; then
  echo "SKIP [V9] Extended module not installed"
else
  fail "V9" "Extended module partial: $V9_PRESENT/3 — must be all or none"
fi

echo ""
echo "======================================="
echo "RESULTS: $PASS passed, $FAIL failed"
echo "======================================="

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
