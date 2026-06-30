#!/usr/bin/env bash
# check_directory_layout.sh — Verify project directory structure per §8.1
# Part of BADGE Constitution §8.1, §11.2
#
# Checks for:
#   - src/ directory with package (src-layout)
#   - tests/ directory exists
#   - configs/ or config_example.yaml exists
#   - docker/ directory exists
#   - scripts/ directory exists
#   - docs/ directory exists
#   - Key config files at root level
#
# Usage: ./check_directory_layout.sh [project_root]

set -euo pipefail

PROJECT_ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || echo '.')}"
cd "$PROJECT_ROOT"

FAIL=0

echo "Checking directory layout..."

# ─── 1. src-layout check ────────────────────────────────────────────────

if [ -d "$PROJECT_ROOT/src" ]; then
    echo "  [OK] src/ directory exists (src-layout)"
    # Check there's at least one package directory inside src/
    PKG_DIRS=$(find "$PROJECT_ROOT/src" -maxdepth 2 -name '__init__.py' -not -path '*.egg-info/*' 2>/dev/null || true)
    if [ -n "$PKG_DIRS" ]; then
        echo "  [OK] Python package(s) found under src/"
    else
        echo "  [WARN] No Python package (__init__.py) found under src/ — is this a new project?"
    fi
else
    echo "[FAIL] check_directory_layout: src/ directory not found (src-layout required by §8.1)."
    FAIL=1
fi

# ─── 2. Required directories ────────────────────────────────────────────

REQUIRED_DIRS=(
    "tests:TDD directory"
    "docker:Docker build directory"
    "scripts:Utility scripts directory"
)

for entry in "${REQUIRED_DIRS[@]}"; do
    dir="${entry%%:*}"
    desc="${entry##*:}"
    if [ -d "$PROJECT_ROOT/$dir" ]; then
        echo "  [OK] $dir/ — $desc"
    else
        echo "[FAIL] check_directory_layout: $dir/ directory not found ($desc required by §8.1)."
        FAIL=1
    fi
done

# ─── 3. Config directory or file ────────────────────────────────────────

if [ -d "$PROJECT_ROOT/configs" ] || [ -f "$PROJECT_ROOT/config_example.yaml" ]; then
    echo "  [OK] Config template exists (configs/ or config_example.yaml)"
else
    echo "[FAIL] check_directory_layout: No configs/ directory or config_example.yaml found (§7.3)."
    FAIL=1
fi

# ─── 4. docs/ directory ─────────────────────────────────────────────────

if [ -d "$PROJECT_ROOT/docs" ]; then
    echo "  [OK] docs/ — documentation directory"
else
    echo "  [WARN] docs/ directory not found — consider creating for architecture docs (§17.2)."
fi

# ─── 5. Root-level required files ───────────────────────────────────────

ROOT_FILES=(
    "pyproject.toml:Package config"
    "README.md:English README"
    "README.zh-CN.md:Chinese README"
    ".gitignore:Git ignore rules"
)

for entry in "${ROOT_FILES[@]}"; do
    file="${entry%%:*}"
    desc="${entry##*:}"
    if [ -f "$PROJECT_ROOT/$file" ]; then
        echo "  [OK] $file — $desc"
    else
        if [ "$file" = "README.zh-CN.md" ]; then
            echo "  [WARN] $file not found (bilingual docs required by §17.1)"
        else
            echo "[FAIL] check_directory_layout: $file not found ($desc required by §8.1/§19.2)."
            FAIL=1
        fi
    fi
done

# ─── 6. Recommended directories ─────────────────────────────────────────

RECOMMENDED=(
    ".local:Temporary local files"
)

for entry in "${RECOMMENDED[@]}"; do
    dir="${entry%%:*}"
    desc="${entry##*:}"
    if [ -d "$PROJECT_ROOT/$dir" ]; then
        echo "  [OK] $dir/ — $desc"
    else
        echo "  [INFO] $dir/ not created yet — recommend: mkdir $dir ($desc, §XVI)"
    fi
done

echo ""
if [ $FAIL -eq 0 ]; then
    echo "[PASS] check_directory_layout: Directory layout follows constitution."
else
    echo "[FAIL] check_directory_layout: Issues found."
fi
exit $FAIL
