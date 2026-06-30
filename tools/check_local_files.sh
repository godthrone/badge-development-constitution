#!/usr/bin/env bash
# check_local_files.sh — Verify no temporary files exist outside .local/
# Part of BADGE Constitution v1.6.0 §XVI
#
# Usage: ./check_local_files.sh [project_root]

set -euo pipefail

PROJECT_ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || echo '.')}"
cd "$PROJECT_ROOT"

FAIL=0

# ─── 1. Check .local/ is in .gitignore ───────────────────────────────────

GITIGNORE="$PROJECT_ROOT/.gitignore"
if [ -f "$GITIGNORE" ]; then
    if grep -v '^\s*#' "$GITIGNORE" | grep -qF '.local/' 2>/dev/null; then
        echo "  [OK] .local/ is in .gitignore"
    else
        echo "  [FAIL] .local/ is NOT in .gitignore (required by §19.2)."
        FAIL=1
    fi
fi

# ─── 2. Check for temporary files outside .local/ ───────────────────────

# Heuristic: files matching common temporary-file naming patterns
# outside of .local/ and not in standard directories.
TEMP_PATTERNS=(
    '*LONG_RUN*'
    '*MIGRATION_PLAN*'
    '*RUNBOOK*'
    '*runbook*'
    '*deploy_note*'
    '*experiment*note*'
    '*personal_note*'
)

# Find tracked files (not in .local/)
if git rev-parse --git-dir &>/dev/null 2>&1; then
    TRACKED_FILES=$(git ls-files --cached 2>/dev/null || true)
else
    echo "[SKIP] check_local_files: Not a git repository."
    exit 0
fi

echo "Checking for temporary files outside .local/..."

for pattern in "${TEMP_PATTERNS[@]}"; do
    # Find files matching the pattern in tracked files, excluding .local/
    MATCHES=$(echo "$TRACKED_FILES" | grep -i "$pattern" 2>/dev/null | grep -v '^\.local/' || true)
    if [ -n "$MATCHES" ]; then
        echo "  [FAIL] Temporary file found outside .local/:"
        echo "$MATCHES" | while IFS= read -r f; do
            echo "    $f (should be moved to .local/)"
        done
        FAIL=1
    fi
done

# ─── 3. Check for files with internal naming patterns in root ────────────

# Files in the project root that look like notes/runbooks
ROOT_SUSPECT_FILES=$(echo "$TRACKED_FILES" | grep -E '^[A-Z_]+\.md$' 2>/dev/null | \
    grep -v '^README\.md$' | grep -v '^CLAUDE\.md$' | grep -v '^LICENSE$' || true)

if [ -n "$ROOT_SUSPECT_FILES" ]; then
    echo "  [WARN] All-caps .md files in project root (review manually):"
    echo "$ROOT_SUSPECT_FILES" | while IFS= read -r f; do
        echo "    $f"
    done
    echo "         If these are temporary notes, move them to .local/."
fi

# ─── 4. .local/ directory exists check ───────────────────────────────────

if [ -d "$PROJECT_ROOT/.local" ]; then
    echo "  [OK] .local/ directory exists."
else
    echo "  [INFO] .local/ directory does not exist yet. Create it: mkdir .local"
fi

echo ""
if [ $FAIL -eq 0 ]; then
    echo "[PASS] check_local_files: No temporary files outside .local/."
else
    echo "[FAIL] check_local_files: Issues found."
fi
exit $FAIL