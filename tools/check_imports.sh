#!/usr/bin/env bash
# check_imports.sh — Detect forbidden relative imports per §8.6
# Part of BADGE Constitution §8.6
#
# Checks for:
#   - Relative imports: `from . import`, `from .. import`
#   - Files importing from sibling packages via relative paths
#
# Usage: ./check_imports.sh [project_root]

set -euo pipefail

PROJECT_ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || echo '.')}"
cd "$PROJECT_ROOT"

FAIL=0

if ! git rev-parse --git-dir &>/dev/null 2>&1; then
    echo "[SKIP] check_imports: Not a git repository."
    exit 0
fi

PY_FILES=$(git ls-files --cached --others --exclude-standard 2>/dev/null | \
    grep '\.py$' | grep -v '__pycache__/' | grep -v '\.egg-info/' | \
    grep -v '__init__\.py' | \
    grep -v 'badge-development-constitution/' || true)

if [ -z "$PY_FILES" ]; then
    echo "[PASS] check_imports: No Python files to check."
    exit 0
fi

echo "Checking for relative imports..."

# ─── 1. Detect relative imports ──────────────────────────────────────────

# Find `from .` and `from ..` imports (excluding comments)
REL_IMPORTS=$(echo "$PY_FILES" | xargs grep -nE '^\s*from\s+\.' 2>/dev/null || true)

if [ -n "$REL_IMPORTS" ]; then
    echo "[FAIL] check_imports: Relative imports found (use absolute imports per §8.6):"
    echo "$REL_IMPORTS" | while IFS= read -r line; do
        echo "  $line"
    done
    FAIL=1
fi

# ─── 2. Detect `import .` pattern (less common) ─────────────────────────

DOT_IMPORTS=$(echo "$PY_FILES" | xargs grep -nE '^\s*import\s+\.' 2>/dev/null || true)

if [ -n "$DOT_IMPORTS" ]; then
    echo "[FAIL] check_imports: Dot imports found (use absolute imports per §8.6):"
    echo "$DOT_IMPORTS" | while IFS= read -r line; do
        echo "  $line"
    done
    FAIL=1
fi

echo ""
if [ $FAIL -eq 0 ]; then
    echo "[PASS] check_imports: All imports are absolute."
else
    echo "[FAIL] check_imports: Relative imports found."
fi
exit $FAIL
