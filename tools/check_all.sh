#!/usr/bin/env bash
# check_all.sh — Run all BADGE Constitution compliance checks
# Part of BADGE Constitution
#
# Usage: ./check_all.sh [project_root]
#   project_root defaults to the git repo root of the current directory.
#
# Exit code: 0 if all checks pass, 1 if any check fails.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || echo '.')}"

# Dynamically read version from the English constitution
VERSION=$(grep -oP 'BADGE Constitution v\K[0-9]+\.[0-9]+\.[0-9]+' "$SCRIPT_DIR/../BADGE-constitution.en.md" 2>/dev/null || echo "unknown")

echo "============================================"
echo " BADGE Constitution v$VERSION — Compliance Check"
echo " Project: $PROJECT_ROOT"
echo "============================================"
echo ""

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0
FAILED_CHECKS=()

run_check() {
    local name="$1"
    local script="$2"
    echo "── $name ──"
    # Capture exit code
    local exit_code=0
    "$script" "$PROJECT_ROOT" || exit_code=$?
    if [ $exit_code -eq 0 ]; then
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        FAIL_COUNT=$((FAIL_COUNT + 1))
        FAILED_CHECKS+=("$name")
    fi
    echo ""
}

# ============================================================================
# Layer 1: Design Philosophy
# ============================================================================

# §2.2 — Explicitness: hasattr / **kwargs misuse
run_check "hasattr / **kwargs Usage (§2.2)"   "$SCRIPT_DIR/check_hasattr_kwargs.sh"

# ============================================================================
# Layer 2: Engineering Standards
# ============================================================================

# §6 — Reproducible Environments
run_check "Reproducibility (§6)"               "$SCRIPT_DIR/check_reproducibility.sh"

# §7 — Configuration System
run_check "Configuration System (§7.1-7.3)"    "$SCRIPT_DIR/check_config_system.sh"

# §8.1 — Directory Layout
run_check "Directory Layout (§8.1)"            "$SCRIPT_DIR/check_directory_layout.sh"

# §8.2 — File Size
run_check "File Size (§8.2)"                   "$SCRIPT_DIR/check_file_size.sh"

# §8.6 — Imports
run_check "Absolute Imports (§8.6)"            "$SCRIPT_DIR/check_imports.sh"

# §8.6 — Future Annotations (warn-only)
run_check "Future Annotations (§8.6)"          "$SCRIPT_DIR/check_future_annotations.sh"

# §8.7 — Version Single Source
run_check "Version Single Source (§8.7)"       "$SCRIPT_DIR/check_version.sh"

# §9.1 — Pydantic Models
run_check "Pydantic Conventions (§9.1)"        "$SCRIPT_DIR/check_pydantic.sh"

# §11.2 — Test Structure
run_check "Test Structure (§11.2)"             "$SCRIPT_DIR/check_test_structure.sh"

# §12.1 — Type Annotations
run_check "Type Annotations (§12.1)"           "$SCRIPT_DIR/check_type_annotations.sh"

# §13.1 — Exception Handling
run_check "Exception Handling (§13.1)"         "$SCRIPT_DIR/check_exception_handling.sh"

# §13.3 — Log File Consistency
run_check "Log File Consistency (§13.3)"       "$SCRIPT_DIR/check_log_consistency.sh"

# §14.1, §14.2, §19.3 — Dependencies and License
run_check "Dependencies & License (§14.1-2, §19.3)" "$SCRIPT_DIR/check_dependencies.sh"

# §14.3 — Dockerfile Check
run_check "Dockerfile (§14.3)"                 "$SCRIPT_DIR/check_dockerfile.sh"

# §14.3 — Docker Image Version
run_check "Docker Image Version (§14.3)"       "$SCRIPT_DIR/check_docker_version.sh"

# ============================================================================
# Layer 3: Security and Project Governance
# ============================================================================

# §15.1 — Secrets Scan
run_check "Secrets Scan (§15.1)"               "$SCRIPT_DIR/check_secrets.sh"

# §XVI — Temporary Files
run_check "Temporary Files (§XVI)"             "$SCRIPT_DIR/check_local_files.sh"

# §17.1 — README Parity
run_check "README Parity (§17.1)"              "$SCRIPT_DIR/check_readme_parity.sh"

# §18.1 — Legacy Cleanup
run_check "Legacy Cleanup (§18.1)"             "$SCRIPT_DIR/check_legacy_cleanup.sh"

# §8.7 — Constitution Refs in Source
run_check "Constitution References (§8.7)"     "$SCRIPT_DIR/check_constitution_refs.sh"

# §19.2 — .gitignore Coverage
run_check ".gitignore Coverage (§19.2)"        "$SCRIPT_DIR/check_gitignore.sh"

# ============================================================================
# Summary
# ============================================================================

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
    echo "[FAIL] $FAIL_COUNT check(s) failed. Fix the issues above before committing."
    exit 1
else
    echo ""
    echo "[PASS] All checks passed."
fi
