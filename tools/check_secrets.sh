#!/usr/bin/env bash
# check_secrets.sh — Scan tracked files for secrets (§15.1)
# Part of BADGE Constitution §15.1
#
# Checks for:
#   - IP addresses (internal/private ranges flagged)
#   - API keys, tokens, private keys
#   - Hardcoded passwords and secrets
#   - JWT tokens, base64-encoded credentials
#   - Internal file paths, SSH connection strings
#   - .env tracked by git
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
    # OpenAI-style keys
    'sk-proj-[a-zA-Z0-9_-]{20,}'
    'sk-admin-[a-zA-Z0-9_-]{20,}'
    # Generic API key patterns
    'api[_-]?key[=:]\s*["'"'"'][a-zA-Z0-9_-]{16,}["'"'"']'
    'api[_-]?secret[=:]\s*["'"'"'][a-zA-Z0-9_-]{16,}["'"'"']'
)

# Hardcoded credential patterns
CREDENTIAL_PATTERNS=(
    'password[=:]\s*["'"'"'][^"'"'"']{4,}["'"'"']'
    'passwd[=:]\s*["'"'"'][^"'"'"']{4,}["'"'"']'
    'secret[=:]\s*["'"'"'][a-zA-Z0-9_-]{8,}["'"'"']'
    'token[=:]\s*["'"'"'][a-zA-Z0-9_-]{16,}["'"'"']'
    'access[_-]?key[=:]\s*["'"'"'][a-zA-Z0-9]{8,}["'"'"']'
)

# JWT token pattern (eyJ... base64url encoded header)
JWT_PATTERN='eyJ[a-zA-Z0-9_-]{20,}\.[a-zA-Z0-9_-]{20,}\.[a-zA-Z0-9_-]{10,}'

# Long base64 string (potential encoded secret)
B64_SECRET_PATTERN='[A-Za-z0-9+/]{40,}={0,2}'

# Internal path patterns
INTERNAL_PATH_PATTERNS=(
    '/home/[a-z][a-z0-9_]*/'
    '/root/'
    '/etc/(passwd|shadow|ssl|nginx|apache)'
    '/var/log/'
)

# Internal / private IP ranges
PRIVATE_IP_PATTERNS=(
    '10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'
    '172\.(1[6-9]|2[0-9]|3[01])\.[0-9]{1,3}\.[0-9]{1,3}'
    '192\.168\.[0-9]{1,3}\.[0-9]{1,3}'
)

# ─── Helper ─────────────────────────────────────────────────────────────

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
# - uv.lock and other lockfiles contain version strings (e.g. 12.4.5.8)
# - public URLs from package registries
# - semantic version strings
IP_MATCHES=$(echo "$IP_RAW" | grep -v '^uv\.lock:' | grep -v '^package-lock\.json:' | \
    grep -v '0\.0\.0\.0' | grep -v '127\.0\.0\.1' | \
    grep -v '255\.255\.255\.255' | grep -v 'version.*[0-9]\.[0-9]\.[0-9]' | \
    grep -v 'files\.pythonhosted\.org' || true)

# Highlight private/internal IPs specifically
PRIVATE_IP_MATCHES=$(echo "$IP_MATCHES" | grep -E "$(IFS='|'; echo "${PRIVATE_IP_PATTERNS[*]}")" || true)
PUBLIC_IP_MATCHES=$(echo "$IP_MATCHES" | grep -vE "$(IFS='|'; echo "${PRIVATE_IP_PATTERNS[*]}")" || true)

if [ -n "$PRIVATE_IP_MATCHES" ]; then
    echo "[FAIL] check_secrets: Private/internal IP addresses found:"
    echo "$PRIVATE_IP_MATCHES" | while IFS= read -r line; do
        echo "  $line"
    done
    FAIL=1
fi
if [ -n "$PUBLIC_IP_MATCHES" ]; then
    echo "[WARN] Public IP addresses found (review if internal endpoints):"
    echo "$PUBLIC_IP_MATCHES" | head -20 | while IFS= read -r line; do
        echo "  $line"
    done
fi

# ─── Scan: API keys ──────────────────────────────────────────────────────

echo "Scanning for API keys and tokens..."
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

# ─── Scan: Hardcoded passwords and credentials ───────────────────────────

echo "Scanning for hardcoded credentials..."
for pattern in "${CREDENTIAL_PATTERNS[@]}"; do
    CRED_RAW=$(grep_tracked "$pattern")
    # Exclude: comments, example configs, constitution docs
    CRED_MATCHES=$(echo "$CRED_RAW" | \
        grep -v '^\s*#' | \
        grep -v '\.env-example' | \
        grep -v 'config_example\.yaml' | \
        grep -v 'badge-development-constitution/' | \
        grep -v 'check_secrets\.sh' || true)
    if [ -n "$CRED_MATCHES" ]; then
        echo "[FAIL] check_secrets: Hardcoded credential found:"
        echo "$CRED_MATCHES" | while IFS= read -r line; do
            echo "  $line"
        done
        FAIL=1
    fi
done

# ─── Scan: JWT tokens ────────────────────────────────────────────────────

echo "Scanning for JWT tokens..."
JWT_MATCHES=$(grep_tracked "$JWT_PATTERN" | \
    grep -v '\.env-example' | \
    grep -v 'badge-development-constitution/' | \
    grep -v 'check_secrets\.sh' || true)
if [ -n "$JWT_MATCHES" ]; then
    echo "[FAIL] check_secrets: Possible JWT token found:"
    echo "$JWT_MATCHES" | while IFS= read -r line; do
        echo "  $line"
    done
    FAIL=1
fi

# ─── Scan: Long base64 strings (potential encoded secrets) ──────────────

echo "Scanning for base64-encoded values..."
# Only check non-binary files, exclude known data files
B64_MATCHES=$(echo "$FILES" | grep -vE '\.(png|jpg|jpeg|gif|ico|woff2?|ttf|eot|pdf|zip|tar|gz|bin)$' | \
    xargs grep -nE "$B64_SECRET_PATTERN" 2>/dev/null | \
    grep -v 'badge-development-constitution/' | \
    grep -v 'uv\.lock:' | \
    grep -v '\.gitignore' | \
    grep -v '__pycache__' | \
    grep -v 'check_secrets\.sh' || true)
if [ -n "$B64_MATCHES" ]; then
    echo "[WARN] Long base64-like strings found (review manually):"
    echo "$B64_MATCHES" | head -20 | while IFS= read -r line; do
        echo "  $line"
    done
    echo "         These may be encoded secrets, certificates, or binary data."
fi

# ─── Scan: Internal paths ────────────────────────────────────────────────

echo "Scanning for internal paths..."
for path_pattern in "${INTERNAL_PATH_PATTERNS[@]}"; do
    PATH_RAW=$(grep_tracked "$path_pattern")
    PATH_MATCHES=$(echo "$PATH_RAW" | grep -v '\.gitignore' | grep -v '\.local/' | \
        grep -v 'badge-development-constitution/' | grep -v 'check_secrets\.sh' || true)
    print_matches "Internal path ($path_pattern)" "$PATH_MATCHES"
done

# ─── Scan: SSH connection strings ────────────────────────────────────────

echo "Scanning for SSH strings..."
SSH_MATCHES=$(grep_tracked 'ssh.*@[0-9]')
print_matches "SSH connection string with IP" "$SSH_MATCHES"

# Also catch ssh user@host patterns
SSH_USER_MATCHES=$(grep_tracked 'ssh\s+\w+@[a-zA-Z0-9.-]+' | \
    grep -v 'badge-development-constitution/' | grep -v 'check_secrets\.sh' || true)
print_matches "SSH user@host string" "$SSH_USER_MATCHES"

# ─── Scan: .env in tracked files ─────────────────────────────────────────

if echo "$FILES" | grep -qxF '.env' 2>/dev/null; then
    echo "[FAIL] check_secrets: .env file is tracked by git."
    FAIL=1
fi

# ─── Scan: AWS credential file references ────────────────────────────────

echo "Scanning for cloud credential references..."
AWS_CRED_MATCHES=$(grep_tracked '~/.aws/credentials\|AWS_ACCESS_KEY_ID\|AWS_SECRET_ACCESS_KEY\|GOOGLE_APPLICATION_CREDENTIALS\|AZURE_CLIENT_SECRET' | \
    grep -v '\.env-example' | grep -v 'badge-development-constitution/' || true)
print_matches "Cloud credential reference" "$AWS_CRED_MATCHES"

# ─── Result ──────────────────────────────────────────────────────────────

if [ $FAIL -eq 0 ]; then
    echo "[PASS] check_secrets: No secrets found in tracked files."
fi
exit $FAIL
