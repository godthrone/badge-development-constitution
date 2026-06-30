#!/usr/bin/env bash
# check_gitignore.sh — Verify .gitignore covers all required entries per §19.2
# Part of BADGE Constitution §19.2
#
# Usage: ./check_gitignore.sh [project_root]

set -euo pipefail

PROJECT_ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || echo '.')}"
cd "$PROJECT_ROOT"

GITIGNORE="$PROJECT_ROOT/.gitignore"

if [ ! -f "$GITIGNORE" ]; then
    echo "[FAIL] check_gitignore: .gitignore file not found at $GITIGNORE"
    exit 1
fi

FAIL=0

# Each entry: "pattern" "description"
REQUIRED=(
    "__pycache__/"      "Python cache"
    "*.pyc"             "Python bytecode (or *.py[cod])"
    ".venv/"            "Virtual environment"
    "venv/"             "Virtual environment (alt name)"
    ".pytest_cache/"    "pytest cache"
    ".mypy_cache/"      "mypy cache"
    ".ruff_cache/"      "ruff cache"
    "dist/"             "Build artifacts"
    "build/"            "Build artifacts"
    "*.egg-info/"       "Build artifacts"
    ".env"              "Environment config"
    "outputs/"          "Output directory"
    ".idea/"            "IDE config"
    ".vscode/"          "IDE config"
    "CLAUDE.md"         "AI assistant file"
    "AGENTS.md"         "AI assistant file"
    ".DS_Store"         "macOS system file"
    ".local/"           "Temporary local files"
)

# Read .gitignore content
GITIGNORE_CONTENT=$(cat "$GITIGNORE")

check_pattern() {
    local pattern="$1"
    local desc="$2"

    # Check if pattern appears in .gitignore (non-commented lines)
    if echo "$GITIGNORE_CONTENT" | grep -v '^\s*#' | grep -qF "$pattern" 2>/dev/null; then
        echo "  [OK] $desc ($pattern)"
        return 0
    else
        # Special case: *.pyc is covered by *.py[cod]
        if [ "$pattern" = "*.pyc" ]; then
            if echo "$GITIGNORE_CONTENT" | grep -v '^\s*#' | grep -qE '\*\.py\[cod\]' 2>/dev/null; then
                echo "  [OK] $desc (covered by *.py[cod])"
                return 0
            fi
        fi
        # Special case: .venv/ is covered by .venv-*/
        if [ "$pattern" = ".venv/" ]; then
            if echo "$GITIGNORE_CONTENT" | grep -v '^\s*#' | grep -qE '\.venv-\*' 2>/dev/null; then
                echo "  [OK] $desc (covered by .venv-*/)"
                return 0
            fi
        fi
        # Special case: Thumbs.db is optional (Windows only)
        if [ "$pattern" = "Thumbs.db" ]; then
            echo "  [WARN] $desc ($pattern) — consider adding if team uses Windows"
            return 0
        fi
        echo "  [FAIL] $desc ($pattern) — MISSING from .gitignore"
        FAIL=1
        return 1
    fi
}

echo "Checking .gitignore coverage..."

for ((i=0; i<${#REQUIRED[@]}; i+=2)); do
    check_pattern "${REQUIRED[$i]}" "${REQUIRED[$i+1]}"
done

# Also check that CLAUDE.zh-CN.md is covered
if echo "$GITIGNORE_CONTENT" | grep -v '^\s*#' | grep -qF "CLAUDE.zh-CN.md" 2>/dev/null; then
    echo "  [OK] AI assistant Chinese file (CLAUDE.zh-CN.md)"
else
    echo "  [WARN] CLAUDE.zh-CN.md not explicitly in .gitignore (covered by CLAUDE.md pattern if using glob)"
fi

# ─── .env-example check (conditional per §19.2) ────────────────────────────
#
# .env-example is only required when the project has non-infrastructure
# environment variables.  Infrastructure-only projects (using only standard
# CUDA/NCCL/PyTorch distributed env vars) are exempt.
# We detect this by scanning source code for os.environ / os.getenv calls
# that are NOT infrastructure env vars.
INFRA_VARS='CUDA_VISIBLE_DEVICES|NCCL_|PYTORCH_|RANK\b|LOCAL_RANK|WORLD_SIZE|MASTER_ADDR|MASTER_PORT|TORCH_|OMP_'
IS_INFRA_ONLY=1

if [ -d "$PROJECT_ROOT/src" ]; then
    # Find os.environ / os.getenv references, exclude infrastructure-only ones
    # Also exclude bare os.environ copies (e.g. dict(os.environ), os.environ.copy())
    # which are infrastructure-level env passthrough, not app-specific config.
    APP_ENV_REFS=$(grep -rE '(os\.environ|os\.getenv)\b' "$PROJECT_ROOT/src/" 2>/dev/null | \
        grep -vE "$INFRA_VARS" | \
        grep -vE '(dict\(|\.copy\(|\.items\(|\.keys\()' | \
        grep -v '\.pyc' | grep -v '__pycache__' || true)
    if [ -n "$APP_ENV_REFS" ]; then
        IS_INFRA_ONLY=0
    fi
fi

# Also check config_example.yaml for env-related fields
if [ -f "$PROJECT_ROOT/config_example.yaml" ]; then
    if grep -qiE 'env:|environment:' "$PROJECT_ROOT/config_example.yaml" 2>/dev/null; then
        ENV_SECTION=$(grep -A 5 -E '^\s*env:' "$PROJECT_ROOT/config_example.yaml" 2>/dev/null | \
            grep -vE '^\s*(#|$)' | grep -v '^\s*env:' | grep -v '\{\}' | grep -v '\[\]' || true)
        if [ -n "$ENV_SECTION" ]; then
            IS_INFRA_ONLY=0
        fi
    fi
fi

if [ $IS_INFRA_ONLY -eq 1 ]; then
    echo "  [INFO] No .env-example needed (infrastructure-only project, see §19.2)."
else
    # Project has app-specific env vars → .env-example must exist
    if [ -f "$PROJECT_ROOT/.env-example" ]; then
        echo "  [OK] .env-example exists (project has app-specific env vars)."
        # Ensure .env-example is NOT in .gitignore
        if echo "$GITIGNORE_CONTENT" | grep -v '^\s*#' | grep -q '\.env-example' 2>/dev/null; then
            echo "  [FAIL] .env-example is excluded in .gitignore — it MUST be tracked."
            FAIL=1
        fi
    else
        echo "  [FAIL] .env-example is missing but project has app-specific env vars."
        FAIL=1
    fi
fi

# Check sample data exceptions
if echo "$GITIGNORE_CONTENT" | grep -v '^\s*#' | grep -q 'data/' 2>/dev/null; then
    if echo "$GITIGNORE_CONTENT" | grep -v '^\s*#' | grep -q '!data/sample' 2>/dev/null; then
        echo "  [OK] data/ excluded with sample data exceptions"
    else
        echo "  [WARN] data/ excluded but no sample data exceptions found"
    fi
fi

echo ""
if [ $FAIL -eq 0 ]; then
    echo "[PASS] check_gitignore: All required entries covered."
else
    echo "[FAIL] check_gitignore: Some required entries are missing."
fi
exit $FAIL