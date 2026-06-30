#!/usr/bin/env bash
# check_gitignore.sh — Verify .gitignore covers all required entries per §19.2
# Part of BADGE Constitution v1.6.0 §19.2
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

# Check that .env-example is NOT excluded (it should be tracked)
if echo "$GITIGNORE_CONTENT" | grep -v '^\s*#' | grep -q '\.env-example' 2>/dev/null; then
    echo "  [FAIL] .env-example is excluded in .gitignore — it MUST be tracked."
    FAIL=1
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