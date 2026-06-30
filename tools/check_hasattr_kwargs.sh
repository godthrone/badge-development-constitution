#!/usr/bin/env bash
# check_hasattr_kwargs.sh — Detect misuse of hasattr and **kwargs per §2.2
# Part of BADGE Constitution §2.2
#
# Checks for:
#   - hasattr() probing business interfaces (own project classes)
#   - **kwargs without docstring documentation
#   - **kwargs pass-through without documentation
#
# Usage: ./check_hasattr_kwargs.sh [project_root]

set -euo pipefail

PROJECT_ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || echo '.')}"
cd "$PROJECT_ROOT"

FAIL=0

if ! git rev-parse --git-dir &>/dev/null 2>&1; then
    echo "[SKIP] check_hasattr_kwargs: Not a git repository."
    exit 0
fi

PY_FILES=$(git ls-files --cached --others --exclude-standard 2>/dev/null | \
    grep '\.py$' | grep -v '__pycache__/' | grep -v '\.egg-info/' | \
    grep -v 'badge-development-constitution/' | grep -v 'tests/' || true)

if [ -z "$PY_FILES" ]; then
    echo "[PASS] check_hasattr_kwargs: No Python files to check."
    exit 0
fi

echo "Checking hasattr and **kwargs usage..."

# ─── 1. hasattr usage in own project code ───────────────────────────────

# Find hasattr calls — we flag them all for review, since the constitution
# only allows hasattr for: runtime capability detection, cross-version compat,
# and duck-typing. Business interface probing is forbidden.
HASATTR_USAGE=$(echo "$PY_FILES" | xargs grep -nE '\bhasattr\(' 2>/dev/null || true)

if [ -n "$HASATTR_USAGE" ]; then
    # Separate known-allowed patterns from suspicious ones
    # Allowed: hasattr(torch, ...), hasattr(tensor, ...), hasattr(module, ...) for version checks
    ALLOWED_HASATTR=$(echo "$HASATTR_USAGE" | grep -E 'hasattr\(torch[,.]|hasattr\(tensor|hasattr\([a-z_]+\.(version|__version)|#\s*allowed' || true)
    SUSPICIOUS_HASATTR=$(echo "$HASATTR_USAGE" | grep -vE 'hasattr\(torch[,.]|hasattr\(tensor|hasattr\([a-z_]+\.(version|__version)|#\s*allowed' || true)

    if [ -n "$SUSPICIOUS_HASATTR" ]; then
        echo "[WARN] hasattr() usage found (review each — business interface probing is forbidden §2.2):"
        echo "$SUSPICIOUS_HASATTR" | while IFS= read -r line; do
            echo "  $line"
        done
        echo "         Allowed only for: runtime capability detection, cross-version compat, duck-typing."
        echo "         For business interfaces, use ABC or Protocol instead."
    fi
    if [ -n "$ALLOWED_HASATTR" ]; then
        echo "  [OK] hasattr() on known library types (torch, etc.) — appears legitimate"
    fi
fi

# ─── 2. **kwargs without docstring documentation ───────────────────────

# Find function definitions using **kwargs
KWARGS_FUNCTIONS=$(echo "$PY_FILES" | xargs grep -nE 'def \w+\([^)]*\*\*kwargs[^)]*\)' 2>/dev/null || true)

if [ -n "$KWARGS_FUNCTIONS" ]; then
    echo ""
    echo "Checking **kwargs documentation..."
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        file=$(echo "$line" | cut -d: -f1)
        line_no=$(echo "$line" | cut -d: -f2)

        # Check if this function's docstring mentions kwargs
        # Look at lines after the function definition for docstring with kwargs mention
        if [ -f "$file" ]; then
            HAS_DOC=0
            # Check next 10 lines for docstring with kwargs documentation
            for i in $(seq $((line_no + 1)) $((line_no + 10))); do
                DOC_LINE=$(sed -n "${i}p" "$file" 2>/dev/null || true)
                if echo "$DOC_LINE" | grep -qiE '(kwargs|keyword arguments|Args:|additional parameters|子类可能|额外参数)'; then
                    HAS_DOC=1
                    break
                fi
                # Stop checking after docstring ends (triple quote close or code)
                if echo "$DOC_LINE" | grep -qE '^[^"#]|^\s*$' && ! echo "$DOC_LINE" | grep -qE '^\s*"""|^\s*$'; then
                    break
                fi
            done

            if [ $HAS_DOC -eq 0 ]; then
                echo "[FAIL] check_hasattr_kwargs: **kwargs without documented parameters in docstring:"
                echo "  $file:$line_no"
                FAIL=1
            fi
        fi
    done <<< "$KWARGS_FUNCTIONS"

    if [ $FAIL -eq 0 ] && [ -n "$KWARGS_FUNCTIONS" ]; then
        echo "  [OK] All **kwargs usages have docstring documentation"
    fi
fi

echo ""
if [ $FAIL -eq 0 ]; then
    echo "[PASS] check_hasattr_kwargs: hasattr and **kwargs usage follows §2.2."
else
    echo "[FAIL] check_hasattr_kwargs: Issues found."
fi
exit $FAIL
