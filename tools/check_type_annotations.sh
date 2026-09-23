#!/usr/bin/env bash
# check_type_annotations.sh — Verify type annotation conventions per §12.1
# Part of BADGE Constitution §12.1
#
# Checks for:
#   - `Optional[str]` usage (advisory: prefer `str | None`, §12.1 rule 3)
#   - `Union[...]` usage (advisory only — the constitution has no Union clause)
#   - `py.typed` marker file existence
#   - `Dict[...]`, `List[...]`, `Tuple[...]` (should use built-in generics)
#
# Usage: ./check_type_annotations.sh [project_root]

set -euo pipefail

PROJECT_ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || echo '.')}"
cd "$PROJECT_ROOT"

FAIL=0

if ! git rev-parse --git-dir &>/dev/null 2>&1; then
    echo "[SKIP] check_type_annotations: Not a git repository."
    exit 0
fi

PY_FILES=$(git ls-files --cached --others --exclude-standard 2>/dev/null | \
    grep '\.py$' | grep -v '__pycache__/' | grep -v '\.egg-info/' | \
    grep -v 'badge-development-constitution/' || true)

if [ -z "$PY_FILES" ]; then
    echo "[PASS] check_type_annotations: No Python files to check."
    exit 0
fi

echo "Checking type annotation conventions..."

# ─── 1. Optional[str] → prefer str | None (advisory) ────────────────────
#
# §12.1 rule 3 (C:650): 可选类型统一使用 `X | None`（PEP 604）；但同句明确
# "`Optional` **仍可用**但不作为项目约定"。故 Optional[X] 不是违规写法，
# 只提示改用项目约定 —— 不置 FAIL。

OPTIONAL_USAGE=$(echo "$PY_FILES" | xargs grep -nE 'Optional\[[a-zA-Z]' 2>/dev/null | \
    grep -v '^\s*#' | grep -v 'badge-development-constitution/' | \
    grep -v 'check_type_annotations\.sh' || true)

if [ -n "$OPTIONAL_USAGE" ]; then
    echo "[WARN] check_type_annotations: Optional[X] found — allowed but not the project convention."
    echo "       Prefer X | None (PEP 604, §12.1 rule 3); 'Optional' 仍可用但不作为项目约定."
    echo "$OPTIONAL_USAGE" | while IFS= read -r line; do
        echo "  $line"
    done
fi

# ─── 2. Union[X, Y] → PEP 604 `X | Y` (advisory, no constitutional clause) ──
#
# 宪法全文没有 Union 条文（grep -n 'Union' BADGE-constitution-v2.5.0.zh-CN.md
# 为 0 命中）。§12.1 rule 3 只点名 Optional/`| None`，未覆盖 Union。故本项
# 不得引 "per §12.1" 作为依据，只能作为无条文支撑的风格提示，且不置 FAIL。

UNION_USAGE=$(echo "$PY_FILES" | xargs grep -nE 'Union\[[a-zA-Z]' 2>/dev/null | \
    grep -v '^\s*#' | grep -v 'badge-development-constitution/' || true)

if [ -n "$UNION_USAGE" ]; then
    echo "[WARN] check_type_annotations: Union[X, Y] found — style advisory only."
    echo "       The constitution has no Union clause; §12.1 rule 3 names only Optional."
    echo "       PEP 604 syntax (X | Y) is preferred for consistency, not required."
    echo "$UNION_USAGE" | while IFS= read -r line; do
        echo "  $line"
    done
fi

# ─── 3. Dict[...], List[...], Tuple[...] → use dict, list, tuple ────────

OLD_GENERICS=$(echo "$PY_FILES" | xargs grep -nE '\b(Dict|List|Tuple|Set|FrozenSet)\[' 2>/dev/null | \
    grep -v '^\s*#' | grep -v 'typing' | grep -v 'badge-development-constitution/' || true)

if [ -n "$OLD_GENERICS" ]; then
    echo "[WARN] Old-style generics found (Dict, List, Tuple, Set)."
    echo "       In Python 3.11+, use built-in generics: dict[X, Y], list[X], tuple[X, ...]"
    echo "$OLD_GENERICS" | head -20 | while IFS= read -r line; do
        echo "  $line"
    done
fi

# ─── 4. py.typed marker ─────────────────────────────────────────────────

# Find the package directory under src/
PY_TYPED=""
if [ -d "$PROJECT_ROOT/src" ]; then
    PY_TYPED=$(find "$PROJECT_ROOT/src" -name 'py.typed' -not -path '*.egg-info/*' 2>/dev/null | head -1 || true)
fi

if [ -n "$PY_TYPED" ]; then
    echo "  [OK] py.typed marker found: ${PY_TYPED#$PROJECT_ROOT/}"
else
    if [ -d "$PROJECT_ROOT/src" ]; then
        echo "  [FAIL] py.typed marker missing (PEP 561, required by §12.1)."
        echo "         Create an empty py.typed file in your package directory."
        FAIL=1
    else
        echo "  [INFO] No src/ directory — py.typed check skipped."
    fi
fi

echo ""
if [ $FAIL -eq 0 ]; then
    echo "[PASS] check_type_annotations: Type annotation conventions are followed."
else
    echo "[FAIL] check_type_annotations: Issues found."
fi
exit $FAIL
