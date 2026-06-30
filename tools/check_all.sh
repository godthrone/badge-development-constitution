#!/usr/bin/env bash
# check_all.sh — Run all BADGE Constitution compliance checks
# Part of BADGE Constitution v1.6.0
#
# Usage: ./check_all.sh [project_root]
#   project_root defaults to the git repo root of the current directory.
#
# Exit code: 0 if all checks pass, 1 if any check fails.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || echo '.')}"

echo "============================================"
echo " BADGE Constitution v1.6.0 — Compliance Check"
echo " Project: $PROJECT_ROOT"
echo "============================================"
echo ""

PASS_COUNT=0
FAIL_COUNT=0
FAILED_CHECKS=()

run_check() {
    local name="$1"
    local script="$2"
    echo "── $name ──"
    if "$script" "$PROJECT_ROOT"; then
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        FAIL_COUNT=$((FAIL_COUNT + 1))
        FAILED_CHECKS+=("$name")
    fi
    echo ""
}

# Run all checks
run_check "Secrets Scan (§15.1)"           "$SCRIPT_DIR/check_secrets.sh"
run_check ".gitignore Coverage (§19.2)"     "$SCRIPT_DIR/check_gitignore.sh"
run_check "README Parity (§17.1)"           "$SCRIPT_DIR/check_readme_parity.sh"
run_check "Version Single Source (§8.7)"    "$SCRIPT_DIR/check_version.sh"
run_check "Temporary Files (§XVI)"          "$SCRIPT_DIR/check_local_files.sh"

# ─── Summary ──────────────────────────────────────────────────────────────

echo "============================================"
echo " Summary"
echo "============================================"
echo "  Passed: $PASS_COUNT"
echo "  Failed: $FAIL_COUNT"

if [ $FAIL_COUNT -gt 0 ]; then
    echo ""
    echo "  Failed checks:"
    for check in "${FAILED_CHECKS[@]}"; do
        echo "    - $check"
    done
    echo ""
    echo "[FAIL] Some checks failed. Fix the issues above before committing."
    exit 1
else
    echo ""
    echo "[PASS] All checks passed."
fi