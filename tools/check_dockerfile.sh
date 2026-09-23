#!/usr/bin/env bash
# check_dockerfile.sh — Verify Dockerfile follows §14.3 requirements
# Part of BADGE Constitution §14.3
#
# Checks for:
#   - Dockerfile exists
#   - Base image uses specific version (not :latest)
#   - Two-layer build (dependency layer + source layer, §14.3)
#   - uv is used for dependency installation (not pip install -r requirements.txt)
#   - build.sh or docker/build.sh exists
#   - No proxy ENV directives (proxy must use --build-arg per §14.3)
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

# ─── 3. Two-layer build check ──────────────────────────────────────────

# §14.3 (BADGE-constitution-v2.5.0.zh-CN.md:768) requires a **two-layer**
# build — a dependency layer (uv.lock + pyproject.toml) and a source layer —
# so the dependency layer stays cached. It does NOT ask for a multi-stage
# build: the official template (same file, lines 778–797) is single-FROM.
#
# The old heuristic only looked for `FROM … AS builder` / `COPY --from=`,
# so a compliant single-FROM file was reported as "No multi-stage build",
# contradicting check_reproducibility.sh on the very same Dockerfile.
#
# Accepted forms (warning only, never a hard gate):
#   1. the §14.3 two-layer shape — uv.lock/pyproject.toml COPYed before the
#      source COPY; or
#   2. a multi-stage build, which reaches the same caching goal.
if grep -qE '^[[:space:]]*COPY[[:space:]].*(uv\.lock|pyproject\.toml)' "$DOCKERFILE" 2>/dev/null && \
   grep -qE '^[[:space:]]*COPY[[:space:]].*(src/|src[[:space:]]|[[:space:]]\.[[:space:]]*$)' "$DOCKERFILE" 2>/dev/null; then
    echo "  [OK] Two-layer build: dependency layer (uv.lock + pyproject.toml) precedes the source layer (§14.3)"
elif grep -qE 'COPY --from=' "$DOCKERFILE" 2>/dev/null || \
     grep -qE 'FROM.*AS[[:space:]]+(builder|deps|build|base)' "$DOCKERFILE" 2>/dev/null; then
    echo "  [OK] Multi-stage build detected (dependency caching satisfied, §14.3)"
else
    echo "  [WARN] No two-layer (dependency layer + source layer) build detected — the dependency layer may not stay cached."
    echo "         Follow the §14.3 template: COPY uv.lock pyproject.toml … and install first, then COPY the source."
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

# ─── 6. BuildKit cache mount for uv ─────────────────────────────────────

if grep -qE 'RUN --mount=type=cache.*uv' "$DOCKERFILE" 2>/dev/null; then
    echo "  [OK] BuildKit cache mount for uv (prevents re-download on rebuild)"
else
    echo "  [WARN] No BuildKit cache mount for uv found."
    echo "         Add: RUN --mount=type=cache,target=/root/.cache/uv uv sync ..."
    echo "         This prevents re-downloading all packages when a layer is rebuilt (§14.3)."
fi

# ─── 7. build.sh exists ────────────────────────────────────────────────

if [ -f "$PROJECT_ROOT/build.sh" ]; then
    echo "  [OK] build.sh exists"
elif [ -f "$PROJECT_ROOT/docker/build.sh" ]; then
    echo "  [OK] docker/build.sh exists"
else
    echo "  [WARN] No build.sh found — recommend encapsulating build command (§14.3)."
fi

# ─── 8. Proxy ENV check ──────────────────────────────────────────────────

PROXY_ENV=$(grep -inE '^\s*ENV\s+(HTTP_PROXY|HTTPS_PROXY|NO_PROXY|http_proxy|https_proxy|no_proxy)\b' "$DOCKERFILE" 2>/dev/null || true)
if [ -n "$PROXY_ENV" ]; then
    echo "[FAIL] check_dockerfile: Proxy environment variables found in ENV directive."
    echo "         Proxy settings must be passed via --build-arg in build.sh, not ENV in Dockerfile."
    echo "         ENV variables persist in the final image and will break networking"
    echo "         in environments without the proxy (§14.3)."
    echo "$PROXY_ENV" | while IFS= read -r line; do echo "  $line"; done
    FAIL=1
else
    echo "  [OK] No proxy ENV directives found (proxy passed via ARG only)"
fi

echo ""
if [ $FAIL -eq 0 ]; then
    echo "[PASS] check_dockerfile: Dockerfile follows constitution."
else
    echo "[FAIL] check_dockerfile: Issues found."
fi
exit $FAIL
