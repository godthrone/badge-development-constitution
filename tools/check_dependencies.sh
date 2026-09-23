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
#   - No copyleft-licensed packages in dependencies (heuristic)
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

# ─── 1. Forbidden dependency declaration files (§14.2 C:762, C:764) ──────
#
# §14.2 C:762: uv 是唯一包管理器；pyproject.toml + uv.lock 构成依赖的唯一真相源
#   ——"不存在其他依赖声明"。
# §14.2 C:764 明文点名：不设 `requirements.txt`、`Pipfile`、环境变量覆盖依赖版本。
# 下表：前两项为条文点名；其余是"另一份依赖声明 / 另一套包管理器"的直接推论
# （依据同一条 C:762 的"唯一包管理器 + 不存在其他依赖声明"）。

FORBIDDEN_FILES=(
    "requirements.txt"   # 明文点名（C:764）
    "Pipfile"            # 明文点名（C:764）
    "Pipfile.lock"       # Pipfile 的锁文件 = 另一份依赖真相源（C:762）
    "poetry.lock"        # 另一套包管理器的锁文件（C:762）
    "conda.env"          # conda 环境声明，非 uv（C:762）
    "environment.yml"    # conda 环境声明，非 uv（C:762）
    "setup.py"           # 另一份依赖声明（install_requires）（C:762）
    "setup.cfg"          # 另一份依赖声明（C:762）
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

# ─── 4. Copyleft dependency check (heuristic) ───────────────────────────

if [ -f "$PROJECT_ROOT/uv.lock" ]; then
    # uv.lock records each package as [[package]] with `name = "..."` and, when
    # the registry provides it, `license = "<SPDX>"`. A package *name* does not
    # encode its license, so the old `^name = "gpl` pattern could never match a
    # real package. Match the license field instead (§14.1 C:758 forbids GPL/AGPL
    # and equivalent copyleft licenses). A leading quote is required right before
    # the SPDX id so dual-licensed expressions like "MIT OR GPL-3.0" (usable under
    # MIT) are not flagged.
    COPYLEFT_PATTERNS='^[[:space:]]*license[[:space:]]*=.*"(A?GPL|LGPL|MPL|CC-BY-NC|EUPL|SSPL|CDDL|OSL)'
    COPYLEFT_DEPS=$(grep -iE "$COPYLEFT_PATTERNS" "$PROJECT_ROOT/uv.lock" 2>/dev/null || true)
    if [ -n "$COPYLEFT_DEPS" ]; then
        echo "[FAIL] check_dependencies: Possible copyleft-licensed dependency found (§14.1):"
        echo "$COPYLEFT_DEPS" | while IFS= read -r line; do
            echo "  $line"
        done
        FAIL=1
    else
        echo "  [OK] No obvious copyleft dependencies in uv.lock"
    fi
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
