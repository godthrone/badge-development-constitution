#!/usr/bin/env bash
# check_reproducibility.sh — Verify reproducibility mechanisms per §6
# Part of BADGE Constitution §6（复现：由需求定义的效果 / the effect defined by requirements）
#
# Checks for:
#   - uv.lock committed to git
#   - Docker base image not using :latest tag
#   - Docker base image using SHA256 digest (optional, strongest pinning)
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
    echo "[FAIL] check_reproducibility: uv.lock not tracked in git (§14.2)."
    FAIL=1
fi

# ─── 2. .python-version is pinned ───────────────────────────────────────

PY_VERSION_FILE="$PROJECT_ROOT/.python-version"
if [ -f "$PY_VERSION_FILE" ]; then
    PY_VER=$(cat "$PY_VERSION_FILE" | tr -d '[:space:]')
    echo "  [OK] .python-version pinned to $PY_VER"
else
    echo "  [WARN] .python-version not found — Python version not pinned (§14.2)."
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
        echo "[FAIL] check_reproducibility: Dockerfile uses :latest tag (pin to specific version per §14.3):"
        grep -nE 'FROM\s+\S+:latest\b' "$DOCKERFILE" 2>/dev/null | grep -v '^\s*#' | \
            while IFS= read -r line; do echo "  $line"; done
        FAIL=1
    fi

    # Check for SHA256 digest (optional, strongest pinning)
    if grep -E 'FROM\s+\S+@sha256:' "$DOCKERFILE" 2>/dev/null | grep -v '^\s*#' | grep -q .; then
        echo "  [OK] Docker base image pinned to SHA256 digest (strongest pinning)"
    else
        echo "  [WARN] Docker base image not pinned to SHA256 digest (optional)."
        echo "         Tags can be overwritten — use @sha256:... to pin the exact image."
        echo "         Whether that level is needed depends on the effect the requirement defines (§6)."
    fi

    # Check for BuildKit cache mount (§14.3: every `uv sync` / `uv pip install`
    # is required to use RUN --mount=type=cache). Only meaningful when the
    # Dockerfile actually installs with uv, so that precondition is checked
    # first to avoid false positives on Dockerfiles that do not use uv.
    if grep -qE 'uv (sync|pip install)' "$DOCKERFILE" 2>/dev/null; then
        if grep -qE 'RUN --mount=type=cache.*uv' "$DOCKERFILE" 2>/dev/null; then
            echo "  [OK] BuildKit cache mount for uv (prevents re-download on rebuild §14.3)"
        else
            echo "  [WARN] uv install found without a BuildKit cache mount (§14.3 requires it)."
            echo "         Add: RUN --mount=type=cache,target=/root/.cache/uv uv sync ..."
            echo "         This prevents re-downloading all packages when a layer is rebuilt (§14.3)."
        fi
    fi

    # Check for the §14.3 two-layer build: the dependency layer (uv.lock +
    # pyproject.toml) is copied and installed before the source layer, so the
    # dependency layer stays cached. §14.3 specifies a single-FROM two-layer
    # template; a multi-stage build also satisfies the caching goal and is
    # accepted. (The previous heuristic only looked for multi-stage, so it
    # warned on compliant single-FROM files.)
    if grep -qE 'COPY --from=' "$DOCKERFILE" 2>/dev/null || \
       grep -qE 'FROM.*AS[[:space:]]+(builder|deps|build)' "$DOCKERFILE" 2>/dev/null || \
       { grep -qE '^[[:space:]]*COPY[[:space:]].*(uv\.lock|pyproject\.toml)' "$DOCKERFILE" 2>/dev/null && \
         grep -qE '^[[:space:]]*COPY[[:space:]].*(src/|src[[:space:]]|[[:space:]]\.[[:space:]]*$)' "$DOCKERFILE" 2>/dev/null; }; then
        echo "  [OK] Dockerfile follows the §14.3 two-layer build (dependency layer cached)"
    else
        echo "  [WARN] Dockerfile does not appear to follow the §14.3 two-layer build."
        echo "         Copy uv.lock + pyproject.toml and install dependencies first,"
        echo "         then COPY the source layer — see the §14.3 Dockerfile template."
    fi
else
    echo "  [WARN] No Dockerfile found (Docker deployment required by §14.3)."
fi

# ─── 4. Random seed hints ──────────────────────────────────────────────

CFG_TEMPLATE="$PROJECT_ROOT/config.toml"
[ -f "$CFG_TEMPLATE" ] || CFG_TEMPLATE="$PROJECT_ROOT/config_example.toml"
[ -f "$CFG_TEMPLATE" ] || CFG_TEMPLATE="$PROJECT_ROOT/config_example.yaml"
if [ -f "$CFG_TEMPLATE" ]; then
    if grep -qiE '^\s*(seed|random_seed)\s*[:=]' "$CFG_TEMPLATE" 2>/dev/null; then
        echo "  [OK] Random seed appears in config example"
    else
        echo "  [WARN] No random seed field found in config example."
        echo "         If the task has randomness and must reproduce a defined effect,"
        echo "         the seed must be explicit in config, not dependent on system time (§6)."
    fi
fi

echo ""
if [ $FAIL -eq 0 ]; then
    echo "[PASS] check_reproducibility: Reproducibility measures in place."
else
    echo "[FAIL] check_reproducibility: Issues found."
fi
exit $FAIL
