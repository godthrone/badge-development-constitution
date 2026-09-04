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
# Usage: ./check_directory_layout.sh [--class=A|B|C] [project_root]
#   --class=B: relax README.zh-CN.md requirement (advisory only per §17.6)

set -euo pipefail

CLASS="A"
PROJECT_ROOT=""
for arg in "${@}"; do
    case "$arg" in
        --class=A|--class=B|--class=C) CLASS="${arg#--class=}" ;;
        -*) echo "Usage: check_directory_layout.sh [--class=A|B|C] [project_root]" >&2; exit 2 ;;
        *) PROJECT_ROOT="$arg" ;;
    esac
done

PROJECT_ROOT="${PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || echo '.')}"
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

# ─── 2b. Optional: scripts/ (v1.14.1: §10.2 institutionalization) ───────
# scripts/ is optional — once all tools are promoted to CLI or deleted
# (§10.2), the directory is legitimately absent. Kept only as a
# compatibility note so a present scripts/ still passes.
if [ -d "$PROJECT_ROOT/scripts" ]; then
    echo "  [OK] scripts/ — utility scripts directory (optional, §10.2)"
fi

# ─── 3. Config directory or file ────────────────────────────────────────

# Recursively search for config_example.yaml or configs/ directory.
# Projects may place configs in subdirectories (e.g. samples/configs/).
CONFIG_EXAMPLE=$(find "$PROJECT_ROOT" -name "config_example.yaml" \
    -not -path "*/.local/*" -not -path "*/node_modules/*" \
    -not -path "*/__pycache__/*" -not -path "*/.venv/*" 2>/dev/null | head -1)
CONFIGS_DIR=$(find "$PROJECT_ROOT" -type d -name "configs" \
    -not -path "*/.local/*" -not -path "*/node_modules/*" \
    -not -path "*/__pycache__/*" -not -path "*/.venv/*" 2>/dev/null | head -1)

if [ -n "$CONFIG_EXAMPLE" ] || [ -n "$CONFIGS_DIR" ]; then
    echo "  [OK] Config template exists (configs/ or config_example.yaml)"
else
    echo "[FAIL] check_directory_layout: No configs/ directory or config_example.yaml found (§7.3)."
    echo "         Searched recursively; excluded .local/, node_modules/, __pycache__/, .venv/."
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
            if [ "$CLASS" = "B" ] || [ "$CLASS" = "C" ]; then
                echo "  [INFO] $file not found (bilingual docs exempt per §17.6 for Class $CLASS)"
            else
                echo "  [WARN] $file not found (bilingual docs required by §17.1)"
            fi
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
