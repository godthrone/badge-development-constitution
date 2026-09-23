#!/usr/bin/env bash
# check_pydantic.sh — Verify pydantic model conventions per §9.1
# Part of BADGE Constitution §9.1
#
# Checks for:
#   - Pydantic BaseModel subclasses missing extra="forbid"
#   - Bare dict/list usage in function signatures (heuristic)
#   - Nested dict patterns (dict of dicts anti-pattern)
#
# Usage: ./check_pydantic.sh [project_root]

set -euo pipefail

PROJECT_ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || echo '.')}"
cd "$PROJECT_ROOT"

FAIL=0

if ! git rev-parse --git-dir &>/dev/null 2>&1; then
    echo "[SKIP] check_pydantic: Not a git repository."
    exit 0
fi

PY_FILES=$(git ls-files --cached --others --exclude-standard 2>/dev/null | \
    grep '\.py$' | grep -v '__pycache__/' | grep -v '\.egg-info/' | \
    grep -v 'badge-development-constitution/' | grep -v 'tests/' || true)

if [ -z "$PY_FILES" ]; then
    echo "[PASS] check_pydantic: No Python source files to check."
    exit 0
fi

echo "Checking pydantic model conventions..."

# ─── 1. BaseModel subclasses missing extra="forbid" ─────────────────────

# Find files that define pydantic models (inherit from BaseModel) and require
# extra="forbid" (§7.2 C:382, §9.1 C:544-546) *within each model's own body*.
# A file-level match must not short-circuit the whole file — a file may define
# several models and only some of them carry extra="forbid".
while IFS= read -r file; do
    [ -z "$file" ] && continue
    if [ ! -f "$file" ]; then continue; fi

    # Check if file uses BaseModel
    if ! grep -q 'BaseModel' "$file" 2>/dev/null; then
        continue
    fi

    # Class definitions that directly inherit BaseModel (top-level classes only,
    # so a nested `class Config:` is not mistaken for a class boundary)
    CLASS_LINES=$(grep -nE '^class[[:space:]]+[A-Za-z_][A-Za-z0-9_]*\(.*\bBaseModel\b' "$file" 2>/dev/null | cut -d: -f1 || true)
    [ -n "$CLASS_LINES" ] || continue

    TOTAL_LINES_FILE=$(wc -l < "$file")
    for class_line in $CLASS_LINES; do
        # Body = class line up to the line before the next top-level class definition
        next_class=$(grep -nE '^class[[:space:]]' "$file" 2>/dev/null | cut -d: -f1 | \
            awk -v c="$class_line" '$1 > c { print; exit }')
        if [ -n "$next_class" ]; then
            class_end=$((next_class - 1))
        else
            class_end=$TOTAL_LINES_FILE
        fi

        CLASS_BODY=$(sed -n "${class_line},${class_end}p" "$file" 2>/dev/null || true)
        CLASS_NAME=$(sed -n "${class_line}p" "$file" 2>/dev/null | \
            sed -E 's/^[[:space:]]*class[[:space:]]+([A-Za-z_][A-Za-z0-9_]*).*/\1/' || true)

        if ! printf '%s\n' "$CLASS_BODY" | grep -qE 'extra\s*=\s*["'"'"']forbid["'"'"']' 2>/dev/null; then
            echo "[FAIL] check_pydantic: BaseModel subclass missing extra=\"forbid\": $file:$class_line ($CLASS_NAME)"
            FAIL=1
        fi
    done
done <<< "$PY_FILES"

# ─── 2. Detect type annotations that are bare dict/list ─────────────────

# Function parameters typed as plain dict or list (not Dict[str, Any], dict[str, int], etc.)
BARE_DICT_PARAMS=$(echo "$PY_FILES" | xargs grep -nE 'def \w+\([^)]*:\s*(dict|list)\s*[,\)]' 2>/dev/null | \
    grep -v '^\s*#' | grep -v 'badge-development-constitution/' || true)

if [ -n "$BARE_DICT_PARAMS" ]; then
    echo "[WARN] Function parameters typed as bare dict/list (should specify key/value types):"
    echo "$BARE_DICT_PARAMS" | while IFS= read -r line; do
        echo "  $line"
    done
fi

# Return types that are bare dict/list
BARE_DICT_RETURNS=$(echo "$PY_FILES" | xargs grep -nE '\)\s*->\s*(dict|list)\s*:' 2>/dev/null | \
    grep -v '^\s*#' | grep -v 'badge-development-constitution/' || true)

if [ -n "$BARE_DICT_RETURNS" ]; then
    echo "[WARN] Return types as bare dict/list (should specify key/value types):"
    echo "$BARE_DICT_RETURNS" | while IFS= read -r line; do
        echo "  $line"
    done
fi

# ─── 3. Nested dict patterns (dict of dicts anti-pattern) ───────────────

NESTED_DICT=$(echo "$PY_FILES" | xargs grep -nE '(Dict|dict)\[str,\s*(Dict|dict)\[' 2>/dev/null | \
    grep -v 'badge-development-constitution/' || true)

if [ -n "$NESTED_DICT" ]; then
    echo "[WARN] Nested dict types found (dict of dicts is an anti-pattern per §9.1):"
    echo "$NESTED_DICT" | while IFS= read -r line; do
        echo "  $line"
    done
    echo "         Use nested pydantic models instead."
fi

echo ""
if [ $FAIL -eq 0 ]; then
    echo "[PASS] check_pydantic: Pydantic conventions are followed."
else
    echo "[FAIL] check_pydantic: Issues found."
fi
exit $FAIL
