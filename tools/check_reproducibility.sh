#!/usr/bin/env bash
# check_reproducibility.sh — Verify environment reproducibility per §6
# Part of BADGE Constitution §6
#
# Checks for:
#   - uv.lock committed to git
#   - Docker base image not using :latest tag
#   - Docker base image using SHA256 digest (recommended)
#   - Random seed configuration hints
#   - .python-version exists and is pinned
#
# Usage: ./check_reproducibility.sh [project_root]

set -euo pipefail

PROJECT_ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || echo '.')}"
cd "$PROJECT_ROOT"

FAIL=0

if ! git rev-parse --git-dir &>/dev/null 2>&1; then
    echo "[SKIP] check_reproducibility: Not a git repository."
    exit 0
fi

TRACKED_FILES=$(git ls-files --cached 2>/dev/null || true)

echo "Checking reproducibility..."

# ─── 1. uv.lock is tracked ──────────────────────────────────────────────

if echo "$TRACKED_FILES" | grep -qxF 'uv.lock' 2>/dev/null; then
    echo "  [OK] uv.lock is tracked in git"
else
    echo "[FAIL] check_reproducibility: uv.lock not tracked in git (§6)."
    FAIL=1
fi

# ─── 2. .python-version is pinned ───────────────────────────────────────

PY_VERSION_FILE="$PROJECT_ROOT/.python-version"
if [ -f "$PY_VERSION_FILE" ]; then
    PY_VER=$(cat "$PY_VERSION_FILE" | tr -d '[:space:]')
    echo "  [OK] .python-version pinned to $PY_VER"
else
    echo "  [WARN] .python-version not found — Python version not pinned (§6)."
fi

# ─── 3. Dockerfile: no :latest tag, prefer SHA256 ───────────────────────

DOCKERFILE=""
if [ -f "$PROJECT_ROOT/Dockerfile" ]; then
    DOCKERFILE="$PROJECT_ROOT/Dockerfile"
elif [ -f "$PROJECT_ROOT/docker/Dockerfile" ]; then
    DOCKERFILE="$PROJECT_ROOT/docker/Dockerfile"
fi

if [ -n "$DOCKERFILE" ]; then
    echo "  [OK] Dockerfile found: ${DOCKERFILE#$PROJECT_ROOT/}"

    # Check for :latest
    if grep -E 'FROM\s+\S+:latest\b' "$DOCKERFILE" 2>/dev/null | grep -v '^\s*#' | grep -q .; then
        echo "[FAIL] check_reproducibility: Dockerfile uses :latest tag (pin to specific version per §6):"
        grep -nE 'FROM\s+\S+:latest\b' "$DOCKERFILE" 2>/dev/null | grep -v '^\s*#' | \
            while IFS= read -r line; do echo "  $line"; done
        FAIL=1
    fi

    # Check for SHA256 digest (recommended)
    if grep -E 'FROM\s+\S+@sha256:' "$DOCKERFILE" 2>/dev/null | grep -v '^\s*#' | grep -q .; then
        echo "  [OK] Docker base image pinned to SHA256 digest (recommended §6)"
    else
        echo "  [WARN] Docker base image not pinned to SHA256 digest (recommended per §6)."
        echo "         Tags can be overwritten — use @sha256:... for bit-for-bit reproducibility."
    fi

    # Check for two-stage build (COPY --from=...)
    if grep -qE 'COPY --from=' "$DOCKERFILE" 2>/dev/null || \
       grep -qE 'FROM.*AS\s+(builder|deps|build)' "$DOCKERFILE" 2>/dev/null; then
        echo "  [OK] Dockerfile appears to use multi-stage build (§14.3)"
    else
        echo "  [WARN] Dockerfile may not use multi-stage build (recommended for caching §14.3)."
    fi
else
    echo "  [WARN] No Dockerfile found (Docker deployment required by §14.3)."
fi

# ─── 4. Random seed hints ──────────────────────────────────────────────

if [ -f "$PROJECT_ROOT/config_example.yaml" ]; then
    if grep -qiE '^\s*(seed|random_seed):' "$PROJECT_ROOT/config_example.yaml" 2>/dev/null; then
        echo "  [OK] Random seed appears in config_example.yaml"
    else
        echo "  [WARN] No random seed field found in config_example.yaml."
        echo "         Random seed must be explicit in config, not dependent on system time (§6)."
    fi
fi

echo ""
if [ $FAIL -eq 0 ]; then
    echo "[PASS] check_reproducibility: Reproducibility measures in place."
else
    echo "[FAIL] check_reproducibility: Issues found."
fi
exit $FAIL
