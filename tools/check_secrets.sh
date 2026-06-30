#!/usr/bin/env bash
# check_secrets.sh — Scan tracked files for secrets (IPs, keys, tokens, internal paths)
# Part of BADGE Constitution v1.6.0 §15.1
#
# Usage: ./check_secrets.sh [project_root]
#   project_root defaults to the git repo root of the current directory.

set -euo pipefail

PROJECT_ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || echo '.')}"
cd "$PROJECT_ROOT"

# Collect tracked files
if git rev-parse --git-dir &>/dev/null; then
    FILES=$(git ls-files --cached --others --exclude-standard 2>/dev/null || true)
    if [ -z "$FILES" ]; then
        echo "[PASS] check_secrets: No tracked files found."
        exit 0
    fi
else
    echo "[SKIP] check_secrets: Not a git repository."
    exit 0
fi

FAIL=0

# ─── Pattern definitions ───────────────────────────────────────────────

# IPv4 address (catches 10.x, 172.16-31.x, 192.168.x, and any internal IP)
IPV4_PATTERN='(^|[^0-9])([0-9]{1,3}\.){3}[0-9]{1,3}($|[^0-9])'

# Common API key / token prefixes
KEY_PATTERNS=(
    'sk-[a-zA-Z0-9]{20,}'
    'tvly-[a-zA-Z0-9_-]{20,}'
    'hf_[a-zA-Z0-9]{20,}'
    'ghp_[a-zA-Z0-9]{20,}'
    'gho_[a-zA-Z0-9]{20,}'
    'AKIA[0-9A-Z]{16}'
    'xox[bpras]-[a-zA-Z0-9-]+'
    '-----BEGIN (RSA|DSA|EC|OPENSSH|PGP) PRIVATE KEY-----'
)

# Internal path patterns
INTERNAL_PATH_PATTERNS=(
    '/home/[a-z][a-z0-9_]*/'
    '/root/'
)

# ─── Helper ─────────────────────────────────────────────────────────────

# Run grep on tracked files, return matches (or empty string if none)
grep_tracked() {
    local pattern="$1"
    local grep_opts="${2:--nE}"
    echo "$FILES" | xargs grep $grep_opts "$pattern" 2>/dev/null || true
}

print_matches() {
    local label="$1"
    local matches="$2"
    if [ -n "$matches" ]; then
        echo "[FAIL] check_secrets: $label found:"
        echo "$matches" | while IFS= read -r line; do
            echo "  $line"
        done
        FAIL=1
    fi
}

# ─── Scan: IP addresses ──────────────────────────────────────────────────

echo "Scanning for IP addresses..."
IP_RAW=$(grep_tracked "$IPV4_PATTERN")
# Exclude common false positives:
# - uv.lock and other lockfiles contain version strings (e.g. 12.4.5.8) that match IP patterns
# - public URLs from package registries
IP_MATCHES=$(echo "$IP_RAW" | grep -v '^uv\.lock:' | grep -v '^package-lock\.json:' | \
    grep -v '0\.0\.0\.0' | grep -v '127\.0\.0\.1' | \
    grep -v '255\.255\.255\.255' | grep -v 'version.*[0-9]\.[0-9]\.[0-9]' | \
    grep -v 'files\.pythonhosted\.org' || true)
print_matches "IP addresses (check if internal)" "$IP_MATCHES"

# ─── Scan: API keys ──────────────────────────────────────────────────────

echo "Scanning for API keys..."
for pattern in "${KEY_PATTERNS[@]}"; do
    KEY_RAW=$(grep_tracked "$pattern")
    KEY_MATCHES=$(echo "$KEY_RAW" | grep -v '\.env-example' | grep -v 'CLAUDE\.md' || true)
    if [ -n "$KEY_MATCHES" ]; then
        # Check if matches are in constitution/tools directory (reference only) or actual leaks
        REAL_LEAKS=$(echo "$KEY_MATCHES" | grep -v 'badge-development-constitution/' || true)
        if [ -n "$REAL_LEAKS" ]; then
            echo "[FAIL] check_secrets: Possible API key/token found:"
            echo "$REAL_LEAKS" | while IFS= read -r line; do
                echo "  $line"
            done
            FAIL=1
        fi
    fi
done

# ─── Scan: Internal paths ────────────────────────────────────────────────

echo "Scanning for internal paths..."
for path_pattern in "${INTERNAL_PATH_PATTERNS[@]}"; do
    PATH_RAW=$(grep_tracked "$path_pattern")
    PATH_MATCHES=$(echo "$PATH_RAW" | grep -v '\.gitignore' | grep -v '\.local/' || true)
    print_matches "Internal path ($path_pattern)" "$PATH_MATCHES"
done

# ─── Scan: SSH connection strings ────────────────────────────────────────

echo "Scanning for SSH strings..."
SSH_MATCHES=$(grep_tracked 'ssh.*@[0-9]')
print_matches "SSH connection string with IP" "$SSH_MATCHES"

# ─── Scan: .env in tracked files ─────────────────────────────────────────

if echo "$FILES" | grep -qxF '.env' 2>/dev/null; then
    echo "[FAIL] check_secrets: .env file is tracked by git."
    FAIL=1
fi

# ─── Result ──────────────────────────────────────────────────────────────

if [ $FAIL -eq 0 ]; then
    echo "[PASS] check_secrets: No secrets found in tracked files."
fi
exit $FAIL