#!/usr/bin/env bash
# check_dependencies.sh — Verify dependency management conventions
# Part of BADGE Constitution §14.1 (license), §14.2 (uv), §19.3 (license file)
#
# Checks for:
#   - No requirements.txt, Pipfile, poetry.lock, Pipfile.lock
#   - uv.lock exists and is tracked
#   - pyproject.toml exists
#   - .python-version exists
#   - LICENSE file exists
#   - No copyleft-licensed packages in dependencies (offline: reads installed
#     *.dist-info/METADATA under .venv/; FAIL for strong copyleft, WARN for
#     weak copyleft / unclassifiable; BADGE_LICENSE_STRICT=1 fails weak too.
#     Never claims [OK] when no metadata could be inspected.)
#
# Usage: ./check_dependencies.sh [project_root]

set -euo pipefail

PROJECT_ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || echo '.')}"
cd "$PROJECT_ROOT"

FAIL=0

if ! git rev-parse --git-dir &>/dev/null 2>&1; then
    echo "[SKIP] check_dependencies: Not a git repository."
    exit 0
fi

TRACKED_FILES=$(git ls-files --cached 2>/dev/null || true)

echo "Checking dependency management..."

# ─── 1. Forbidden dependency declaration files (§14.2) ──────
#
# §14.2: uv 是唯一包管理器；pyproject.toml + uv.lock 构成依赖的唯一真相源
#   ——"不存在其他依赖声明"。
# §14.2 明文点名：不设 `requirements.txt`、`Pipfile`、环境变量覆盖依赖版本。
# 下表：前两项为条文点名；其余是"另一份依赖声明 / 另一套包管理器"的直接推论
# （依据同一条 §14.2 的"唯一包管理器 + 不存在其他依赖声明"）。

FORBIDDEN_FILES=(
    "requirements.txt"   # 明文点名
    "Pipfile"            # 明文点名
    "Pipfile.lock"       # Pipfile 的锁文件 = 另一份依赖真相源
    "poetry.lock"        # 另一套包管理器的锁文件
    "conda.env"          # conda 环境声明，非 uv
    "environment.yml"    # conda 环境声明，非 uv
    "setup.py"           # 另一份依赖声明（install_requires）
    "setup.cfg"          # 另一份依赖声明
)

for forbidden in "${FORBIDDEN_FILES[@]}"; do
    if echo "$TRACKED_FILES" | grep -qxF "$forbidden" 2>/dev/null; then
        echo "[FAIL] check_dependencies: $forbidden found — use uv + pyproject.toml only (§14.2)."
        FAIL=1
    fi
done

# Also catch requirements*.txt variants, including files in subdirectories
# (e.g. requirements-dev.txt, requirements/base.txt). The previous form ended
# with `grep -v 'requirements'`, which discarded every match that had just been
# selected — permanently dead code.
EXTRA_REQS=$(echo "$TRACKED_FILES" | grep -E '(^|/)requirements.*\.txt$' 2>/dev/null | \
    grep -vxF 'requirements.txt' || true)
if [ -n "$EXTRA_REQS" ]; then
    echo "[FAIL] check_dependencies: requirements*.txt files found:"
    echo "$EXTRA_REQS" | while IFS= read -r f; do echo "  $f"; done
    FAIL=1
fi

# ─── 2. Required files ──────────────────────────────────────────────────

REQUIRED_FILES=(
    "pyproject.toml:pyproject.toml"
    "uv.lock:uv.lock"
    ".python-version:.python-version"
)

for entry in "${REQUIRED_FILES[@]}"; do
    path="${entry%%:*}"
    label="${entry##*:}"
    if echo "$TRACKED_FILES" | grep -qxF "$path" 2>/dev/null; then
        echo "  [OK] $label exists and is tracked"
    else
        # .python-version is a SHOULD, not MUST
        if [ "$path" = ".python-version" ]; then
            echo "  [WARN] $label not found — recommend adding to pin Python version (§14.2)"
        else
            echo "[FAIL] check_dependencies: $label not found or not tracked (§14.2)."
            FAIL=1
        fi
    fi
done

# ─── 3. LICENSE file ────────────────────────────────────────────────────

LICENSE="$PROJECT_ROOT/LICENSE"
if [ -f "$LICENSE" ]; then
    echo "  [OK] LICENSE file exists"
    # Quick check: does it look like MIT or Apache?
    if head -5 "$LICENSE" 2>/dev/null | grep -qiE 'MIT|Apache'; then
        echo "  [OK] LICENSE appears to be MIT or Apache 2.0"
    else
        echo "  [WARN] LICENSE content not recognized as MIT/Apache — verify manually (§19.3)."
    fi
else
    echo "[FAIL] check_dependencies: LICENSE file not found (§19.3)."
    FAIL=1
fi

# ─── 4. Copyleft dependency check (§14.1, offline) ──────────────────────
#
# Data source: the distribution metadata that `uv sync` writes into the virtual
# environment — `*.dist-info/METADATA`, fields `License-Expression:` (PEP 639),
# `License:` (legacy) and `Classifier: License :: OSI Approved :: …`.
#
# `uv.lock` is NOT a data source. uv 0.11.7 emits no `license` field for any
# package, so the old `grep '^license = "…"'` on uv.lock could never match and
# still printed "[OK] No obvious copyleft dependencies" — a false pass that hid
# every copyleft dependency. When nothing can be inspected this check now says
# so explicitly and never claims [OK].
#
# This check is strictly OFFLINE: no registry / HTTP lookup is performed.
#
# Severity (§14.1):
#   FAIL — strong copyleft (GPL, AGPL, SSPL, GNU General Public License, …),
#          which §14.1 names as forbidden.
#   WARN — weak copyleft (LGPL, MPL, EPL, CDDL, EUPL, OSL, CC-BY-SA/NC, …) and
#          every license whose text cannot be classified (unknown text).
#          BADGE_LICENSE_STRICT=1 upgrades the weak-copyleft WARN to FAIL;
#          unknown/unclassifiable licenses stay WARN under the strict switch.
#   [OK] is printed only when distributions were actually inspected and none
#          carried a copyleft / unclassifiable license.

# Strong copyleft: the boundary before (A?)GPL is `[^[:alpha:]]`, so the "GPL"
# inside "LGPL" can never match here (the preceding char is the letter L). The
# weak pattern is still tested first, so an expression that names both remains
# correctly classified.
_LICENSE_STRONG_RE='(^|[^[:alpha:]])(A?GPL|SSPL)([^[:alpha:]]|$)|GNU General Public License|Server Side Public License'
_LICENSE_WEAK_RE='LGPL|Lesser General Public License|MPL|Mozilla Public License|EPL|Eclipse Public License|CDDL|Common Development and Distribution License|EUPL|European Union Public Licen[cs]e|CC-BY-(SA|NC)|OSL|CECILL|CPL'
_LICENSE_PERMISSIVE_RE='MIT|Apache|BSD|ISC|PSF|Python Software Foundation|Unlicense|0BSD|Zlib|CC0|BlueOak|Public Domain|Boost|Artistic'

# Classify a free-form license string. Echoes STRONG | WEAK | PERMISSIVE | UNKNOWN.
# Order matters: the weak (LGPL/MPL) test runs before the strong (GPL) test so
# that "LGPL-2.1" is never mistaken for "GPL" by substring matching.
_license_class() {
    local t="$1"
    if printf '%s' "$t" | grep -qiE "$_LICENSE_WEAK_RE"; then
        printf '%s' "$t" | grep -qiE "$_LICENSE_STRONG_RE" && { echo STRONG; return; }
        echo WEAK; return
    fi
    printf '%s' "$t" | grep -qiE "$_LICENSE_STRONG_RE" && { echo STRONG; return; }
    printf '%s' "$t" | grep -qiE "$_LICENSE_PERMISSIVE_RE" && { echo PERMISSIVE; return; }
    echo UNKNOWN
}

LICENSE_STRICT="${BADGE_LICENSE_STRICT:-0}"

# Candidate roots that may hold installed `*.dist-info` metadata. `.venv` first
# (uv's default), then any explicitly pointed-to environment.
LICENSE_ROOTS=()
[ -d "$PROJECT_ROOT/.venv" ] && LICENSE_ROOTS+=("$PROJECT_ROOT/.venv")
[ -n "${VIRTUAL_ENV:-}" ] && [ -d "${VIRTUAL_ENV:-}" ] && LICENSE_ROOTS+=("${VIRTUAL_ENV}")
[ -n "${UV_PROJECT_ENVIRONMENT:-}" ] && [ -d "${UV_PROJECT_ENVIRONMENT:-}" ] && LICENSE_ROOTS+=("${UV_PROJECT_ENVIRONMENT}")

LICENSE_META=""
for root in "${LICENSE_ROOTS[@]}"; do
    LICENSE_META+="$(find "$root" -type f -path '*.dist-info/METADATA' -not -path '*/.git/*' 2>/dev/null || true)"$'\n'
done
# Local `*.dist-info` dirs sitting in the project tree (opt-in fallback), shallow
# depth so the scan stays cheap on repositories with large ignored trees.
LICENSE_META+="$(find "$PROJECT_ROOT" -maxdepth 3 -type f -path '*.dist-info/METADATA' \
    -not -path '*/.git/*' -not -path '*/.venv/*' 2>/dev/null || true)"$'\n'
LICENSE_META=$(printf '%s\n' "$LICENSE_META" | sed '/^$/d' | sort -u)

LICENSE_TOTAL=0
LICENSE_STRONG_LIST=""
LICENSE_WEAK_LIST=""
LICENSE_UNKNOWN_LIST=""

if [ -n "$LICENSE_META" ]; then
    while IFS= read -r meta_file; do
        [ -n "$meta_file" ] || continue
        LICENSE_TOTAL=$((LICENSE_TOTAL + 1))
        pkg=$(grep -m1 -E '^Name:' "$meta_file" 2>/dev/null | sed -E 's/^Name:[[:space:]]*//' || true)
        ver=$(grep -m1 -E '^Version:' "$meta_file" 2>/dev/null | sed -E 's/^Version:[[:space:]]*//' || true)
        expr=$(grep -m1 -E '^License-Expression:' "$meta_file" 2>/dev/null | sed -E 's/^License-Expression:[[:space:]]*//' || true)
        legacy=$(grep -m1 -E '^License:' "$meta_file" 2>/dev/null | sed -E 's/^License:[[:space:]]*//' || true)
        classif=$(grep -E '^Classifier:[[:space:]]*License[[:space:]]*::' "$meta_file" 2>/dev/null | \
            sed -E 's/^Classifier:[[:space:]]*//' | tr '\n' '; ' || true)
        # Prefer the structured field for display, but classify on all of them.
        shown="$expr"; [ -z "$shown" ] && shown="$legacy"; [ -z "$shown" ] && shown="$classif"
        shown="${shown%; }"; [ -n "$shown" ] || shown="(no license field)"
        [ -n "$pkg" ] || pkg="(unknown)"
        [ -n "$ver" ] || ver="?"
        cls=$(_license_class "$expr | $legacy | $classif")
        # A dual expression with a usable permissive branch ("MIT OR GPL-3.0")
        # is not a hard fail: the package can be used under the permissive
        # branch. Still reported, as a WARN, so the choice is visible.
        if [ "$cls" = "STRONG" ] && printf '%s' "$shown" | grep -q ' OR ' && \
           printf '%s' "$shown" | grep -qiE "$_LICENSE_PERMISSIVE_RE"; then
            cls="WEAK"
        fi
        case "$cls" in
            STRONG)  LICENSE_STRONG_LIST+="  $pkg@$ver → $shown"$'\n' ;;
            WEAK)    LICENSE_WEAK_LIST+="  $pkg@$ver → $shown"$'\n' ;;
            UNKNOWN) LICENSE_UNKNOWN_LIST+="  $pkg@$ver → $shown"$'\n' ;;
            *)       : ;;
        esac
    done <<< "$LICENSE_META"
fi

if [ "$LICENSE_TOTAL" -eq 0 ]; then
    echo "  [WARN] §14.1 not verified: cannot verify licenses — no installed distribution"
    echo "         metadata (*.dist-info/METADATA) was found (looked in .venv/,"
    echo "         \$VIRTUAL_ENV, \$UV_PROJECT_ENVIRONMENT and local *.dist-info dirs)."
    echo "         Run 'uv sync' so licenses can be inspected."
elif [ -n "$LICENSE_STRONG_LIST$LICENSE_WEAK_LIST$LICENSE_UNKNOWN_LIST" ]; then
    if [ -n "$LICENSE_STRONG_LIST" ]; then
        echo "[FAIL] check_dependencies: strong copyleft dependency found (§14.1 forbids GPL/AGPL and equivalents):"
        printf '%s' "$LICENSE_STRONG_LIST" | while IFS= read -r l; do echo "$l"; done
        FAIL=1
    fi
    if [ -n "$LICENSE_WEAK_LIST" ]; then
        if [ "$LICENSE_STRICT" = "1" ]; then
            echo "[FAIL] check_dependencies: weak copyleft dependency found (BADGE_LICENSE_STRICT=1 §14.1):"
            FAIL=1
        else
            echo "[WARN] check_dependencies: weak copyleft dependency found — review (§14.1;"
            echo "         set BADGE_LICENSE_STRICT=1 to turn this into a failure):"
        fi
        printf '%s' "$LICENSE_WEAK_LIST" | while IFS= read -r l; do echo "$l"; done
    fi
    if [ -n "$LICENSE_UNKNOWN_LIST" ]; then
        echo "[WARN] check_dependencies: license could not be classified for these distributions (§14.1) — review:"
        printf '%s' "$LICENSE_UNKNOWN_LIST" | while IFS= read -r l; do echo "$l"; done
    fi
    echo "  [INFO] §14.1: verified $LICENSE_TOTAL installed distribution(s); see the findings above."
else
    echo "  [OK] No copyleft among $LICENSE_TOTAL verified installed distribution(s) (§14.1)"
fi

# ─── 5. Check uv.lock is not manually edited (heuristic) ───────────────

if [ -f "$PROJECT_ROOT/uv.lock" ]; then
    # uv.lock header typically contains "# This file was autogenerated by uv"
    if head -3 "$PROJECT_ROOT/uv.lock" 2>/dev/null | grep -q 'autogenerated by uv'; then
        echo "  [OK] uv.lock is auto-generated (not manually edited)"
    fi
fi

echo ""
if [ $FAIL -eq 0 ]; then
    echo "[PASS] check_dependencies: Dependency management follows constitution."
else
    echo "[FAIL] check_dependencies: Issues found."
fi
exit $FAIL
