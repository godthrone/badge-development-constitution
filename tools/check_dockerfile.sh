#!/usr/bin/env bash
# check_dockerfile.sh — Verify Dockerfile follows §14.3 requirements
# Part of BADGE Constitution §14.3
#
# Checks for:
#   - Dockerfile exists
#   - Base image uses specific version (not :latest)
#   - Two-stage build (dependencies + source layers)
#   - uv is used for dependency installation (not pip install -r requirements.txt)
#   - build.sh or docker/build.sh exists
#
# Complemented by: check_docker_version.sh (build.sh tag verification)
#                  check_reproducibility.sh (SHA256 digest check)
#
# Usage: ./check_dockerfile.sh [project_root]

set -euo pipefail

PROJECT_ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || echo '.')}"
cd "$PROJECT_ROOT"

FAIL=0

echo "Checking Dockerfile..."

# ─── 1. Dockerfile existence ────────────────────────────────────────────

DOCKERFILE=""
if [ -f "$PROJECT_ROOT/Dockerfile" ]; then
    DOCKERFILE="$PROJECT_ROOT/Dockerfile"
elif [ -f "$PROJECT_ROOT/docker/Dockerfile" ]; then
    DOCKERFILE="$PROJECT_ROOT/docker/Dockerfile"
fi

if [ -z "$DOCKERFILE" ]; then
    echo "[FAIL] check_dockerfile: No Dockerfile found (Docker deployment required by §14.3)."
    exit 1
fi

echo "  [OK] Dockerfile found: ${DOCKERFILE#$PROJECT_ROOT/}"

# ─── 2. No :latest tag ─────────────────────────────────────────────────

LATEST_FROM=$(grep -nE '^FROM\s+\S+:latest\b' "$DOCKERFILE" 2>/dev/null | grep -v '^\s*#' || true)
if [ -n "$LATEST_FROM" ]; then
    echo "[FAIL] check_dockerfile: Base image uses :latest tag (pin to specific version per §14.3):"
    echo "$LATEST_FROM" | while IFS= read -r line; do echo "  $line"; done
    FAIL=1
else
    echo "  [OK] Base image uses specific version tag (not :latest)"
fi

# ─── 3. Two-stage build check ──────────────────────────────────────────

# Check for multi-stage build patterns
if grep -qE 'FROM.*AS\s+(builder|deps|build|base)' "$DOCKERFILE" 2>/dev/null; then
    STAGES=$(grep -cE 'FROM.*AS\s+' "$DOCKERFILE" 2>/dev/null || echo 0)
    echo "  [OK] Multi-stage build with $STAGES stage(s)"
elif grep -qE 'COPY --from=' "$DOCKERFILE" 2>/dev/null; then
    echo "  [OK] Multi-stage build (COPY --from= detected)"
else
    echo "  [WARN] No multi-stage build detected — recommend two-stage build for layer caching (§14.3)."
fi

# ─── 4. uv usage for dependency installation ────────────────────────────

if grep -qE '(uv sync|uv pip install)' "$DOCKERFILE" 2>/dev/null; then
    echo "  [OK] Uses uv for dependency installation"
else
    echo "  [WARN] uv sync / uv pip install not found in Dockerfile."
    echo "         Dependencies should be installed via uv for version consistency (§14.2, §14.3)."
fi

# ─── 5. pip install -r requirements.txt in Dockerfile ──────────────────

if grep -qE 'pip install.*-r.*requirements' "$DOCKERFILE" 2>/dev/null; then
    echo "[FAIL] check_dockerfile: Dockerfile uses pip install -r requirements.txt"
    echo "         Use uv sync or uv pip install with uv.lock instead (§14.2)."
    FAIL=1
fi

# ─── 6. build.sh exists ────────────────────────────────────────────────

if [ -f "$PROJECT_ROOT/build.sh" ]; then
    echo "  [OK] build.sh exists"
elif [ -f "$PROJECT_ROOT/docker/build.sh" ]; then
    echo "  [OK] docker/build.sh exists"
else
    echo "  [WARN] No build.sh found — recommend encapsulating build command (§14.3)."
fi

echo ""
if [ $FAIL -eq 0 ]; then
    echo "[PASS] check_dockerfile: Dockerfile follows constitution."
else
    echo "[FAIL] check_dockerfile: Issues found."
fi
exit $FAIL
