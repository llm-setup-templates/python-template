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

# F1 4 subfacet acceptance -- see .claude/rules/plan-review-deep.md Section 1
# Each subfacet's verification is the corresponding V/scaffold-e2e block
# below. CI source-greps `echo "=== F1.x ...` to count 4 headers (F1.a-F1.d).
echo "=== F1.a Reproducible Failure ==="
echo "=== F1.b Staged Gate ==="
echo "=== F1.c Immutable Verification ==="
echo "=== F1.d Full-Solution Verification ==="

echo "=== V0a Self-monolithic guard ==="
for spec in "validate.sh:400" "scaffold.sh:395"; do
  f="${spec%%:*}"; limit="${spec##*:}"
  n=$(wc -l < "$f")
  [[ $n -le $limit ]] || { echo "FAIL: V0a $f has $n lines (limit $limit). 14a self-ratchet forbidden -- STOP and open a new review round."; exit 1; }
done
n=$(wc -l < SETUP.md)
[[ $n -le 250 ]] || { echo "FAIL: V0a SETUP.md has $n lines (limit 250)."; exit 1; }
[[ $n -le 220 ]] || echo "WARN: V0a SETUP.md has $n lines (soft 220; hard 250). Action required before next PR merge."

echo "=== V0e Phase 0 schema guard ==="
grep -q '^## Phase 0: System Overview' SETUP.md || { echo "FAIL: V0e Phase 0 header missing"; exit 1; }
grep -q '^```mermaid' SETUP.md || { echo "FAIL: V0e Mermaid block missing"; exit 1; }
for node in clone scaffold verify ci; do
  grep -qE "(^|[^[:alnum:]_-])${node}([^[:alnum:]_-]|$)" SETUP.md || { echo "FAIL: V0e core node ${node} missing"; exit 1; }
done
grep -q 'Change blast radius' SETUP.md || { echo "FAIL: V0e ENV column 'Change blast radius' missing"; exit 1; }
for h in 'Adding a new archetype' 'Adding a new verify step' 'Adding a new env dependency' 'Phase E (DDD/TDD) stack hook'; do
  # NOTE: Use grep -q (BRE) NOT grep -qE -- heading text contains literal `(`, `)`, `/`
  grep -q "^### ${h}" SETUP.md || { echo "FAIL: V0e Extension Points heading '${h}' missing"; exit 1; }
done

echo "=== V_seed Worked example seed ==="
seed=$(find examples/archetype-fastapi/src -name '*.py' -path '*/handlers/*' 2>/dev/null | sort | head -1 || true)
[[ -n "$seed" && -f "$seed" ]] || { echo "FAIL: V_seed missing handlers/*.py"; exit 1; }
grep -qE '^[[:space:]]*(pass|raise NotImplementedError\b.*|\.\.\.)[[:space:]]*$' "$seed" && { echo "FAIL: V_seed stub phrase in $seed"; exit 1; }
[[ $(wc -l < "$seed") -ge 5 ]] || { echo "FAIL: V_seed $seed has < 5 lines"; exit 1; }

echo "=== V1: SETUP.md residual placeholders (only REPO_NAME + VISIBILITY allowed) ==="
# REPO_NAME / VISIBILITY are the two canonical runtime-filled placeholders
# (see SETUP.md § Placeholder Index). Any other {{CAPS}} token is residual.
V1_COUNT=$(grep -oE '\{\{[A-Z_]+\}\}' "$ROOT/SETUP.md" | grep -vE 'REPO_NAME|VISIBILITY' | wc -l | tr -d ' ')
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
echo "=== V4: regression guards (lint-imports wiring in SETUP/CLAUDE + import-linter dep in archetype pyprojects) ==="
# Post-Phase-13: SETUP.md is the scaffold.sh reference guide (not phase-by-phase).
# It must reference lint-imports (the command) in Quick Start + Verification sections.
# CLAUDE.md (template) continues to reference lint-imports in Primary Commands.
# The import-linter PACKAGE dep is enforced in archetype pyproject.toml files
# (since Phase 13 moved pyproject out of SETUP.md Appendix into examples/).
V4_SETUP_LI=$(grep -c "lint-imports" "$ROOT/SETUP.md" || echo 0)
V4_CLAUDE_LI=$(grep -c "lint-imports" "$ROOT/CLAUDE.md" || echo 0)
V4_ARCHETYPE_DEPS=0
for f in \
  examples/archetype-fastapi/pyproject.toml \
  examples/archetype-library/pyproject.toml \
  examples/archetype-data-science/pyproject.toml; do
  if [ -f "$ROOT/$f" ] && grep -q 'import-linter' "$ROOT/$f"; then
    V4_ARCHETYPE_DEPS=$((V4_ARCHETYPE_DEPS + 1))
  fi
done
check_gte "V4a" "SETUP.md references lint-imports (>= 2: Quick Start + Verification)" "$V4_SETUP_LI" "2"
check_gte "V4b" "CLAUDE.md Primary Commands reference lint-imports" "$V4_CLAUDE_LI" "1"
check_present_eq "V4c" "all 3 archetype pyprojects declare import-linter dep" "$V4_ARCHETYPE_DEPS" "3"

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
echo "=== V10: Dependabot config exists (Phase 12 hardening) ==="
V10_PASS=0
for f in .github/dependabot.yml examples/dependabot.yml; do
  if [ -f "$ROOT/$f" ]; then
    pass "V10" "$f"
    V10_PASS=$((V10_PASS + 1))
  else
    fail "V10" "$f missing"
  fi
done

echo ""
echo "=== V11: import-linter contract count (Phase 12 hardening) ==="
V11_COUNT=$(grep -c '^\[importlinter:contract:' "$ROOT/examples/.importlinter" || echo 0)
check_gte "V11" "examples/.importlinter contract count" "$V11_COUNT" "2"

echo ""
echo "=== V12: Multi-archetype config sync (Phase 12 hardening) ==="
# ruff select "W" in both main and scientific pyproject
if grep -q '"W"' "$ROOT/examples/pyproject.toml" && \
   grep -q '"W"' "$ROOT/examples/pyproject.scientific.toml"; then
  pass "V12a" "ruff select 'W' present in main + scientific pyproject"
else
  fail "V12a" "ruff select 'W' must be present in both examples/pyproject.toml AND examples/pyproject.scientific.toml"
fi

# pyright exclude "examples" in main + archetype-fastapi
if grep -qE 'exclude.*examples' "$ROOT/examples/pyproject.toml" && \
   grep -qE 'exclude.*examples' "$ROOT/examples/archetype-fastapi/pyproject.toml"; then
  pass "V12b" "pyright exclude 'examples' present in main + fastapi pyproject"
else
  fail "V12b" "pyright exclude 'examples' must be present in both examples/pyproject.toml AND examples/archetype-fastapi/pyproject.toml"
fi

echo ""
echo "=== V13: scaffold.sh executable + --help ==="
if [ -x "$ROOT/scaffold.sh" ]; then
  pass "V13a" "scaffold.sh is executable"
else
  fail "V13a" "scaffold.sh missing or not executable"
fi
if "$ROOT/scaffold.sh" --help >/dev/null 2>&1; then
  pass "V13b" "scaffold.sh --help exits 0"
else
  fail "V13b" "scaffold.sh --help failed"
fi

echo ""
echo "=== V14: scaffold.sh rejects bad input ==="
if ! "$ROOT/scaffold.sh" --pkg "bad-case" >/dev/null 2>&1; then
  pass "V14a" "scaffold.sh rejects hyphen-case --pkg"
else
  fail "V14a" "scaffold.sh accepted invalid --pkg 'bad-case'"
fi
if ! "$ROOT/scaffold.sh" --pkg "ok" --archetype invalid_type >/dev/null 2>&1; then
  pass "V14b" "scaffold.sh rejects invalid --archetype"
else
  fail "V14b" "scaffold.sh accepted invalid --archetype"
fi
if ! "$ROOT/scaffold.sh" --pkg "ok" --doc-modules "reports" >/dev/null 2>&1; then
  pass "V14c" "scaffold.sh requires 'core' in --doc-modules"
else
  fail "V14c" "scaffold.sh accepted --doc-modules without 'core'"
fi

echo ""
echo "=== V15: test/scaffold-e2e.sh exists + archetype support files ==="
if [ -f "$ROOT/test/scaffold-e2e.sh" ]; then
  pass "V15a" "test/scaffold-e2e.sh present"
else
  fail "V15a" "test/scaffold-e2e.sh missing"
fi
V15_FILES=0
for f in \
  examples/archetype-library/pyproject.toml \
  examples/archetype-library/.importlinter \
  examples/archetype-library/tests/test_smoke.py \
  examples/archetype-data-science/pyproject.toml \
  examples/archetype-data-science/.importlinter \
  examples/.gitignore; do
  if [ -f "$ROOT/$f" ]; then
    V15_FILES=$((V15_FILES + 1))
  else
    fail "V15b" "archetype support file missing: $f"
  fi
done
check_present_eq "V15b" "archetype support files present (6/6)" "$V15_FILES" "6"
# Sanity: library pyproject must NOT include fastapi
if grep -q '"fastapi' "$ROOT/examples/archetype-library/pyproject.toml" 2>/dev/null; then
  fail "V15c" "library archetype pyproject contains 'fastapi' dep (should not)"
else
  pass "V15c" "library archetype pyproject is fastapi-free"
fi
# Sanity: data-science pyproject must include scientific relaxation
if grep -q 'reportUnknownMemberType = false' "$ROOT/examples/archetype-data-science/pyproject.toml" 2>/dev/null; then
  pass "V15d" "data-science archetype has pyright relaxation"
else
  fail "V15d" "data-science archetype missing pyright relaxation"
fi

echo ""
echo "=== V16: scaffold.sh interpreter guard (Fix 8 / e2e24 PowerShell silent-failure) ==="
# STATIC-ONLY check. NEVER invoke scaffold.sh from validate.sh — the template
# directory IS the scaffold target, and an invocation would scaffold it in
# place. Runtime verification of the guard belongs in scaffold-e2e.sh which
# operates in a tmpdir copy.
#
# [M-01 fix] V16a matches the actual `[ -z ... BASH_VERSION ]` test, not just
# the string "BASH_VERSION" anywhere (which would false-pass if the guard was
# removed but a comment retained the word).
# [M-02 fix] V16b uses the same tighter pattern for GUARD_LINE extraction so
# it pins to the real test expression, not a doc comment.
# [M-03 fix in scaffold.sh] The guard checks BASH_VERSION AND $BASH basename.
# V16c asserts both checks are present.
GUARD_RE='\[ -z.*BASH_VERSION'
if grep -qE "$GUARD_RE" "$ROOT/scaffold.sh"; then
  pass "V16a" "scaffold.sh contains [ -z ... BASH_VERSION ] guard"
else
  fail "V16a" "scaffold.sh missing active [ -z ... BASH_VERSION ] guard — silent-success risk"
fi
GUARD_LINE=$(grep -nE "$GUARD_RE" "$ROOT/scaffold.sh" | head -1 | cut -d: -f1)
SET_LINE=$(grep -nE '^set -euo pipefail' "$ROOT/scaffold.sh" | head -1 | cut -d: -f1)
if [ -n "$GUARD_LINE" ] && [ -n "$SET_LINE" ] && [ "$GUARD_LINE" -lt "$SET_LINE" ]; then
  pass "V16b" "BASH_VERSION guard precedes 'set -euo pipefail' (line $GUARD_LINE < $SET_LINE)"
else
  fail "V16b" "BASH_VERSION guard must appear before 'set -euo pipefail' (guard=$GUARD_LINE set=$SET_LINE)"
fi
# V16c: verify the BASH env-injection hardening ($BASH basename check)
if grep -qE '\$\{BASH##\*/\}' "$ROOT/scaffold.sh"; then
  pass "V16c" "scaffold.sh has \$BASH basename check (env-injection hardening)"
else
  fail "V16c" "scaffold.sh missing \$BASH basename check — PowerShell env-injection bypass possible"
fi

echo ""
echo "======================================="
echo "RESULTS: $PASS passed, $FAIL failed"
echo "======================================="

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
