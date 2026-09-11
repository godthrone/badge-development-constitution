#!/usr/bin/env bash
# check_all.sh — Run all BADGE Constitution compliance checks
# Part of BADGE Constitution
#
# Usage: ./check_all.sh [options] [project_root]
#        ./check_all.sh --no-history [project_root]   skip git history scan (faster)
#        ./check_all.sh --class=A|B|C [project_root]  select check class
#   project_root defaults to the git repo root of the current directory.
#
# Classes:
#   --class A  (default) Run all checks
#   --class B  Skip §17.1 bilingual checks (exemption), relax YAML/__main__.py checks
#   --class C  Only run §15, §16, §17.3-§17.5, §19.1-§19.3 checks
#
# Exit code: 0 if all checks pass, 1 if any check fails.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── Argument parsing ────────────────────────────────────────────────────

NO_HISTORY_FLAG=""
CLASS="A"
PROJECT_ROOT=""
for arg in "${@}"; do
    case "$arg" in
        --no-history) NO_HISTORY_FLAG="--no-history" ;;
        --class=A|--class=B|--class=C) CLASS="${arg#--class=}" ;;
        --class) echo "Usage: check_all.sh [--no-history] [--class=A|B|C] [project_root]" >&2; exit 2 ;;
        -*) echo "Usage: check_all.sh [--no-history] [--class=A|B|C] [project_root]" >&2; exit 2 ;;
        *) PROJECT_ROOT="$arg" ;;
    esac
done

PROJECT_ROOT="${PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || echo '.')}"

# Dynamically detect latest constitution file (sorted by version)
CONSTITUTION_FILE=$(ls "$SCRIPT_DIR/../BADGE-constitution-v"*.en.md 2>/dev/null | sort -V | tail -1)
if [ -n "$CONSTITUTION_FILE" ]; then
    VERSION=$(grep -oP 'BADGE Constitution v\K[0-9]+\.[0-9]+\.[0-9]+' "$CONSTITUTION_FILE" 2>/dev/null || echo "unknown")
else
    VERSION="unknown"
fi

CLASS_LABEL=""
case "$CLASS" in
    A) CLASS_LABEL=" (Class A — Full)" ;;
    B) CLASS_LABEL=" (Class B — Relaxed)" ;;
    C) CLASS_LABEL=" (Class C — Security & Governance)" ;;
esac

echo "============================================"
echo " BADGE Constitution v$VERSION — Compliance Check$CLASS_LABEL"
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
    shift 2
    echo "── $name ──"
    # Capture exit code.
    # Invoke via `bash` rather than executing directly: the executable bit is not
    # preserved on Windows/WSL checkouts (core.filemode=false), which would make
    # every sub-check fail with "Permission denied".
    local exit_code=0
    bash "$script" "$PROJECT_ROOT" "$@" || exit_code=$?
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

if [ "$CLASS" = "A" ] || [ "$CLASS" = "B" ]; then

# §2.2 — Explicitness: hasattr / **kwargs misuse
run_check "hasattr / **kwargs Usage (§2.2)"   "$SCRIPT_DIR/check_hasattr_kwargs.sh"

# ============================================================================
# Layer 2: Engineering Standards
# ============================================================================

# §6 — Reproducible Environments
run_check "Reproducibility (§6)"               "$SCRIPT_DIR/check_reproducibility.sh"

# §7 — Configuration System
if [ "$CLASS" = "B" ]; then
    run_check "Configuration System (§7.1-7.3)"    "$SCRIPT_DIR/check_config_system.sh" --class=B
else
    run_check "Configuration System (§7.1-7.3)"    "$SCRIPT_DIR/check_config_system.sh"
fi

# §8.1 — Directory Layout
if [ "$CLASS" = "B" ]; then
    run_check "Directory Layout (§8.1)"            "$SCRIPT_DIR/check_directory_layout.sh" --class=B
else
    run_check "Directory Layout (§8.1)"            "$SCRIPT_DIR/check_directory_layout.sh"
fi

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

# §12.2 — Class-Path Mirroring (file name = class name)
run_check "Class-Path Mirroring (§12.2)"       "$SCRIPT_DIR/check_class_file_naming.sh"

# §12.4 — File Header Responsibility Declarations
run_check "File Headers (§12.4)"               "$SCRIPT_DIR/check_file_header.sh"

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

fi  # end class A/B Layer 1-2

# ============================================================================
# Layer 3: Security and Project Governance
# ============================================================================

# §15.1 — Secrets Scan (all classes)
run_check "Secrets Scan (§15.1)"               "$SCRIPT_DIR/check_secrets.sh" $NO_HISTORY_FLAG

# §XVI — Temporary Files (all classes)
run_check "Temporary Files (§XVI)"             "$SCRIPT_DIR/check_local_files.sh"

if [ "$CLASS" = "A" ]; then

# §17.1 — README Parity (class A only; class B/C exempt per §17.6)
run_check "README Parity (§17.1)"              "$SCRIPT_DIR/check_readme_parity.sh"

# §17.2 — Docs ASCII Diagrams (warn-only)
run_check "Docs ASCII Diagrams (§17.2)"        "$SCRIPT_DIR/check_docs_ascii.sh"

# §18.1 — Legacy Cleanup
run_check "Legacy Cleanup (§18.1)"             "$SCRIPT_DIR/check_legacy_cleanup.sh"

elif [ "$CLASS" = "B" ]; then

echo "── README Parity (§17.1) ──"
echo "  [SKIP] §17.6 exemption: bilingual README check skipped for Class B projects."
echo ""

# §17.2 — Docs ASCII Diagrams (warn-only)
run_check "Docs ASCII Diagrams (§17.2)"        "$SCRIPT_DIR/check_docs_ascii.sh"

# §18.1 — Legacy Cleanup
run_check "Legacy Cleanup (§18.1)"             "$SCRIPT_DIR/check_legacy_cleanup.sh"

elif [ "$CLASS" = "C" ]; then

echo "── README Parity (§17.1) ──"
echo "  [SKIP] §17.6 exemption: bilingual README check skipped for Class C projects."
echo ""

fi  # end class-specific §17 checks

# §8.7 — Constitution Refs in Source (all classes)
run_check "Constitution References (§8.7)"     "$SCRIPT_DIR/check_constitution_refs.sh"

# §19.2 — .gitignore Coverage (all classes)
run_check ".gitignore Coverage (§19.2)"        "$SCRIPT_DIR/check_gitignore.sh"

# ============================================================================
# Summary
# ============================================================================

echo "============================================"
echo " Summary (Class $CLASS)"
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
