#!/usr/bin/env bash
# check_version.sh — Verify version number is only in pyproject.toml per §8.7
# Part of BADGE Constitution §8.7
#
# Usage: ./check_version.sh [project_root]

set -euo pipefail

PROJECT_ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || echo '.')}"
cd "$PROJECT_ROOT"

FAIL=0

# ─── 1. Check __init__.py for __version__ ────────────────────────────────

# Find all __init__.py files under src/
INIT_FILES=$(find src/ -name '__init__.py' -not -path '*.egg-info/*' 2>/dev/null || true)

if [ -n "$INIT_FILES" ]; then
    while IFS= read -r init_file; do
        if grep -q '__version__' "$init_file" 2>/dev/null; then
            echo "  [FAIL] $init_file defines __version__ (forbidden by §8.7)."
            FAIL=1
        fi
    done <<< "$INIT_FILES"
else
    echo "  [OK] No __init__.py files found under src/."
fi

# ─── 2. Check pyproject.toml has version ─────────────────────────────────

PYPROJECT="$PROJECT_ROOT/pyproject.toml"
if [ ! -f "$PYPROJECT" ]; then
    echo "[FAIL] check_version: pyproject.toml not found."
    exit 1
fi

VERSION=$(grep -E '^version\s*=' "$PYPROJECT" 2>/dev/null | head -1 | sed 's/.*=\s*"\([^"]*\)".*/\1/' || true)
if [ -z "$VERSION" ]; then
    echo "  [FAIL] No version found in pyproject.toml [project] section."
    FAIL=1
else
    echo "  [OK] Version: $VERSION (from pyproject.toml)"
fi

# ─── 3. Check config_example.yaml doesn't have version ────────────────────

CONFIG_EXAMPLE="$PROJECT_ROOT/config_example.yaml"
if [ -f "$CONFIG_EXAMPLE" ]; then
    if grep -qiE 'version:\s*[0-9]+\.[0-9]+' "$CONFIG_EXAMPLE" 2>/dev/null; then
        echo "  [WARN] config_example.yaml may contain version numbers (review manually)."
    fi
fi

# ─── 4. Check no standalone VERSION file ──────────────────────────────────

if [ -f "$PROJECT_ROOT/VERSION" ] || [ -f "$PROJECT_ROOT/version.txt" ]; then
    echo "  [FAIL] Standalone VERSION/version.txt file found (forbidden by §8.7)."
    FAIL=1
fi

echo ""
if [ $FAIL -eq 0 ]; then
    echo "[PASS] check_version: Version is single-source in pyproject.toml."
else
    echo "[FAIL] check_version: Issues found."
fi
exit $FAIL