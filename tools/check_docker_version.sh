#!/usr/bin/env bash
# check_docker_version.sh — Verify Docker image tag matches pyproject.toml
# version (§14.3).
#
# Checks:
# 1. If build.sh or docker/build.sh exists, does it hardcode a version?
# 2. If hardcoded, does it match pyproject.toml?
# 3. If dynamic (reads from pyproject.toml), PASS.
#
# Usage: ./check_docker_version.sh [project_root]

set -euo pipefail

PROJECT_ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || echo '.')}"
cd "$PROJECT_ROOT"

# ─── Find build script ──────────────────────────────────────────────────────

BUILD_SCRIPT=""
if [ -f "$PROJECT_ROOT/build.sh" ]; then
    BUILD_SCRIPT="$PROJECT_ROOT/build.sh"
elif [ -f "$PROJECT_ROOT/docker/build.sh" ]; then
    BUILD_SCRIPT="$PROJECT_ROOT/docker/build.sh"
fi

if [ -z "$BUILD_SCRIPT" ]; then
    echo "[SKIP] check_docker_version: No build.sh or docker/build.sh found."
    exit 0
fi

echo "Checking $BUILD_SCRIPT..."

# ─── Extract version from pyproject.toml ────────────────────────────────────

PYPROJECT="$PROJECT_ROOT/pyproject.toml"
if [ ! -f "$PYPROJECT" ]; then
    echo "[SKIP] check_docker_version: No pyproject.toml found."
    exit 0
fi

PY_VERSION=$(grep -E '^version\s*=' "$PYPROJECT" 2>/dev/null | head -1 | \
    sed 's/.*=\s*"\([^"]*\)".*/\1/' || true)

if [ -z "$PY_VERSION" ]; then
    echo "[SKIP] check_docker_version: Could not extract version from pyproject.toml."
    exit 0
fi

echo "  pyproject.toml version: $PY_VERSION"

# ─── Check if build.sh uses dynamic extraction ──────────────────────────────

if grep -q 'tomllib\|toml\.load\|importlib\.metadata' "$BUILD_SCRIPT" 2>/dev/null; then
    echo "  [OK] build.sh reads version dynamically from pyproject.toml."
    echo "[PASS] check_docker_version: Docker version matches pyproject.toml."
    exit 0
fi

# ─── Extract hardcoded version from build.sh ────────────────────────────────

# Look for patterns like:
#   IMAGE_NAME=...:0.9.1
#   IMAGE_NAME="${IMAGE_NAME:-project:0.9.1}"
#   TAG=...:0.9.1
HARDCODED=$(grep -oE 'IMAGE_NAME[=:][^}]*:[0-9]+\.[0-9]+\.[0-9]+' "$BUILD_SCRIPT" 2>/dev/null | \
    grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)

if [ -z "$HARDCODED" ]; then
    # Try broader pattern
    HARDCODED=$(grep -oE '(graspo|project|image|tag)[=:][^}]*:[0-9]+\.[0-9]+\.[0-9]+' "$BUILD_SCRIPT" 2>/dev/null | \
        grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)
fi

if [ -z "$HARDCODED" ]; then
    echo "  [WARN] Could not detect version tag in build.sh. Review manually."
    echo "        Per §14.3, the tag should be derived from pyproject.toml."
    exit 0
fi

echo "  build.sh hardcoded tag: $HARDCODED"

# ─── Compare ────────────────────────────────────────────────────────────────

if [ "$HARDCODED" = "$PY_VERSION" ]; then
    echo "  [WARN] build.sh hardcodes version $HARDCODED which matches pyproject.toml."
    echo "         Per §14.3, prefer dynamic extraction from pyproject.toml to prevent drift."
    echo "[WARN] check_docker_version: Version matches but is hardcoded (should be dynamic)."
    exit 0
else
    echo "  [FAIL] build.sh tag ($HARDCODED) != pyproject.toml version ($PY_VERSION)."
    echo "         Update build.sh to dynamically read the version from pyproject.toml (§14.3)."
    echo "[FAIL] check_docker_version: Docker tag does not match pyproject.toml."
    exit 1
fi
