#!/usr/bin/env bash
# check_legacy_cleanup.sh — Detect technical debt anti-patterns per §18.1
# Part of BADGE Constitution §18.1, §18.2
#
# Checks for:
#   - legacy/ or deprecated/ directories
#   - v2, new, legacy naming prefixes/suffixes in files
#   - Stale TODO/FIXME comments referencing removal plans
#   - Compatibility shims with "backward compat" patterns
#
# Usage: ./check_legacy_cleanup.sh [project_root]

set -euo pipefail

PROJECT_ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || echo '.')}"
cd "$PROJECT_ROOT"

FAIL=0

if ! git rev-parse --git-dir &>/dev/null 2>&1; then
    echo "[SKIP] check_legacy_cleanup: Not a git repository."
    exit 0
fi

TRACKED_FILES=$(git ls-files --cached --others --exclude-standard 2>/dev/null | \
    grep -v 'badge-development-constitution/' | \
    grep -v '^tools/' || true)

echo "Checking for technical debt..."

# ─── 1. Legacy/deprecated directories ───────────────────────────────────

LEGACY_DIRS=$(echo "$TRACKED_FILES" | grep -E '(^|/)legacy/' 2>/dev/null | head -10 || true)
DEPRECATED_DIRS=$(echo "$TRACKED_FILES" | grep -E '(^|/)deprecated/' 2>/dev/null | head -10 || true)

if [ -n "$LEGACY_DIRS" ]; then
    echo "[FAIL] check_legacy_cleanup: legacy/ directory found (delete old architecture per §18.1):"
    echo "$LEGACY_DIRS" | while IFS= read -r f; do echo "  $f"; done
    FAIL=1
fi

if [ -n "$DEPRECATED_DIRS" ]; then
    echo "[FAIL] check_legacy_cleanup: deprecated/ directory found (delete old architecture per §18.1):"
    echo "$DEPRECATED_DIRS" | while IFS= read -r f; do echo "  $f"; done
    FAIL=1
fi

# ─── 2. Naming anti-patterns (v2, new, legacy prefixes/suffixes) ───────

NAMING_ANTI_PATTERNS=(
    '_v2\.py$'
    '_v3\.py$'
    '_new\.py$'
    '_old\.py$'
    '_legacy\.py$'
    '/v2/'
    '/legacy/'
    'legacy_'
    'Legacy[A-Z]'
)

for pattern in "${NAMING_ANTI_PATTERNS[@]}"; do
    NAMING_ISSUES=$(echo "$TRACKED_FILES" | grep -E "$pattern" 2>/dev/null | \
        grep -v 'migrate_v[0-9]_to_v[0-9]' | \
        grep -v '__pycache__' | head -10 || true)
    if [ -n "$NAMING_ISSUES" ]; then
        echo "[FAIL] check_legacy_cleanup: Naming anti-pattern ($pattern) — remove version/legacy suffixes per §18.1:"
        echo "$NAMING_ISSUES" | while IFS= read -r f; do
            echo "  $f"
        done
        FAIL=1
    fi
done

# ─── 3. Stale TODO/FIXME about removal ──────────────────────────────────

STALE_TODOS=$(echo "$TRACKED_FILES" | grep -E '\.(py|yaml|yml|sh)$' | \
    xargs grep -nE '(TODO|FIXME|HACK).*remove after' 2>/dev/null | \
    grep -v 'badge-development-constitution/' | head -10 || true)

if [ -n "$STALE_TODOS" ]; then
    echo "[FAIL] check_legacy_cleanup: TODO/FIXME comments about removal found (delete now, not later §18.1):"
    echo "$STALE_TODOS" | while IFS= read -r line; do
        echo "  $line"
    done
    FAIL=1
fi

# ─── 4. Compatibility mode / backward compat patterns ───────────────────

COMPAT_PATTERNS=$(echo "$TRACKED_FILES" | grep -E '\.py$' | \
    xargs grep -nE '(backward.?compat|compat(ibility)?.?mode|COMPAT_MODE|deprecated.*kept.*for)' 2>/dev/null | \
    grep -v 'badge-development-constitution/' | head -10 || true)

if [ -n "$COMPAT_PATTERNS" ]; then
    echo "[FAIL] check_legacy_cleanup: Compatibility mode code found (delete old architecture per §18.1):"
    echo "$COMPAT_PATTERNS" | while IFS= read -r line; do
        echo "  $line"
    done
    FAIL=1
fi

# ─── 5. Check for migration scripts (they're OK, just note them) ───────

MIGRATION_SCRIPTS=$(echo "$TRACKED_FILES" | grep -E 'migrate.*v[0-9]_to_v[0-9]' 2>/dev/null | head -10 || true)
if [ -n "$MIGRATION_SCRIPTS" ]; then
    echo "  [INFO] Migration scripts found (allowed per §18.2):"
    echo "$MIGRATION_SCRIPTS" | while IFS= read -r f; do echo "    $f"; done
fi

echo ""
if [ $FAIL -eq 0 ]; then
    echo "[PASS] check_legacy_cleanup: No technical debt detected."
else
    echo "[FAIL] check_legacy_cleanup: Technical debt found — delete old architecture."
fi
exit $FAIL
