#!/usr/bin/env bash
# check_local_files.sh — Verify no temporary files exist outside .local/
# Part of BADGE Constitution §XVI
#
# Checks:
#   1. .local/ is in .gitignore
#   2. No temporary files in tracked paths outside .local/
#   3. No log files, temp files, or backup files in tracked paths
#   4. No files with sensitive content patterns (IPs, SSH) outside .local/ or docs/
#   5. .local/ directory exists (info)
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
else
    echo "  [WARN] No .gitignore found — cannot verify .local/ exclusion."
fi

# ─── 2. Collect tracked files ───────────────────────────────────────────

if ! git rev-parse --git-dir &>/dev/null 2>&1; then
    echo "[SKIP] check_local_files: Not a git repository."
    exit 0
fi

TRACKED_FILES=$(git ls-files --cached 2>/dev/null || true)
if [ -z "$TRACKED_FILES" ]; then
    echo "[PASS] check_local_files: No tracked files found."
    exit 0
fi

# Files outside .local/
TRACKED_OUTSIDE_LOCAL=$(echo "$TRACKED_FILES" | grep -v '^\.local/' || true)

# ─── 3. Check for temporary-file naming patterns ───────────────────────

echo "Checking for temporary files outside .local/..."

# Broad patterns for temporary files
TEMP_PATTERNS=(
    # Notes, plans, runbooks
    '*_NOTE*' '*_NOTES*' '*_PLAN*' '*_PLANS*'
    '*RUNBOOK*' '*runbook*' '*MIGRATION*'
    # Deployment / experiment records
    '*deploy*note*' '*deploy*record*'
    '*experiment*note*' '*experiment*log*'
    '*personal*' '*scratch*'
    # Run monitors / logs
    '*LONG_RUN*' '*run_monitor*' '*watchdog*'
    # Draft files
    '*_DRAFT*' '*_draft*' '*_WIP*' '*_wip*'
    '*_TEMP*' '*_temp*' '*_TMP*' '*_tmp*'
    '*_BACKUP*' '*_backup*' '*_BAK*' '*_bak*'
    '*_OLD*' '*_old*'
    # Discussion / meeting notes
    '*meeting*note*' '*discussion*note*'
)

for pattern in "${TEMP_PATTERNS[@]}"; do
    MATCHES=$(echo "$TRACKED_OUTSIDE_LOCAL" | grep -i "${pattern//\*/.*}" 2>/dev/null | \
        grep -v '^\.local/' || true)
    if [ -n "$MATCHES" ]; then
        echo "  [FAIL] Temporary file found outside .local/:"
        echo "$MATCHES" | while IFS= read -r f; do
            echo "    $f (should be moved to .local/)"
        done
        FAIL=1
    fi
done

# ─── 4. Check for log/temp/bak files in tracked paths ──────────────────

echo "Checking for log, temp, and backup files in tracked paths..."

# *.log files (outside .local/ and standard log directories like outputs/)
LOG_FILES=$(echo "$TRACKED_OUTSIDE_LOCAL" | grep -E '\.log$' 2>/dev/null | \
    grep -v '^outputs/' | grep -v '^\.local/' || true)
if [ -n "$LOG_FILES" ]; then
    echo "  [WARN] .log files tracked outside outputs/ or .local/:"
    echo "$LOG_FILES" | while IFS= read -r f; do
        echo "    $f"
    done
    echo "         Log files should be in outputs/ or .local/."
fi

# *.tmp, *.bak, *.swp files
TEMP_EXT_FILES=$(echo "$TRACKED_OUTSIDE_LOCAL" | grep -E '\.(tmp|bak|swp|swo|~)$' 2>/dev/null || true)
if [ -n "$TEMP_EXT_FILES" ]; then
    echo "  [FAIL] Temp/backup/swap files tracked in git:"
    echo "$TEMP_EXT_FILES" | while IFS= read -r f; do
        echo "    $f (delete or move to .local/)"
    done
    FAIL=1
fi

# ─── 5. All-caps .md files in root (suspect notes/runbooks) ────────────

ROOT_SUSPECT_FILES=$(echo "$TRACKED_FILES" | grep -E '^[A-Z_]{4,}\.md$' 2>/dev/null | \
    grep -v '^README\.md$' | grep -v '^CLAUDE\.md$' | grep -v '^LICENSE$' | \
    grep -v '^CHANGELOG\.md$' || true)

if [ -n "$ROOT_SUSPECT_FILES" ]; then
    echo "  [WARN] All-caps .md files in project root (review manually):"
    echo "$ROOT_SUSPECT_FILES" | while IFS= read -r f; do
        echo "    $f"
    done
    echo "         If these are temporary notes, move them to .local/."
fi

# ─── 6. Check for data dumps / serialized data in tracked paths ────────

DATA_DUMPS=$(echo "$TRACKED_OUTSIDE_LOCAL" | grep -E '\.(pkl|pickle|joblib|h5|hdf5|parquet|feather)$' 2>/dev/null | \
    grep -v '^tests/' | grep -v '^data/sample' || true)
if [ -n "$DATA_DUMPS" ]; then
    echo "  [WARN] Data files tracked outside tests/ or sample data:"
    echo "$DATA_DUMPS" | while IFS= read -r f; do
        echo "    $f"
    done
    echo "         Large data files should be in .local/ or data/ (excluded from git)."
fi

# ─── 7. .local/ directory exists check ──────────────────────────────────

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
