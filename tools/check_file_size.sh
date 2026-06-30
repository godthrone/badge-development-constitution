#!/usr/bin/env bash
# check_file_size.sh — Flag files exceeding recommended size per §8.2
# Part of BADGE Constitution §8.2
#
# Checks for:
#   - Files exceeding 1000 lines
#   - Extremely large files (> 2000 lines)
#
# Usage: ./check_file_size.sh [project_root]

set -euo pipefail

PROJECT_ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || echo '.')}"
cd "$PROJECT_ROOT"

FAIL=0

if ! git rev-parse --git-dir &>/dev/null 2>&1; then
    echo "[SKIP] check_file_size: Not a git repository."
    exit 0
fi

TRACKED_FILES=$(git ls-files --cached --others --exclude-standard 2>/dev/null | \
    grep -E '\.(py|yaml|yml|md|sh|toml)$' | \
    grep -v 'uv\.lock' | \
    grep -v '__pycache__/' | \
    grep -v '\.egg-info/' | \
    grep -v 'badge-development-constitution/' || true)

if [ -z "$TRACKED_FILES" ]; then
    echo "[PASS] check_file_size: No files to check."
    exit 0
fi

echo "Checking file sizes..."

OVER_1000=()
OVER_2000=()

while IFS= read -r file; do
    [ -z "$file" ] && continue
    if [ ! -f "$file" ]; then continue; fi
    LINES=$(wc -l < "$file" 2>/dev/null || echo 0)
    if [ "$LINES" -gt 2000 ]; then
        OVER_2000+=("$file:$LINES")
    elif [ "$LINES" -gt 1000 ]; then
        OVER_1000+=("$file:$LINES")
    fi
done <<< "$TRACKED_FILES"

# Report files > 2000 lines (strong concern)
if [ ${#OVER_2000[@]} -gt 0 ]; then
    echo "[FAIL] check_file_size: Files exceeding 2000 lines (strongly consider splitting §8.2):"
    for entry in "${OVER_2000[@]}"; do
        file="${entry%%:*}"
        lines="${entry##*:}"
        echo "  $file ($lines lines)"
    done
    FAIL=1
fi

# Report files > 1000 lines (advisory)
if [ ${#OVER_1000[@]} -gt 0 ]; then
    echo "[WARN] Files exceeding 1000 lines (review for potential splitting §8.2):"
    for entry in "${OVER_1000[@]}"; do
        file="${entry%%:*}"
        lines="${entry##*:}"
        echo "  $file ($lines lines)"
    done
    echo "         §8.2: if exceeding 1000 lines, ask: is it cramming in two concepts?"
    echo "         Single-concept files (toolkits, complex adapters) may exceed 1000 lines."
fi

if [ ${#OVER_1000[@]} -eq 0 ] && [ ${#OVER_2000[@]} -eq 0 ]; then
    echo "  [OK] All files are under 1000 lines."
fi

echo ""
if [ $FAIL -eq 0 ]; then
    echo "[PASS] check_file_size: File sizes are within recommended limits."
else
    echo "[FAIL] check_file_size: Some files need splitting."
fi
exit $FAIL
