#!/usr/bin/env bash
# check_readme_parity.sh — Verify README.md and README.zh-CN.md are content mirrors
# Part of BADGE Constitution §17.1
#
# Checks:
#   1. Both README files exist
#   2. Section count parity
#   3. Required sections present in both
#   4. Code block count parity
#   5. Image/link count parity
#   6. Cross-reference links present
#   7. Word count ratio (rough content volume check)
#   8. No Changelog section (§17.4)
#   9. Same version references in both
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

# ─── 3. Code block count ─────────────────────────────────────────────────

EN_CODE_BLOCKS=$(grep -c '```' "$README_EN" 2>/dev/null || echo 0)
CN_CODE_BLOCKS=$(grep -c '```' "$README_CN" 2>/dev/null || echo 0)
EN_PAIRS=$((EN_CODE_BLOCKS / 2))
CN_PAIRS=$((CN_CODE_BLOCKS / 2))

if [ "$EN_PAIRS" != "$CN_PAIRS" ]; then
    echo "  [WARN] Code block count differs: EN=$EN_PAIRS pairs, CN=$CN_PAIRS pairs"
    echo "         This may indicate content differences. Review manually."
else
    echo "  [OK] Code block count: $EN_PAIRS pairs in both"
fi

# ─── 4. Image/link count parity ──────────────────────────────────────────

EN_IMAGES=$(grep -oc '!\[.*\](.*)' "$README_EN" 2>/dev/null || echo 0)
CN_IMAGES=$(grep -oc '!\[.*\](.*)' "$README_CN" 2>/dev/null || echo 0)

if [ "$EN_IMAGES" != "$CN_IMAGES" ]; then
    echo "  [WARN] Image count differs: EN=$EN_IMAGES, CN=$CN_IMAGES"
fi

EN_LINKS=$(grep -oc '\[.*\](http[^)]*)\|\[.*\](\.\/[^)]*)\|\[.*\]([a-z]*\.md)' "$README_EN" 2>/dev/null || echo 0)
CN_LINKS=$(grep -oc '\[.*\](http[^)]*)\|\[.*\](\.\/[^)]*)\|\[.*\]([a-z]*\.md)' "$README_CN" 2>/dev/null || echo 0)

if [ "$EN_LINKS" != "$CN_LINKS" ]; then
    echo "  [WARN] Link count differs: EN=$EN_LINKS, CN=$CN_LINKS"
else
    echo "  [OK] Image and link counts match"
fi

# ─── 5. Cross-reference check ────────────────────────────────────────────

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

# ─── 6. Word count ratio check ───────────────────────────────────────────

EN_WORDS=$(wc -w < "$README_EN" 2>/dev/null || echo 0)
CN_WORDS=$(wc -w < "$README_CN" 2>/dev/null || echo 0)

# Chinese text typically has fewer "words" (characters) for the same content
# but wc -w counts whitespace-delimited tokens differently.
# We check that neither is less than 30% of the other.
if [ "$EN_WORDS" -gt 0 ] && [ "$CN_WORDS" -gt 0 ]; then
    if [ "$EN_WORDS" -gt "$CN_WORDS" ]; then
        RATIO=$((100 * CN_WORDS / EN_WORDS))
    else
        RATIO=$((100 * EN_WORDS / CN_WORDS))
    fi
    if [ "$RATIO" -lt 30 ]; then
        echo "  [WARN] Word count ratio is $RATIO% (large disparity)."
        echo "         EN: $EN_WORDS words, CN: $CN_WORDS words. Review manually."
    else
        echo "  [OK] Word count ratio: $RATIO% (EN=$EN_WORDS, CN=$CN_WORDS)"
    fi
fi

# ─── 7. No Changelog section (per §17.4) ─────────────────────────────────

if grep -qi 'Changelog\|更新日志' "$README_EN" 2>/dev/null; then
    echo "  [FAIL] EN README contains Changelog section (remove per §17.4)."
    FAIL=1
fi
if grep -qi 'Changelog\|更新日志' "$README_CN" 2>/dev/null; then
    echo "  [FAIL] CN README contains Changelog section (remove per §17.4)."
    FAIL=1
fi

# ─── 8. Version references consistency ───────────────────────────────────

EN_VERSION=$(grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' "$README_EN" 2>/dev/null | head -1 || true)
CN_VERSION=$(grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' "$README_CN" 2>/dev/null | head -1 || true)

if [ -n "$EN_VERSION" ] && [ -n "$CN_VERSION" ]; then
    if [ "$EN_VERSION" = "$CN_VERSION" ]; then
        echo "  [OK] Version references match: $EN_VERSION"
    else
        echo "  [FAIL] Version mismatch: EN=$EN_VERSION, CN=$CN_VERSION"
        FAIL=1
    fi
fi

echo ""
if [ $FAIL -eq 0 ]; then
    echo "[PASS] check_readme_parity: READMEs are consistent."
else
    echo "[FAIL] check_readme_parity: Issues found."
fi
exit $FAIL
