#!/usr/bin/env bash
# check_class_file_naming.sh — Verify single-class file names encode the
# functional part of the class name per §12.2 (class-path mirroring).
# Part of BADGE Constitution §12.2
#
# §12.2: "Class name CamelCase words decompose into path components —
# package → directory → filename (snake_case), one word per level.
# The directory hierarchy provides domain context; the filename only
# needs to encode the functional part, not the full flattened class name."
#
# Check: the filename (without .py) must be a suffix of the full class
# name converted to snake_case.  This ensures the functional part of the
# class name is reflected in the filename, while the directory hierarchy
# carries the domain prefix.
#
# Exemptions (per §12.2):
#   - Class directories (§8.3): a sibling adapter.py means the directory
#     carries class-name locality; inner files are named by functional domain
#   - Mixin classes (_-prefixed or *Mixin suffix): named by function
#   - Multi-class files (§8.4): named by functional family
#   - Data-container types (frozen dataclass / pydantic model): attached to
#     the function family that operates on them (§8.4 benign mixing)
#   - Test files (tests/): named after the module under test (§11.2)
#
# Known acronyms (LoRA) are normalized before PascalCase conversion.
#
# Usage: ./check_class_file_naming.sh [project_root]

set -euo pipefail

PROJECT_ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || echo '.')}"
cd "$PROJECT_ROOT"

if ! git rev-parse --git-dir &>/dev/null 2>&1; then
    echo "[SKIP] check_class_file_naming: Not a git repository."
    exit 0
fi

PY_FILES=$(git ls-files --cached --others --exclude-standard 2>/dev/null | \
    grep '\.py$' | \
    grep -v '__pycache__/' | \
    grep -v '\.egg-info/' || true)

if [ -z "$PY_FILES" ]; then
    echo "[PASS] check_class_file_naming: No Python files to check."
    exit 0
fi

# PascalCase → snake_case: normalize known acronyms, insert _ at case
# boundaries, lowercase everything
to_snake() {
    echo "$1" | sed -E 's/LoRA/Lora/g; s/([a-z0-9])([A-Z])/\1_\2/g; s/([A-Z]+)([A-Z][a-z])/\1_\2/g' | tr '[:upper:]' '[:lower:]'
}

FAIL=0
echo "Checking single-class file naming..."

while IFS= read -r file; do
    [ -z "$file" ] && continue
    [ -f "$file" ] || continue

    # Test files: named after the module under test (§11.2), not the helper class
    case "$file" in
        tests/*) continue ;;
    esac

    # Top-level class names only — nested classes are not the file's identity
    CLASSES=$(grep -E '^class ' "$file" | sed -E 's/^class[[:space:]]+([A-Za-z_][A-Za-z0-9_]*).*/\1/' || true)
    [ -z "$CLASSES" ] && continue

    CLASS_COUNT=$(echo "$CLASSES" | grep -c '.' || true)
    [ "$CLASS_COUNT" -ne 1 ] && continue   # multi-class file: exempt (§8.4)

    CLASS="$CLASSES"
    case "$CLASS" in
        _* | *Mixin) continue ;;   # mixin class: named by function (§12.2)
    esac

    # Data-container types (§8.4 A-class): attached to their function family
    DECORATOR=$(grep -B1 "^class $CLASS[ :(]" "$file" | head -1 || true)
    echo "$DECORATOR" | grep -q '@dataclass' && continue
    grep -E "^class $CLASS[ :(].*(BaseModel|BaseSettings)" "$file" >/dev/null 2>&1 && continue

    # Class directory (§8.3): a sibling adapter.py means the dir carries locality
    DIR=$(dirname "$file")
    [ -f "$DIR/adapter.py" ] && continue

    EXPECTED_FULL=$(to_snake "$CLASS")
    BASENAME=$(basename "$file")
    BASENAME_NOEXT="${BASENAME%.py}"
    # The filename (without .py) must be a suffix of the full snake_case
    # class name.  The directory hierarchy carries the domain prefix.
    # Exact match (full class name flattened) OR suffix match (directory
    # hierarchy carries the domain prefix, filename carries the functional part).
    if [ "${EXPECTED_FULL}" = "${BASENAME_NOEXT}" ] || [ "${EXPECTED_FULL}" != "${EXPECTED_FULL%_${BASENAME_NOEXT}}" ]; then
        :
    else
        echo "  [FAIL] $file: single class '$CLASS' (full snake: ${EXPECTED_FULL}) → expected file name to be a suffix of '${EXPECTED_FULL}.py' (§12.2 class-path mirroring)"
        FAIL=1
    fi
done <<< "$PY_FILES"

if [ $FAIL -eq 0 ]; then
    echo "  [OK] All single-class files match their class names."
    echo "[PASS] check_class_file_naming: Class-path mirroring satisfied."
else
    echo "[FAIL] check_class_file_naming: Some file names do not mirror their class names."
fi
exit $FAIL