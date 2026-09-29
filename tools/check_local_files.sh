#!/usr/bin/env bash
# check_local_files.sh — Verify no temporary files exist outside .local/
# Part of BADGE Constitution §16
#
# Checks:
#   1. .local/ is in .gitignore
#   2. No temporary files in tracked paths outside .local/
#   3. No log, temp, backup, or data-dump files in tracked paths
#   4. All-caps .md files in the project root (manual review, warn-only)
#   5. .local/ directory exists (info)
#
# Scope note: sensitive-content detection (internal IPs, SSH users) is
# check_secrets.sh's job (§15.1). This script only enforces §16 — where
# local/temporary files are allowed to live.
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

# §16.2 defines "local / temporary files" by *functional role* (running-environment
# record, one-off deployment record, personal notes, debug output, …), not by
# filename. Severity therefore depends on BOTH the marker and the *location*:
#
#   - unambiguous one-off markers (draft/wip/temp/tmp/backup/bak/old) → hard
#     failure anywhere;
#   - §16.2-named one-off roles (migration plan, runbook, deployment/experiment
#     record, personal notes, scratch pad, run monitor) → hard failure, *except*
#     inside a permanent project tree (src/tests/scripts/docker/tools/docs),
#     where those words routinely name real modules and docs and are reported as
#     [WARN] for review;
#   - ordinary English words (`note`, `plan`, `watchdog`) that also name permanent
#     modules → [WARN] everywhere — §16.2 judges the file's role, and a word alone
#     is only a weak signal (reference projects carry permanent `*_planner.py` /
#     `*_watchdog.py` modules). §16.1 still makes a stray one-off outside those
#     trees a violation, so the role words above keep blocking power.
TEMP_PATTERNS_HARD=(
    # Unambiguous one-off markers
    '*_DRAFT*' '*_draft*' '*_WIP*' '*_wip*'
    '*_TEMP_*' '*_temp_*' '*_TMP*' '*_tmp*'
    '*_BACKUP*' '*_backup*' '*_BAK*' '*_bak*'
    '*_OLD*' '*_old*'
)
# §16.2 roles: one-off operation records / personal notes / run monitors.
TEMP_PATTERNS_ROLE=(
    '*RUNBOOK*' '*MIGRATION*'
    '*deploy*note*' '*deploy*record*'
    '*experiment*note*' '*experiment*log*'
    '*personal*' '*scratch*'
    '*LONG_RUN*' '*run_monitor*'
    '*meeting*note*' '*discussion*note*'
)
# Ordinary English words that also name permanent source/test/doc modules.
TEMP_PATTERNS_ADVISORY=(
    '*_NOTE*' '*_NOTES*' '*_PLAN*' '*_PLANS*'
    '*watchdog*'
    # Bare note-file names (e.g. notes.md, note.txt) — advisory only
    'note*' 'notes*'
)

# Permanent project trees (§8.1 layout). A one-off word inside them is far more
# likely to be a module/doc name than a stray temp file.
PROJECT_TREES_RE='^(src|tests|scripts|docker|tools|docs)/'

# path<TAB>lowercased-basename, computed once. Matching the *basename* keeps a
# directory such as motion_planners/ from tainting every file beneath it.
BASENAME_LIST=$(printf '%s\n' "$TRACKED_OUTSIDE_LOCAL" | awk '
    NF {
        base = $0; sub(/.*\//, "", base);
        printf "%s\t%s\n", $0, tolower(base);
    }')

# Glob → whole-token regex. `*` matches any run of characters, but every literal
# token between stars must be bounded by a non-alphanumeric (or the string edge)
# so that `*_PLAN*` no longer fires on `motion_planner.py`. Boundaries are taken
# from each *token* (not from the glob edges), so `*a*b*` keeps both words.
glob_to_regex() {
    local pattern="$1" seg="" mid="" out="" first=1
    pattern="$(printf '%s' "$pattern" | tr '[:upper:]' '[:lower:]')"
    while IFS= read -r seg; do
        [ -n "$seg" ] || continue
        mid="$seg"
        case "$seg" in [a-z0-9]*) mid="(^|[^[:alnum:]])$mid" ;; esac
        case "$seg" in *[a-z0-9]) mid="$mid([^[:alnum:]]|$)" ;; esac
        if [ "$first" -eq 1 ]; then out="$mid"; first=0; else out="$out.*$mid"; fi
    done < <(printf '%s' "$pattern" | tr '*' '\n')
    printf '%s' "$out"
}

# §16.2 role words are matched as substrings, so `*scratch*` catches
# `scratchpad.py` (a whole-token match would not); lowered for case-insensitivity.
glob_to_substr_regex() {
    printf '%s' "${1//\*/.*}" | tr '[:upper:]' '[:lower:]'
}

# Collect unique basename matches for all patterns. $1 = matcher: token | substr.
collect_matches() {
    local matcher="$1"; shift
    local pattern regex
    for pattern in "$@"; do
        if [ "$matcher" = token ]; then
            regex="$(glob_to_regex "$pattern")"
        else
            regex="$(glob_to_substr_regex "$pattern")"
        fi
        [ -n "$regex" ] || continue
        printf '%s\n' "$BASENAME_LIST" | awk -F'\t' -v re="$regex" '$2 ~ re { print $1 }'
    done | grep -v '^\.local/' | sort -u || true
}

HARD_MATCHES=$(collect_matches token "${TEMP_PATTERNS_HARD[@]}")
ROLE_MATCHES=$(collect_matches substr "${TEMP_PATTERNS_ROLE[@]}")
# §16.2 roles inside a permanent tree are reviewed ([WARN]); elsewhere they block.
ROLE_IN_TREE=$(printf '%s\n' "$ROLE_MATCHES" | grep -E "$PROJECT_TREES_RE" || true)
ROLE_OUT_TREE=$(printf '%s\n' "$ROLE_MATCHES" | grep -vE "$PROJECT_TREES_RE" | grep -v '^$' || true)
ADVISORY_MATCHES=$(collect_matches token "${TEMP_PATTERNS_ADVISORY[@]}")

FAIL_MATCHES=$(printf '%s\n%s\n' "$HARD_MATCHES" "$ROLE_OUT_TREE" | grep -v '^$' | sort -u || true)
WARN_MATCHES=$(printf '%s\n%s\n' "$ADVISORY_MATCHES" "$ROLE_IN_TREE" | grep -v '^$' | sort -u || true)
# A file that already hard-fails is not repeated under [WARN] (a role word can
# also match an ordinary-word advisory pattern, e.g. deploy_note.md).
if [ -n "$FAIL_MATCHES" ]; then
    WARN_MATCHES=$(printf '%s\n' "$WARN_MATCHES" | grep -vxFf <(printf '%s\n' "$FAIL_MATCHES") || true)
fi

if [ -n "$FAIL_MATCHES" ]; then
    echo "  [FAIL] Temporary file found outside .local/:"
    printf '%s\n' "$FAIL_MATCHES" | while IFS= read -r f; do
        echo "    $f (should be moved to .local/)"
    done
    FAIL=1
fi

if [ -n "$WARN_MATCHES" ]; then
    echo "  [WARN] Possibly-temporary file name outside .local/ — review (§16.2 defines the category by role, not by name; ordinary words also name permanent modules):"
    printf '%s\n' "$WARN_MATCHES" | while IFS= read -r f; do
        echo "    $f"
    done
fi

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

# Standard root documents are permanent community artifacts, not §16.2
# local/temporary files. §17.1 (README) and §17.2 (docs/)
# govern the tracked documentation system, and §17.2 draws the
# docs-vs-.local/ boundary; §16.2 defines what must live in .local/.
# Whitelist CONTRIBUTING.md / CODE_OF_CONDUCT.md, alongside the existing
# README.md / CLAUDE.md / CHANGELOG.md exclusions, so a normal open-source
# project does not get a meaningless warning.
ROOT_SUSPECT_FILES=$(echo "$TRACKED_FILES" | grep -E '^[A-Z_]{4,}\.md$' 2>/dev/null | \
    grep -v '^README\.md$' | grep -v '^CLAUDE\.md$' | grep -v '^LICENSE$' | \
    grep -v '^CHANGELOG\.md$' | grep -v '^CONTRIBUTING\.md$' | \
    grep -v '^CODE_OF_CONDUCT\.md$' || true)

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
