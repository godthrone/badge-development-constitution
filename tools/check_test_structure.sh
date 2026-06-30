#!/usr/bin/env bash
# check_test_structure.sh — Verify tests/ mirrors src/ per §11.2
# Part of BADGE Constitution §11.2, §11.3
#
# Checks for:
#   - tests/ directory mirrors src/package/ tree
#   - e2e/ directory exists under tests/
#   - pyproject.toml has pytest configuration
#   - ruff and mypy configured
#
# Usage: ./check_test_structure.sh [project_root]

set -euo pipefail

PROJECT_ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || echo '.')}"
cd "$PROJECT_ROOT"

FAIL=0

echo "Checking test structure..."

# ─── 1. tests/ directory exists ─────────────────────────────────────────

if [ ! -d "$PROJECT_ROOT/tests" ]; then
    echo "[FAIL] check_test_structure: tests/ directory not found (§11.2)."
    exit 1
fi

# ─── 2. tests/e2e/ directory ────────────────────────────────────────────

if [ -d "$PROJECT_ROOT/tests/e2e" ]; then
    echo "  [OK] tests/e2e/ — end-to-end test directory"
else
    echo "  [WARN] tests/e2e/ not found — consider adding end-to-end tests (§11.2)."
fi

# ─── 3. Mirror check: tests/ should mirror src/<package>/ ───────────────

if [ -d "$PROJECT_ROOT/src" ]; then
    # Find all package directories under src/ (directories with __init__.py, 2 levels deep)
    SRC_PACKAGES=$(find "$PROJECT_ROOT/src" -maxdepth 2 -mindepth 2 -name '__init__.py' -not -path '*.egg-info/*' 2>/dev/null | \
        sed 's|/__init__.py||' | sed "s|$PROJECT_ROOT/src/||" || true)

    # Get subdirectories in tests/ (excluding e2e/)
    TEST_DIRS=$(find "$PROJECT_ROOT/tests" -maxdepth 2 -mindepth 1 -type d -not -name 'e2e' -not -name '__pycache__' -not -name '.pytest_cache' 2>/dev/null | \
        sed "s|$PROJECT_ROOT/tests/||" || true)

    if [ -n "$SRC_PACKAGES" ] && [ -n "$TEST_DIRS" ]; then
        # For each source package subdirectory, check if tests/ has a matching directory
        while IFS= read -r src_dir; do
            [ -z "$src_dir" ] && continue
            # Get the subdirectories inside this package (e.g., core, backends, domain)
            SUBDIRS=$(find "$PROJECT_ROOT/src/$src_dir" -maxdepth 1 -type d -not -name "$src_dir" -not -name '__pycache__' -not -name '*.egg-info' 2>/dev/null | \
                sed "s|$PROJECT_ROOT/src/$src_dir/||" || true)
            for sub in $SUBDIRS; do
                [ -z "$sub" ] && continue
                if [ -d "$PROJECT_ROOT/tests/$sub" ]; then
                    echo "  [OK] tests/$sub/ mirrors src/$src_dir/$sub/"
                else
                    echo "  [WARN] tests/$sub/ not found — src/$src_dir/$sub/ has no corresponding test directory (§11.2)."
                fi
            done
        done <<< "$SRC_PACKAGES"

        # Reverse check: test directories without source counterparts
        while IFS= read -r test_dir; do
            [ -z "$test_dir" ] && continue
            FOUND=0
            while IFS= read -r src_dir; do
                [ -z "$src_dir" ] && continue
                if [ -d "$PROJECT_ROOT/src/$src_dir/$test_dir" ]; then
                    FOUND=1
                    break
                fi
            done <<< "$SRC_PACKAGES"
            if [ $FOUND -eq 0 ]; then
                echo "  [WARN] tests/$test_dir/ has no corresponding directory under src/ (§11.2)."
            fi
        done <<< "$TEST_DIRS"
    elif [ -z "$SRC_PACKAGES" ]; then
        echo "  [INFO] No Python packages found under src/ — mirror check skipped."
    fi
fi

# ─── 4. Toolchain configuration in pyproject.toml ───────────────────────

PYPROJECT="$PROJECT_ROOT/pyproject.toml"
if [ -f "$PYPROJECT" ]; then
    # pytest config
    if grep -q '\[tool\.pytest' "$PYPROJECT" 2>/dev/null; then
        echo "  [OK] pytest configured in pyproject.toml"
    else
        echo "  [WARN] pytest not configured in pyproject.toml (§11.1)."
    fi

    # ruff config
    if grep -q '\[tool\.ruff' "$PYPROJECT" 2>/dev/null; then
        echo "  [OK] ruff configured in pyproject.toml"
    else
        echo "  [WARN] ruff not configured in pyproject.toml (§11.1)."
    fi

    # mypy config
    if grep -q '\[tool\.mypy' "$PYPROJECT" 2>/dev/null; then
        echo "  [OK] mypy configured in pyproject.toml"
    else
        echo "  [WARN] mypy not configured in pyproject.toml (§11.1)."
    fi

    # Dev dependencies
    if grep -qE '"pytest' "$PYPROJECT" 2>/dev/null && \
       grep -qE '"ruff' "$PYPROJECT" 2>/dev/null && \
       grep -qE '"mypy' "$PYPROJECT" 2>/dev/null; then
        echo "  [OK] pytest, ruff, mypy in dev dependencies"
    else
        echo "  [WARN] Dev dependencies may be missing pytest, ruff, or mypy (§11.1)."
    fi
fi

echo ""
if [ $FAIL -eq 0 ]; then
    echo "[PASS] check_test_structure: Test structure follows constitution."
else
    echo "[FAIL] check_test_structure: Issues found."
fi
exit $FAIL
