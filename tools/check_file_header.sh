#!/usr/bin/env bash
# check_file_header.sh — Verify every source file opens with a responsibility
# declaration comment per §12.4.
# Part of BADGE Constitution §12.4
#
# §12.4: "Every source file must open with a comment declaring the file's
# function and scope of responsibility, in one sentence."
#
# Exempt: __init__.py — its responsibility is re-exporting the public API
# (§8.6), no need to declare it again.
#
# Usage: ./check_file_header.sh [project_root]

set -euo pipefail

PROJECT_ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || echo '.')}"
cd "$PROJECT_ROOT"

if ! git rev-parse --git-dir &>/dev/null 2>&1; then
    echo "[SKIP] check_file_header: Not a git repository."
    exit 0
fi

PY_FILES=$(git ls-files --cached --others --exclude-standard 2>/dev/null | \
    grep '\.py$' | \
    grep -v '__pycache__/' | \
    grep -v '\.egg-info/' | \
    grep -v '/__init__\.py$' || true)

if [ -z "$PY_FILES" ]; then
    echo "[PASS] check_file_header: No Python files to check."
    exit 0
fi

FAIL=0
MISSING=()

while IFS= read -r file; do
    [ -z "$file" ] && continue
    [ -f "$file" ] || continue

    # First non-blank, non-shebang line must start a comment (#, """, or ''')
    # — the header responsibility declaration.
    FIRST=$(awk '/^#!\// { next } NF { print; exit }' "$file" 2>/dev/null || true)
    case "$FIRST" in
        \#*) ;;             # comment or shebang
        \"\"\"*) ;;         # module docstring
        \'\'\'*) ;;
        *)
            MISSING+=("$file")
            FAIL=1
            ;;
    esac
done <<< "$PY_FILES"

if [ ${#MISSING[@]} -gt 0 ]; then
    echo "[FAIL] check_file_header: ${#MISSING[@]} file(s) missing a file-header responsibility declaration (§12.4):"
    for file in "${MISSING[@]}"; do
        echo "  $file"
    done
    echo "         §12.4: open with a comment declaring the file's function and scope of responsibility."
else
    echo "[PASS] check_file_header: All source files open with a responsibility declaration."
fi
exit $FAIL
