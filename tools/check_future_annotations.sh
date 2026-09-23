#!/usr/bin/env bash
# check_future_annotations.sh — Warn on unnecessary `from __future__ import
# annotations` in Python source files (§8.6).
#
# §8.6: "from __future__ import annotations (PEP 563) is used only when
# circular imports prevent type annotations from being evaluated, not
# required in every file."
#
# Heuristic: if a file has the import but NO forward-reference annotations
# (string annotations like "ClassName", TYPE_CHECKING guard), flag it.
# This is warn-only — exit code is always 0.
#
# Usage: ./check_future_annotations.sh [project_root]

set -euo pipefail

PROJECT_ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || echo '.')}"
cd "$PROJECT_ROOT"

# ─── Collect Python source files ──────────────────────────────────────────

if ! git rev-parse --git-dir &>/dev/null 2>&1; then
    echo "[SKIP] check_future_annotations: Not a git repository."
    exit 0
fi

PY_FILES=$(git ls-files --cached --others --exclude-standard 2>/dev/null | \
    grep '\.py$' | \
    grep -v '__pycache__/' | \
    grep -v '\.egg-info/' || true)

if [ -z "$PY_FILES" ]; then
    echo "[PASS] check_future_annotations: No Python files to check."
    exit 0
fi

# ─── Find files with from __future__ import annotations ───────────────────

FILES_WITH_FUTURE=$(echo "$PY_FILES" | xargs grep -l -- 'from __future__ import annotations' || true)

if [ -z "$FILES_WITH_FUTURE" ]; then
    echo "[PASS] check_future_annotations: No files use from __future__ import annotations."
    exit 0
fi

WARN_COUNT=0
TOTAL_COUNT=$(echo "$FILES_WITH_FUTURE" | grep -c '.' || echo 0)

echo "Checking $TOTAL_COUNT file(s) with 'from __future__ import annotations'..."

while IFS= read -r file; do
    [ -z "$file" ] && continue

    # Heuristic indicators that the import IS needed:
    # 1. TYPE_CHECKING guard → likely has forward refs
    # 2. String annotations like 'ClassName' or "ClassName"
    # 3. Self-referencing return type: `-> GraspoConfig` inside class GraspoConfig
    #    (Python 3.11 needs PEP 563 to defer class-body annotation evaluation)
    # 4. Old-style typing imports → may need PEP 563 for forward references
    #
    # Every pattern is passed after `--`, and none of these greps discards
    # stderr: a pattern that begins with '-' (case 3 starts with `->`) is
    # otherwise parsed by grep as an option, which returned 2, made the
    # condition permanently false, and — with the old `2>/dev/null` — hid the
    # `invalid option` error. A grep failure is now visible instead of
    # silently turning the heuristic off.
    NEEDS_IT=0

    # Case 3 is evaluated against the classes defined in this very file:
    # only `-> ThisFilesOwnClass` needs deferred evaluation. A bare
    # `grep -qE -- '->[[:space:]]*[A-Z]'` would also accept `-> None` and
    # imported types such as `-> Path`, which is why, on a real project, 11
    # of the 18 flagged files carried only such annotations and would have
    # had their warning silently dropped. The intersection below keeps case 3
    # as strong as its comment claims.
    SELF_REF_RETURN=""
    FILE_CLASSES=$(grep -oE '^[[:space:]]*class[[:space:]]+[A-Za-z_][A-Za-z0-9_]*' "$file" | awk '{print $2}' | sort -u || true)
    FILE_RETURN_TYPES=$(grep -oE -- '->[[:space:]]*[A-Za-z_][A-Za-z0-9_]*' "$file" | sed -E 's/^->[[:space:]]*//' | sort -u || true)
    if [ -n "$FILE_CLASSES" ] && [ -n "$FILE_RETURN_TYPES" ]; then
        SELF_REF_RETURN=$(comm -12 <(printf '%s\n' "$FILE_CLASSES") <(printf '%s\n' "$FILE_RETURN_TYPES") || true)
    fi

    if grep -q -- 'TYPE_CHECKING' "$file"; then
        NEEDS_IT=1
    elif grep -qE -- '["'\''"'\'']([A-Z][a-zA-Z0-9_]*["'\''"'\'']|\s*\|)' "$file"; then
        # String annotation pattern like -> "ClassName" or : "SomeType"
        NEEDS_IT=1
    elif [ -n "$SELF_REF_RETURN" ]; then
        # Self-referencing return type annotation (e.g. `-> GraspoConfig`)
        NEEDS_IT=1
    elif grep -qE -- 'from typing import (Dict|List|Tuple|Set|Optional|Union|Callable)' "$file"; then
        # Old-style typing imports that need PEP 563 for forward references
        NEEDS_IT=1
    fi

    if [ $NEEDS_IT -eq 0 ]; then
        LINE_NO=$(grep -n 'from __future__ import annotations' "$file" | head -1 | cut -d: -f1)
        echo "  [WARN] $file:$LINE_NO: from __future__ import annotations may be unnecessary (no forward references detected)"
        WARN_COUNT=$((WARN_COUNT + 1))
    fi
done <<< "$FILES_WITH_FUTURE"

echo ""
if [ $WARN_COUNT -eq 0 ]; then
    echo "[PASS] check_future_annotations: All $TOTAL_COUNT file(s) with the import appear to need it."
else
    echo "[WARN] check_future_annotations: $WARN_COUNT file(s) may have unnecessary from __future__ import annotations."
    echo "       Review each warning. Remove the import if the file has no forward-reference annotations (§8.6)."
fi
exit 0
