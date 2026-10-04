#!/usr/bin/env bash
# check_legacy_cleanup.sh — Detect technical debt anti-patterns per §18.1
# Part of BADGE Constitution §18.1, §18.2
# Opt-in vendored manifest documentation: docs/opt-in-exemptions.md
#
# Checks for:
#   - legacy/ or deprecated/ directories
#   - v2, new, legacy naming prefixes/suffixes in files
#   - Stale TODO/FIXME comments referencing removal plans
#   - Compatibility shims with "backward compat" patterns
#
# Opt-in vendored/upstream declaration (.badge/vendored.txt):
#   §18.1 governs FIRST-PARTY architecture. Third-party / upstream code carried
#   in-tree legitimately contains phrases like "backward compatibility" or
#   `legacy_`-style names that must not be flagged. A project may declare those
#   paths in a repo-root manifest:
#
#       .badge/vendored.txt    one repository-relative path PREFIX per line;
#                              `#` starts a comment; blank lines are ignored.
#       e.g.                   src/isaaclab/
#                              vendor/
#
#   The manifest is opt-in: when it does not exist the scan is byte-for-byte
#   what it was before. Skips are never silent — the skipped paths and the
#   count are printed. A declared prefix that matches no tracked file is a WARN
#   (stale or misspelled declaration). No path is auto-guessed.
#
#   Guardrails (a declaration must not switch the check off):
#     * a prefix that covers a first-level OWN source directory
#       (src/, tests/, scripts/, docker/, tools/) is refused with a blocking
#       [FAIL] and is not applied — §18.1 governs first-party code;
#     * a declaration that removes every .py file from the scan is refused with
#       a blocking [FAIL];
#     * a prefix that would cover the whole repository (`.` etc.) is refused.
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

# ─── 0. Opt-in vendored/upstream declaration (§18.1) ────────────────────
# See the header for the manifest format. Absent file ⇒ this block prints
# nothing and TRACKED_FILES is untouched (the pre-existing behaviour).
VENDORED_MANIFEST="$PROJECT_ROOT/.badge/vendored.txt"
# First-level own source directories. §18.1 governs first-party architecture;
# a declaration covering one of these would switch the check off for the
# project's own code, so such an entry is refused (blocking) and never applied.
VENDORED_PROTECTED_DIRS='src tests scripts docker tools'
VENDORED_PREFIXES=""
if [ -f "$VENDORED_MANIFEST" ]; then
    while IFS= read -r vline || [ -n "$vline" ]; do
        vline="${vline%$'\r'}"
        vline="${vline%%[[:space:]]#*}"                  # drop inline comment
        vline="${vline#"${vline%%[![:space:]]*}"}"       # ltrim
        vline="${vline%"${vline##*[![:space:]]}"}"       # rtrim
        case "$vline" in ''|'#'*) continue ;; esac       # blank / full-line comment
        case "$vline" in
            /*|*..*)
                echo "  [WARN] .badge/vendored.txt: ignoring non-relative/unsafe prefix '$vline'"
                continue ;;
        esac
        # Normalise for the guardrail tests: strip a leading './' and a trailing
        # '/', so 'src', 'src/' and './src/' are all recognised.
        vnorm="${vline#./}"
        vnorm="${vnorm%/}"
        case "$vnorm" in
            ''|.|..)
                echo "[FAIL] check_legacy_cleanup: .badge/vendored.txt: prefix '$vline' would cover every tracked file — refused (§18.1 must still inspect first-party code)."
                FAIL=1
                continue ;;
        esac
        case " $VENDORED_PROTECTED_DIRS " in
            *" $vnorm "*)
                echo "[FAIL] check_legacy_cleanup: .badge/vendored.txt: prefix '$vline' covers the project's own first-level source directory — refused (§18.1 governs first-party code)."
                FAIL=1
                continue ;;
        esac
        VENDORED_PREFIXES+="$vline"$'\n'
    done < "$VENDORED_MANIFEST"
    VENDORED_PREFIXES=$(printf '%s' "$VENDORED_PREFIXES" | sed '/^$/d')
fi

if [ -n "$VENDORED_PREFIXES" ]; then
    # Guardrail base: the set of files the §18.1 scans actually inspect (.py),
    # measured BEFORE filtering. Comparing against *all* tracked files made the
    # old "covers the whole repository" warning unreachable (README, pyproject
    # and the manifest itself always kept that count above zero).
    VENDORED_SCAN_BEFORE=$(printf '%s\n' "$TRACKED_FILES" | grep -E '\.py$' | grep -c '.' || true)
    VENDORED_SKIPPED=""
    VENDORED_KEPT=""
    while IFS= read -r tracked || [ -n "$tracked" ]; do
        [ -n "$tracked" ] || continue
        vmatch=""
        while IFS= read -r vp; do
            [ -n "$vp" ] || continue
            case "$tracked" in
                "$vp"*) vmatch="$vp"; break ;;
            esac
        done <<< "$VENDORED_PREFIXES"
        if [ -n "$vmatch" ]; then
            VENDORED_SKIPPED+="$tracked"$'\n'
        else
            VENDORED_KEPT+="$tracked"$'\n'
        fi
    done <<< "$TRACKED_FILES"
    TRACKED_FILES="${VENDORED_KEPT%$'\n'}"
    VENDORED_SKIPPED="${VENDORED_SKIPPED%$'\n'}"
    VENDORED_SKIP_COUNT=$(printf '%s\n' "$VENDORED_SKIPPED" | grep -c '.' || true)
    VENDORED_SCAN_AFTER=$(printf '%s\n' "$TRACKED_FILES" | grep -E '\.py$' | grep -c '.' || true)

    if [ "$VENDORED_SKIP_COUNT" -gt 0 ]; then
        echo "  [INFO] §18.1 scope: skipped $VENDORED_SKIP_COUNT vendored file(s) declared in .badge/vendored.txt:"
        printf '%s\n' "$VENDORED_SKIPPED" | sed -n '1,20p' | while IFS= read -r f; do
            [ -n "$f" ] && echo "    $f"
        done
        [ "$VENDORED_SKIP_COUNT" -gt 20 ] && echo "    ... and $((VENDORED_SKIP_COUNT - 20)) more"
    fi

    # Refuse a declaration that leaves the §18.1 scan with nothing to inspect:
    # that is a one-line switch to disable the check for the whole repository.
    if [ "$VENDORED_SCAN_BEFORE" -gt 0 ] && [ "$VENDORED_SCAN_AFTER" -eq 0 ]; then
        echo "[FAIL] check_legacy_cleanup: .badge/vendored.txt removes every .py file from the §18.1 scan ($VENDORED_SCAN_BEFORE → 0) — refusing to disable the check."
        FAIL=1
    fi

    # Reverse guardrail: a declared prefix that matched nothing is stale or
    # misspelled. Report each so the declaration cannot silently rot.
    while IFS= read -r vp; do
        [ -n "$vp" ] || continue
        if ! printf '%s\n' "$VENDORED_SKIPPED" | grep -qF -- "$vp"; then
            echo "  [WARN] .badge/vendored.txt: declared prefix matched no tracked file (stale or misspelled): $vp"
        fi
    done <<< "$VENDORED_PREFIXES"
fi

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
