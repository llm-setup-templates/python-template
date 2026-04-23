#!/usr/bin/env bash
# scaffold.sh — Convert a freshly-cloned python-template into a project-specific scaffold.
#
# Usage:
#   ./scaffold.sh --pkg <snake_case> [--archetype fastapi|library|data-science] \
#                 [--doc-modules core[,reports,briefings,extended]] [--dry-run]
#
# This script is single-use. It must be run on a freshly cloned template
# (detected via presence of validate.sh). After execution, it self-deletes.
#
# See ADR-002 for architecture rationale.
set -euo pipefail

# ────────────────────────────────────────────────────────────────
# parse_args
# ────────────────────────────────────────────────────────────────
PKG=""
ARCHETYPE="fastapi"
DOC_MODULES="core"
DRY_RUN=0

usage() {
  cat <<EOF
Usage: $0 --pkg <snake_case> [options]

Required:
  --pkg <name>           Python package name (snake_case, e.g. my_app)

Optional:
  --archetype <type>     fastapi (default) | library | data-science
  --doc-modules <list>   comma-separated from {core,reports,briefings,extended}
                         default: core. 'core' is mandatory.
  --dry-run              Print planned actions without writing.
  -h, --help             This message.

Examples:
  ./scaffold.sh --pkg my_app
  ./scaffold.sh --pkg my_app --archetype library
  ./scaffold.sh --pkg research_pipeline --archetype data-science --doc-modules core,reports
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --pkg)          PKG="$2"; shift 2 ;;
    --archetype)    ARCHETYPE="$2"; shift 2 ;;
    --doc-modules)  DOC_MODULES="$2"; shift 2 ;;
    --dry-run)      DRY_RUN=1; shift ;;
    -h|--help)      usage; exit 0 ;;
    *)              echo "ERROR: unknown arg: $1" >&2; usage >&2; exit 1 ;;
  esac
done

# ────────────────────────────────────────────────────────────────
# validate args
# ────────────────────────────────────────────────────────────────
if [[ -z "$PKG" ]]; then
  echo "ERROR: --pkg is required" >&2
  usage >&2
  exit 1
fi

if ! [[ "$PKG" =~ ^[a-z][a-z0-9_]*$ ]]; then
  echo "ERROR: --pkg must be snake_case (lowercase, starts with letter, letters/digits/underscores)" >&2
  echo "       got: '$PKG'" >&2
  exit 1
fi

case "$ARCHETYPE" in
  fastapi|library|data-science) ;;
  *) echo "ERROR: --archetype must be one of: fastapi, library, data-science (got '$ARCHETYPE')" >&2; exit 1 ;;
esac

# doc-modules: must include 'core'; each item must be in {core,reports,briefings,extended}
if [[ ",$DOC_MODULES," != *",core,"* ]]; then
  echo "ERROR: --doc-modules must include 'core' (got '$DOC_MODULES')" >&2
  exit 1
fi
IFS=',' read -ra DOC_MODS_ARR <<<"$DOC_MODULES"
for m in "${DOC_MODS_ARR[@]}"; do
  case "$m" in
    core|reports|briefings|extended) ;;
    *) echo "ERROR: unknown doc module '$m' (valid: core,reports,briefings,extended)" >&2; exit 1 ;;
  esac
done

# ────────────────────────────────────────────────────────────────
# freshness check [C-03 fix] — validate.sh is template-only; its presence
# is the reliable marker that scaffold.sh has not yet run.
# ────────────────────────────────────────────────────────────────
if [[ ! -f validate.sh ]]; then
  echo "ERROR: validate.sh not found — this doesn't look like a freshly-cloned template." >&2
  echo "       scaffold.sh is single-use. Re-clone the template to start over:" >&2
  echo "         git clone https://github.com/llm-setup-templates/python-template <new-dir>" >&2
  exit 1
fi

REPO_NAME="$(basename "$PWD")"

# ────────────────────────────────────────────────────────────────
# plan summary
# ────────────────────────────────────────────────────────────────
echo "==============================================="
echo " scaffold.sh — python-template"
echo "==============================================="
echo " REPO_NAME     : $REPO_NAME"
echo " PACKAGE (PKG) : $PKG"
echo " ARCHETYPE     : $ARCHETYPE"
echo " DOC_MODULES   : $DOC_MODULES"
echo " DRY_RUN       : $DRY_RUN"
echo "==============================================="
if [[ $DRY_RUN -eq 1 ]]; then
  echo " (dry-run: no files will be modified)"
fi
echo ""

# ────────────────────────────────────────────────────────────────
# helper: execute-or-echo (dry-run aware)
# ────────────────────────────────────────────────────────────────
run() {
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "  [dry-run] $*"
  else
    "$@"
  fi
}

run_eval() {
  # For commands needing shell expansion (globs, redirects)
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "  [dry-run] $*"
  else
    eval "$*"
  fi
}

substitute() {
  # Portable in-place substitution (GNU sed + BSD sed compatible).
  # Usage: substitute <pattern> <replacement> <file>
  local pattern="$1" replacement="$2" file="$3"
  if [[ ! -f "$file" ]]; then
    echo "  WARN: substitute skip (file not found): $file"
    return 0
  fi
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "  [dry-run] substitute '$pattern' -> '$replacement' in $file"
  else
    sed "s|$pattern|$replacement|g" "$file" > "$file.tmp" && mv "$file.tmp" "$file"
  fi
}

# ────────────────────────────────────────────────────────────────
# Stage A — remove template-only files
#   [C-02 fix] scaffold.sh is NOT in this list (self-deletes in Stage H).
# ────────────────────────────────────────────────────────────────
echo "[Stage A] Remove template-only files"
TEMPLATE_ONLY=(
  validate.sh
  .github/workflows/validate.yml
  .github/dependabot.yml
  examples/dependabot.yml
  test
  RATIONALE.md
  docs/architecture/decisions/ADR-002-clone-script-scaffolding.md
  # .claude/ : KEEP — derived repo reuses these agent rules
  # examples/ : KEEP until Stage F (Stage B reads from it)
  # scaffold.sh : self-delete in Stage H
)
for f in "${TEMPLATE_ONLY[@]}"; do
  if [[ -e "$f" ]]; then
    run rm -rf "$f"
  fi
done

# ────────────────────────────────────────────────────────────────
# Stage B — select archetype sources
# ────────────────────────────────────────────────────────────────
echo "[Stage B] Select archetype: $ARCHETYPE"
ARCHE_DIR="examples/archetype-$ARCHETYPE"

PYPROJ_SRC="$ARCHE_DIR/pyproject.toml"
IMPORT_LINTER_SRC="$ARCHE_DIR/.importlinter"
SRC_DIR="$ARCHE_DIR/src"
TESTS_DIR="$ARCHE_DIR/tests"

# FastAPI archetype falls back to examples/.importlinter (layered-architecture contract)
if [[ "$ARCHETYPE" == "fastapi" ]]; then
  IMPORT_LINTER_SRC="examples/.importlinter"
fi

for required in "$PYPROJ_SRC" "$IMPORT_LINTER_SRC" "$SRC_DIR" "$TESTS_DIR"; do
  if [[ ! -e "$required" ]]; then
    echo "ERROR: archetype asset missing: $required" >&2
    echo "       Template may be corrupted. Re-clone." >&2
    exit 1
  fi
done

# ────────────────────────────────────────────────────────────────
# Stage C — copy chosen archetype to root
# ────────────────────────────────────────────────────────────────
echo "[Stage C] Copy archetype files to repo root"
run mkdir -p src tests .github/workflows

run cp "$PYPROJ_SRC" pyproject.toml
run cp "$IMPORT_LINTER_SRC" .importlinter
run cp examples/ci.yml .github/workflows/ci.yml
run cp examples/.pre-commit-config.yaml .pre-commit-config.yaml
run cp examples/.python-version .python-version
run cp examples/.gitignore .gitignore

# Copy archetype source tree — $SRC_DIR contains my_project/ dir; copy its contents into src/
run_eval "cp -r \"$SRC_DIR\"/* src/"
run_eval "cp -r \"$TESTS_DIR\"/* tests/"

# ────────────────────────────────────────────────────────────────
# Stage D — substitute placeholders
# ────────────────────────────────────────────────────────────────
echo "[Stage D] Substitute placeholders"

# pyproject.toml: my_project -> $PKG
substitute 'my_project' "$PKG" pyproject.toml
substitute 'my_project' "$PKG" .importlinter

# CLAUDE.md: {{REPO_NAME}} -> basename
substitute '{{REPO_NAME}}' "$REPO_NAME" CLAUDE.md

# Rename src/my_project -> src/$PKG
if [[ $DRY_RUN -eq 0 && "$PKG" != "my_project" ]]; then
  if [[ -d "src/my_project" ]]; then
    mv "src/my_project" "src/$PKG"
  fi
  # Also substitute inside source files (absolute imports like `from my_project.core import ...`)
  if [[ -d "src/$PKG" ]]; then
    find "src/$PKG" -type f -name '*.py' -print0 | while IFS= read -r -d '' f; do
      sed "s|my_project|$PKG|g" "$f" > "$f.tmp" && mv "$f.tmp" "$f"
    done
  fi
  if [[ -d "tests" ]]; then
    find "tests" -type f -name '*.py' -print0 | while IFS= read -r -d '' f; do
      sed "s|my_project|$PKG|g" "$f" > "$f.tmp" && mv "$f.tmp" "$f"
    done
  fi
else
  [[ $DRY_RUN -eq 1 ]] && echo "  [dry-run] rename src/my_project -> src/$PKG + sed imports"
fi

# ────────────────────────────────────────────────────────────────
# Stage E — trim unselected doc modules
# ────────────────────────────────────────────────────────────────
echo "[Stage E] Trim doc modules (kept: $DOC_MODULES)"

has_module() {
  [[ ",$DOC_MODULES," == *",$1,"* ]]
}

if ! has_module "reports"; then
  run rm -rf docs/reports
fi
if ! has_module "briefings"; then
  run rm -rf docs/briefings
fi
if ! has_module "extended"; then
  run rm -f docs/architecture/containers.md docs/architecture/DFD.md
  run rm -rf docs/data
fi

# ────────────────────────────────────────────────────────────────
# Stage F — remove examples/ (no longer needed in derived repo)
# ────────────────────────────────────────────────────────────────
echo "[Stage F] Remove examples/ (source templates)"
run rm -rf examples

# ────────────────────────────────────────────────────────────────
# Stage G — reinit git
# ────────────────────────────────────────────────────────────────
echo "[Stage G] Reinit git (fresh history)"
run rm -rf .git
run git init -b main

# ────────────────────────────────────────────────────────────────
# Stage H — report + self-delete
# ────────────────────────────────────────────────────────────────
echo ""
echo "==============================================="
echo " ✓ scaffold complete"
echo "==============================================="
cat <<EOF

Next steps:
  1) Install deps + verify:
       uv sync --all-extras --dev
       uv run ruff check . && uv run ruff format --check . \\
         && uv run basedpyright && uv run lint-imports && uv run pytest
  2) Commit the scaffold:
       git add .
       git commit -m "feat(scaffold): initial project setup"
  3) (Optional) Publish to GitHub:
       gh auth status
       gh repo create $REPO_NAME --private --source=. --remote=origin
       git push -u origin main
     If 'git push' does not trigger CI, trigger manually:
       gh workflow run ci.yml --ref main

⚠ TODO: edit .github/CODEOWNERS — replace every @YOUR_ORG/engineering /
  @YOUR_ORG/architects / @YOUR_ORG/devops placeholder with real team handles
  before enabling branch protection reviews.

EOF

# Self-delete scaffold.sh [C-02].
# On Linux/macOS the inode is preserved until the process closes, so rm -- "$0"
# succeeds from within the running script. On Windows Git Bash the file is locked;
# we emit a warning and ask the user to delete it manually.
if [[ $DRY_RUN -eq 0 ]]; then
  if rm -- "$0" 2>/dev/null; then
    :
  else
    echo "⚠ Could not auto-remove scaffold.sh (likely Windows file lock)."
    echo "  Delete manually: rm scaffold.sh"
  fi
fi

exit 0
