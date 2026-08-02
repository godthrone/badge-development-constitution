#!/usr/bin/env bash
# check_docs_ascii.sh — Detect ASCII-art diagrams in documentation per §17.2.
# Part of BADGE Constitution §17.2
#
# §17.2: "All diagrams in documentation must be drawn with Mermaid — ASCII
# hand-drawn diagrams are prohibited."
#
# Scans docs/**/*.md and README*.md for box-drawing characters. Warn-only:
# directory trees and tables are plain-text structures, not diagrams, and are
# allowed (§17.2) — so hits must be reviewed by a human.
#
# Usage: ./check_docs_ascii.sh [project_root]

set -euo pipefail

PROJECT_ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || echo '.')}"
cd "$PROJECT_ROOT"

if ! git rev-parse --git-dir &>/dev/null 2>&1; then
    echo "[SKIP] check_docs_ascii: Not a git repository."
    exit 0
fi

MD_FILES=$(git ls-files --cached --others --exclude-standard 2>/dev/null | \
    grep -E '(^docs/.*\.md$|^README(\.zh-CN)?\.md$)' || true)

if [ -z "$MD_FILES" ]; then
    echo "[PASS] check_docs_ascii: No documentation files to check."
    exit 0
fi

HITS=$(echo "$MD_FILES" | xargs grep -n '├\|└\|│\|─\|┌\|┐\|┘\|┴\|┬\|┼\|═\|║' 2>/dev/null || true)

if [ -z "$HITS" ]; then
    echo "[PASS] check_docs_ascii: No box-drawing characters in documentation."
    exit 0
fi

echo "[WARN] check_docs_ascii: Box-drawing characters found in documentation (review — §17.2 requires Mermaid for diagrams; directory trees and tables are allowed):"
echo "$HITS" | head -40
if [ "$(echo "$HITS" | grep -c '.' || true)" -gt 40 ]; then
    echo "  ... and more"
fi
echo "         §17.2: all diagrams must be Mermaid; node names wrapped in English double quotes."

# Warn-only: directory trees and tables are legitimate plain-text structures
exit 0
