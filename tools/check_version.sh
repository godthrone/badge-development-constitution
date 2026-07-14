#!/usr/bin/env bash
# check_version.sh — Verify version is single-source per §8.7
# Part of BADGE Constitution §8.7
#
# Checks for:
#   - No __version__ in __init__.py
#   - pyproject.toml uses either static version or dynamic=["version"] with setuptools-scm
#   - No hardcoded version in config_example.yaml
#   - No standalone VERSION file
#   - If setuptools-scm: git tags exist, tag_regex configured
#
# Usage: ./check_version.sh [project_root]

set -euo pipefail

PROJECT_ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || echo '.')}"
cd "$PROJECT_ROOT"

FAIL=0

# ─── 1. Check __init__.py for __version__ ────────────────────────────────

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

# ─── 2. Check pyproject.toml versioning ─────────────────────────────────

PYPROJECT="$PROJECT_ROOT/pyproject.toml"
if [ ! -f "$PYPROJECT" ]; then
    echo "[FAIL] check_version: pyproject.toml not found."
    exit 1
fi

# Check for dynamic version (setuptools-scm) — the recommended approach
if grep -q 'dynamic\s*=\s*\[.*"version"' "$PYPROJECT" 2>/dev/null; then
    echo "  [OK] Version: dynamic (setuptools-scm from git tags)"

    # Verify setuptools-scm is in build-system requires
    if ! grep -q 'setuptools-scm' "$PYPROJECT" 2>/dev/null; then
        echo "  [FAIL] dynamic version declared but setuptools-scm not in build-system.requires"
        FAIL=1
    fi

    # Verify setuptools_scm config exists
    if ! grep -q '\[tool\.setuptools_scm\]' "$PYPROJECT" 2>/dev/null; then
        echo "  [WARN] No [tool.setuptools_scm] section found. Consider adding tag_regex."
    else
        echo "  [OK] [tool.setuptools_scm] configured"
    fi

    # Verify git tags exist (warning only — repo may not have tagged yet)
    if git rev-parse --git-dir >/dev/null 2>&1; then
        TAGS=$(git tag --list 'v*' 2>/dev/null || true)
        if [ -n "$TAGS" ]; then
            echo "  [OK] Git tags found: $(echo "$TAGS" | tr '\n' ' ')"
        else
            echo "  [WARN] No git tags found. Run: git tag v0.1.0"
        fi
    fi
else
    # Fallback: static version (legacy, still accepted)
    VERSION=$(grep -E '^version\s*=' "$PYPROJECT" 2>/dev/null | head -1 | sed 's/.*=\s*"\([^"]*\)".*/\1/' || true)
    if [ -z "$VERSION" ]; then
        echo "  [FAIL] No version or dynamic=[\"version\"] found in pyproject.toml [project] section."
        FAIL=1
    else
        echo "  [OK] Version: $VERSION (static in pyproject.toml)"
        echo "  [NOTE] Consider migrating to dynamic version via setuptools-scm (§8.7)."
    fi
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
    echo "[PASS] check_version: Version is single-source."
else
    echo "[FAIL] check_version: Issues found."
fi
exit $FAIL