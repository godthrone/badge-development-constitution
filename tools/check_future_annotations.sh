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

FILES_WITH_FUTURE=$(echo "$PY_FILES" | xargs grep -l 'from __future__ import annotations' 2>/dev/null || true)

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
    # 3. from typing import ... → may need it for old-style annotations
    NEEDS_IT=0

    if grep -q 'TYPE_CHECKING' "$file" 2>/dev/null; then
        NEEDS_IT=1
    elif grep -qE '["'\'']([A-Z][a-zA-Z0-9_]*["'\'']|\s*\|)' "$file" 2>/dev/null; then
        # String annotation pattern like -> "ClassName" or : "SomeType"
        NEEDS_IT=1
    elif grep -qE 'from typing import (Any|Dict|List|Tuple|Set|Optional|Union|Callable)' "$file" 2>/dev/null; then
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
