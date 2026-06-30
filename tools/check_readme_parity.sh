#!/usr/bin/env bash
# check_readme_parity.sh — Verify README.md and README.zh-CN.md are content mirrors
# Part of BADGE Constitution v1.6.0 §17.1
#
# Usage: ./check_readme_parity.sh [project_root]

set -euo pipefail

PROJECT_ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || echo '.')}"
cd "$PROJECT_ROOT"

README_EN="$PROJECT_ROOT/README.md"
README_CN="$PROJECT_ROOT/README.zh-CN.md"

FAIL=0

if [ ! -f "$README_EN" ]; then
    echo "[FAIL] check_readme_parity: README.md not found."
    exit 1
fi
if [ ! -f "$README_CN" ]; then
    echo "[FAIL] check_readme_parity: README.zh-CN.md not found."
    exit 1
fi

echo "Checking README parity..."

# ─── 1. Section count ────────────────────────────────────────────────────

EN_SECTIONS=$(grep -c '^## ' "$README_EN" 2>/dev/null || echo 0)
CN_SECTIONS=$(grep -c '^## ' "$README_CN" 2>/dev/null || echo 0)

if [ "$EN_SECTIONS" != "$CN_SECTIONS" ]; then
    echo "  [FAIL] Section count mismatch: EN=$EN_SECTIONS, CN=$CN_SECTIONS"
    FAIL=1
else
    echo "  [OK] Section count: $EN_SECTIONS sections in both"
fi

# ─── 2. Required sections ────────────────────────────────────────────────

# Per §17.1: Introduction → Quick Start → Data Format → Config Reference →
#              Output Description → Development Guide → FAQ
# We check for key terms that should appear in both versions.

REQUIRED_TERMS_EN=(
    "Quick Start"
    "Data Format"
    "Configuration"
    "Output"
    "Development"
    "FAQ"
    "License"
)

REQUIRED_TERMS_CN=(
    "快速开始"
    "数据格式"
    "配置"
    "输出"
    "开发"
    "常见问题"
    "License"
)

echo "Checking required sections..."

for i in "${!REQUIRED_TERMS_EN[@]}"; do
    EN_TERM="${REQUIRED_TERMS_EN[$i]}"
    CN_TERM="${REQUIRED_TERMS_CN[$i]}"

    if ! grep -q "$EN_TERM" "$README_EN" 2>/dev/null; then
        echo "  [FAIL] EN README missing section: $EN_TERM"
        FAIL=1
    fi
    if ! grep -q "$CN_TERM" "$README_CN" 2>/dev/null; then
        echo "  [FAIL] CN README missing section: $CN_TERM"
        FAIL=1
    fi
done

# ─── 3. Code block count (rough content parity check) ────────────────────

EN_CODE_BLOCKS=$(grep -c '```' "$README_EN" 2>/dev/null || echo 0)
CN_CODE_BLOCKS=$(grep -c '```' "$README_CN" 2>/dev/null || echo 0)
# Code blocks come in pairs (open/close), so compare pair counts
EN_PAIRS=$((EN_CODE_BLOCKS / 2))
CN_PAIRS=$((CN_CODE_BLOCKS / 2))

if [ "$EN_PAIRS" != "$CN_PAIRS" ]; then
    echo "  [WARN] Code block count differs: EN=$EN_PAIRS pairs, CN=$CN_PAIRS pairs"
    echo "         This may indicate content differences. Review manually."
else
    echo "  [OK] Code block count: $EN_PAIRS pairs in both"
fi

# ─── 4. Cross-reference check ────────────────────────────────────────────

# EN should link to CN, and vice versa. Check for the link text.
if grep -q 'README.zh-CN.md' "$README_EN" 2>/dev/null; then
    echo "  [OK] EN README links to CN version"
else
    echo "  [WARN] EN README does not link to README.zh-CN.md"
fi

if grep -q 'README.md' "$README_CN" 2>/dev/null; then
    echo "  [OK] CN README links to EN version"
else
    echo "  [WARN] CN README does not link to README.md"
fi

# ─── 5. No Changelog section (per §17.4) ──────────────────────────────────

if grep -qi 'Changelog\|更新日志' "$README_EN" 2>/dev/null; then
    echo "  [FAIL] EN README contains Changelog section (remove per §17.4)."
    FAIL=1
fi
if grep -qi 'Changelog\|更新日志' "$README_CN" 2>/dev/null; then
    echo "  [FAIL] CN README contains Changelog section (remove per §17.4)."
    FAIL=1
fi

echo ""
if [ $FAIL -eq 0 ]; then
    echo "[PASS] check_readme_parity: READMEs are consistent."
else
    echo "[FAIL] check_readme_parity: Issues found."
fi
exit $FAIL