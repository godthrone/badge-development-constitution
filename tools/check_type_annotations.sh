#!/usr/bin/env bash
# check_type_annotations.sh — Verify type annotation conventions per §12.1
# Part of BADGE Constitution §12.1
#
# Checks for:
#   - `Optional[str]` usage (should be `str | None`)
#   - `Union[...]` usage (should use `|` syntax in Python 3.11+)
#   - `py.typed` marker file existence
#   - `Dict[...]`, `List[...]`, `Tuple[...]` (should use built-in generics)
#
# Usage: ./check_type_annotations.sh [project_root]

set -euo pipefail

PROJECT_ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || echo '.')}"
cd "$PROJECT_ROOT"

FAIL=0

if ! git rev-parse --git-dir &>/dev/null 2>&1; then
    echo "[SKIP] check_type_annotations: Not a git repository."
    exit 0
fi

PY_FILES=$(git ls-files --cached --others --exclude-standard 2>/dev/null | \
    grep '\.py$' | grep -v '__pycache__/' | grep -v '\.egg-info/' | \
    grep -v 'badge-development-constitution/' || true)

if [ -z "$PY_FILES" ]; then
    echo "[PASS] check_type_annotations: No Python files to check."
    exit 0
fi

echo "Checking type annotation conventions..."

# ─── 1. Optional[str] → should be str | None ────────────────────────────

OPTIONAL_USAGE=$(echo "$PY_FILES" | xargs grep -nE 'Optional\[[a-zA-Z]' 2>/dev/null | \
    grep -v '^\s*#' | grep -v 'badge-development-constitution/' | \
    grep -v 'check_type_annotations\.sh' || true)

if [ -n "$OPTIONAL_USAGE" ]; then
    echo "[FAIL] check_type_annotations: Optional[X] found (use X | None per §12.1):"
    echo "$OPTIONAL_USAGE" | while IFS= read -r line; do
        echo "  $line"
    done
    FAIL=1
fi

# ─── 2. Union[X, Y] → should use X | Y syntax ──────────────────────────

UNION_USAGE=$(echo "$PY_FILES" | xargs grep -nE 'Union\[[a-zA-Z]' 2>/dev/null | \
    grep -v '^\s*#' | grep -v 'badge-development-constitution/' || true)

if [ -n "$UNION_USAGE" ]; then
    echo "[FAIL] check_type_annotations: Union[X, Y] found (use X | Y per §12.1):"
    echo "$UNION_USAGE" | while IFS= read -r line; do
        echo "  $line"
    done
    FAIL=1
fi

# ─── 3. Dict[...], List[...], Tuple[...] → use dict, list, tuple ────────

OLD_GENERICS=$(echo "$PY_FILES" | xargs grep -nE '\b(Dict|List|Tuple|Set|FrozenSet)\[' 2>/dev/null | \
    grep -v '^\s*#' | grep -v 'typing' | grep -v 'badge-development-constitution/' || true)

if [ -n "$OLD_GENERICS" ]; then
    echo "[WARN] Old-style generics found (Dict, List, Tuple, Set)."
    echo "       In Python 3.11+, use built-in generics: dict[X, Y], list[X], tuple[X, ...]"
    echo "$OLD_GENERICS" | head -20 | while IFS= read -r line; do
        echo "  $line"
    done
fi

# ─── 4. py.typed marker ─────────────────────────────────────────────────

# Find the package directory under src/
PY_TYPED=""
if [ -d "$PROJECT_ROOT/src" ]; then
    PY_TYPED=$(find "$PROJECT_ROOT/src" -name 'py.typed' -not -path '*.egg-info/*' 2>/dev/null | head -1 || true)
fi

if [ -n "$PY_TYPED" ]; then
    echo "  [OK] py.typed marker found: ${PY_TYPED#$PROJECT_ROOT/}"
else
    if [ -d "$PROJECT_ROOT/src" ]; then
        echo "  [FAIL] py.typed marker missing (PEP 561, required by §12.1)."
        echo "         Create an empty py.typed file in your package directory."
        FAIL=1
    else
        echo "  [INFO] No src/ directory — py.typed check skipped."
    fi
fi

echo ""
if [ $FAIL -eq 0 ]; then
    echo "[PASS] check_type_annotations: Type annotation conventions are followed."
else
    echo "[FAIL] check_type_annotations: Issues found."
fi
exit $FAIL
