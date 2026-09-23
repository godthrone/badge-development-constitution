#!/usr/bin/env bash
# check_constitution_refs.sh — Scan tracked source files for constitution
# version references (forbidden by §8.7).
#
# Exempt: the constitution files themselves, docs/, CLAUDE.md and tools/
# (they are part of the constitution's own content, not consumer project code).
# The constitution-file exemption is version-independent on purpose: matching by
# exact filename broke when the version in the filename was bumped.
#
# Usage: ./check_constitution_refs.sh [project_root]

set -euo pipefail

PROJECT_ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || echo '.')}"
cd "$PROJECT_ROOT"

FAIL=0

# ─── Collect tracked source files ─────────────────────────────────────────

if ! git rev-parse --git-dir &>/dev/null; then
    echo "[SKIP] check_constitution_refs: Not a git repository."
    exit 0
fi

# Only check source files (Python, YAML, Markdown outside docs/, shell scripts)
FILES=$(git ls-files --cached --others --exclude-standard 2>/dev/null | \
    grep -E '\.(py|yaml|yml|md|sh)$' | \
    grep -v '^docs/' | \
    grep -v '^badge-development-constitution/' | \
    grep -v '^BADGE-constitution' | \
    grep -v 'CLAUDE\.md$' | \
    grep -v '^tools/' || true)

if [ -z "$FILES" ]; then
    echo "[PASS] check_constitution_refs: No source files to check."
    exit 0
fi

# ─── Scan for constitution version references ─────────────────────────────

# Patterns to detect (English + Chinese). §8.7 forbids embedding the
# constitution VERSION in source files, in any of its forms
# (`BADGE Constitution vX.Y`、`constitution vX.Y §Z.W` 或类似模式):
#   "BADGE Constitution v1.6"
#   "constitution v1.5 §8.1"
#   "BADGE 开发宪法 v1.5"
#   "开发宪法 1.5"
#   "Constitution v1.4 §13.2"
#   "v1.5 §8.1"  (version + section, without the word "constitution")
#   "BADGE-constitution"
# etc.
# Note: a version-less §-reference (e.g. "per §8.7") is NOT flagged — §8.7
# forbids *version* references, and the constitution's own tools use §-refs
# without versions. Only patterns that carry a version number are listed.
PATTERNS=(
    'BADGE Constitution v[0-9]'
    'BADGE Constitution [0-9]+\.[0-9]'
    'BADGE 开发宪法 v[0-9]'
    'BADGE 开发宪法 [0-9]+\.[0-9]'
    '开发宪法 v[0-9]+\.[0-9]'
    'constitution v[0-9]'
    'Constitution v[0-9]'
    '宪法 v[0-9]+\.[0-9]'
    'constitution@v[0-9]'
    'v[0-9]+\.[0-9]+\.[0-9]+[[:space:]]*§'
    'v[0-9]+\.[0-9]+[[:space:]]*§'
)

echo "Scanning for constitution version references in source files..."

MATCHES=""
for pattern in "${PATTERNS[@]}"; do
    FOUND=$(echo "$FILES" | xargs grep -nE "$pattern" 2>/dev/null || true)
    if [ -n "$FOUND" ]; then
        MATCHES="${MATCHES}${FOUND}"$'\n'
    fi
done

MATCHES=$(echo "$MATCHES" | grep -v '^$' | sort -u || true)

if [ -n "$MATCHES" ]; then
    echo "[FAIL] check_constitution_refs: Constitution version references found in source files (forbidden by §8.7):"
    echo "$MATCHES" | while IFS= read -r line; do
        [ -n "$line" ] && echo "  $line"
    done
    echo ""
    echo "  Remove the version number from these references."
    echo "  The constitution version is maintained only in the constitution repository."
    FAIL=1
else
    echo "  [OK] No constitution version references found."
fi

echo ""
if [ $FAIL -eq 0 ]; then
    echo "[PASS] check_constitution_refs: No constitution version references in source code."
else
    echo "[FAIL] check_constitution_refs: Issues found."
fi
exit $FAIL
