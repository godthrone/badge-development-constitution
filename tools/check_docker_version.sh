#!/usr/bin/env bash
# check_docker_version.sh — Verify Docker image tag matches project version
# (§14.3).
#
# Checks:
# 1. If build.sh or docker/build.sh exists, does it hardcode a version?
# 2. If hardcoded, does it match pyproject.toml / git tags?
# 3. If dynamic (git describe or tomllib), PASS.
#
# Supports both:
#   - setuptools-scm: git describe --tags (recommended per §8.7)
#   - Static version: tomllib read from pyproject.toml (legacy)
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

# ─── Determine expected version ──────────────────────────────────────────────

EXPECTED_VERSION=""

# First try: git describe (setuptools-scm, recommended)
if git rev-parse --git-dir >/dev/null 2>&1; then
    EXPECTED_VERSION=$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || true)
fi

# Second try: pyproject.toml (static version, legacy)
if [ -z "$EXPECTED_VERSION" ]; then
    PYPROJECT="$PROJECT_ROOT/pyproject.toml"
    if [ -f "$PYPROJECT" ]; then
        EXPECTED_VERSION=$(grep -E '^version\s*=' "$PYPROJECT" 2>/dev/null | head -1 | \
            sed 's/.*=\s*"\([^"]*\)".*/\1/' || true)
    fi
fi

if [ -z "$EXPECTED_VERSION" ]; then
    echo "[SKIP] check_docker_version: Could not determine project version."
    exit 0
fi

echo "  Project version: $EXPECTED_VERSION"

# ─── Check if build.sh uses dynamic extraction ──────────────────────────────

if grep -q 'git describe\|tomllib\|toml\.load\|importlib\.metadata' "$BUILD_SCRIPT" 2>/dev/null; then
    echo "  [OK] build.sh reads version dynamically (git describe or tomllib)."
    echo "[PASS] check_docker_version: Docker version matches project version."
    exit 0
fi

# ─── Extract hardcoded version from build.sh ────────────────────────────────

HARDCODED=$(grep -oE 'IMAGE_NAME[=:][^}]*:[0-9]+\.[0-9]+\.[0-9]+' "$BUILD_SCRIPT" 2>/dev/null | \
    grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)

if [ -z "$HARDCODED" ]; then
    HARDCODED=$(grep -oE '(graspo|project|image|tag)[=:][^}]*:[0-9]+\.[0-9]+\.[0-9]+' "$BUILD_SCRIPT" 2>/dev/null | \
        grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)
fi

if [ -z "$HARDCODED" ]; then
    echo "  [WARN] Could not detect version tag in build.sh. Review manually."
    echo "        Per §14.3, the tag should be derived from git describe or pyproject.toml."
    exit 0
fi

echo "  build.sh hardcoded tag: $HARDCODED"

# ─── Compare ────────────────────────────────────────────────────────────────

if [ "$HARDCODED" = "$EXPECTED_VERSION" ]; then
    echo "  [WARN] build.sh hardcodes version $HARDCODED which matches project version."
    echo "         Per §14.3, prefer dynamic extraction (git describe) to prevent drift."
    echo "[WARN] check_docker_version: Version matches but is hardcoded (should be dynamic)."
    exit 0
else
    echo "  [FAIL] build.sh tag ($HARDCODED) != project version ($EXPECTED_VERSION)."
    echo "         Update build.sh to dynamically read the version (§14.3)."
    echo "[FAIL] check_docker_version: Docker tag does not match project version."
    exit 1
fi
