#!/usr/bin/env bash
# check_docker_version.sh — Verify Docker image tag matches project version
# (§14.3).
#
# Checks:
# 1. If build.sh or docker/build.sh exists, does it hardcode a version?
# 2. If hardcoded, does it match the version derived from git tags?
# 3. If dynamic (git describe or tomllib), PASS.
#
# Per §8.7 the version has exactly one source: git tags via setuptools-scm.
# A static `version` field in pyproject.toml is therefore forbidden (not a fallback).
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

# §8.7: a static `version` field in pyproject.toml is forbidden — it would be a
# second source of truth besides the git tag.
PYPROJECT="$PROJECT_ROOT/pyproject.toml"
if [ -f "$PYPROJECT" ] && grep -qE '^version\s*=' "$PYPROJECT" 2>/dev/null; then
    echo "  [FAIL] pyproject.toml declares a static version field — forbidden by §8.7."
    echo "         Use dynamic = [\"version\"] with setuptools-scm (single source: git tag)."
    echo "[FAIL] check_docker_version: Static version field in pyproject.toml."
    exit 1
fi

# Sole source: git describe (setuptools-scm)
if git rev-parse --git-dir >/dev/null 2>&1; then
    EXPECTED_VERSION=$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || true)
fi

if [ -z "$EXPECTED_VERSION" ]; then
    echo "[SKIP] check_docker_version: Could not determine project version from git tags."
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
    echo "        Per §14.3/§8.7, the tag should be derived from git describe (git tag is the single source)."
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
