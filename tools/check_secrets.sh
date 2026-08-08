#!/usr/bin/env bash
# check_secrets.sh — Scan tracked files and (optionally) git history for secrets (§15.1)
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
# Usage:
#   ./check_secrets.sh [project_root]              scan current tree + git history
#   ./check_secrets.sh --no-history [project_root]  scan current working tree only
#   project_root defaults to the git repo root of the current directory.

set -euo pipefail

# ─── Argument parsing ────────────────────────────────────────────────────

HISTORY_MODE=true
PROJECT_ROOT=""
for arg in "${@}"; do
    case "$arg" in
        --no-history) HISTORY_MODE=false ;;
        -*) echo "Usage: check_secrets.sh [--no-history] [project_root]" >&2; exit 2 ;;
        *) PROJECT_ROOT="$arg" ;;
    esac
done

PROJECT_ROOT="${PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || echo '.')}"
cd "$PROJECT_ROOT"

HAS_GIT=false
if git rev-parse --git-dir &>/dev/null; then
    HAS_GIT=true
fi

FAIL=0

# ─── Pattern definitions ─────────────────────────────────────────────────

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

# ─── Helpers ─────────────────────────────────────────────────────────────

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

# ─── Git history stream builder ──────────────────────────────────────────
#
# Builds a temp file of all added lines from the entire git history.
# Each line is formatted as: <commit_short>:<file>:<line_content>
# This is scanned once, then all patterns are applied to it — much faster
# than running git log per pattern.

_build_history_stream() {
    local stream="$1"
    if ! $HAS_GIT; then
        return 1
    fi
    git log --all -p --format="%H" 2>/dev/null | awk '
        /^commit /  { commit=substr($0,8,9) }
        /^---\//   { next }
        /^\+\+\+ /  { file=$0; sub(/^\+\+\+ b\//, "", file) }
        /^\+/       { if ($0 !~ /^\+\+\+/) print commit ":" file ":" substr($0,2) }
    ' > "$stream"
}

grep_history() {
    local stream="$1"
    local pattern="$2"
    local grep_opts="${3:--nE}"
    if [ -s "$stream" ]; then
        grep $grep_opts "$pattern" "$stream" 2>/dev/null || true
    fi
}

# Filter out common false positives from history scan results.
# Placeholder usernames (user, admin, test), demo hostnames (gpu-host, server),
# standard Docker paths, and version strings in lockfiles.
_filter_history_false_positives() {
    grep -vE \
        -e '/home/(user|admin|test|example)/' \
        -e 'ssh (user|admin|test|example)@' \
        -e '@(gpu-host|localhost|example\.com|server\.example)' \
        -e ':/root/\.(local|cache|config)/' \
        -e ':/root/\.local/bin' \
        -e ':docker/Dockerfile' \
        -e 'RUN --mount=type=cache,target=/root/' \
        || true
}

# ─────────────────────────────────────────────────────────────────────────
# Phase 1: Current working tree scan (always runs)
# ─────────────────────────────────────────────────────────────────────────

if $HAS_GIT; then
    FILES=$(git ls-files --cached --others --exclude-standard 2>/dev/null || true)
    if [ -z "$FILES" ]; then
        echo "[PASS] check_secrets: No tracked files found."
        if ! $HISTORY_MODE; then
            exit 0
        fi
    fi
else
    echo "[SKIP] check_secrets: Not a git repository."
    exit 0
fi

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
    grep -v 'check_secrets\.sh' | \
    grep -v 'sha256:[A-Za-z0-9]' || true)
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
        grep -v 'badge-development-constitution/' | grep -v 'check_secrets\.sh' | \
        grep -v 'RUN --mount=type=cache,target=/root/.cache' || true)
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

# ─────────────────────────────────────────────────────────────────────────
# Phase 2: Git history scan (only when --history is passed)
# ─────────────────────────────────────────────────────────────────────────

if $HISTORY_MODE; then
    echo ""
    echo "─── Scanning git history for secrets ───"

    HIST_STREAM=$(mktemp)
    trap "rm -f '$HIST_STREAM'" EXIT

    _build_history_stream "$HIST_STREAM"

    if [ ! -s "$HIST_STREAM" ]; then
        echo "[PASS] check_secrets (history): No git history to scan."
    else
        HISTORY_FAIL=0

        # ── History: Private IPs ──

        echo "Scanning history for private IPs..."
        HIST_IP=$(grep_history "$HIST_STREAM" "$IPV4_PATTERN")
        HIST_IP=$(echo "$HIST_IP" | grep -v '0\.0\.0\.0' | grep -v '127\.0\.0\.1' | \
            grep -v '255\.255\.255\.255' | grep -v 'files\.pythonhosted\.org' | \
            grep -v ':uv\.lock:' | grep -v 'version.*=.*"[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+"' || true)
        HIST_PRIVATE_IP=$(echo "$HIST_IP" | grep -E "$(IFS='|'; echo "${PRIVATE_IP_PATTERNS[*]}")" | \
            _filter_history_false_positives || true)
        if [ -n "$HIST_PRIVATE_IP" ]; then
            echo "[FAIL] check_secrets (history): Private/internal IPs in git history:"
            echo "$HIST_PRIVATE_IP" | head -30 | while IFS= read -r line; do
                echo "  $line"
            done
            COUNT=$(echo "$HIST_PRIVATE_IP" | wc -l)
            if [ "$COUNT" -gt 30 ]; then
                echo "  ... and $((COUNT - 30)) more lines"
            fi
            HISTORY_FAIL=1
        fi

        # ── History: API keys ──

        echo "Scanning history for API keys and tokens..."
        for pattern in "${KEY_PATTERNS[@]}"; do
            HIST_KEY=$(grep_history "$HIST_STREAM" "$pattern" | \
                grep -v 'badge-development-constitution/' | grep -v '\.env-example' || true)
            if [ -n "$HIST_KEY" ]; then
                echo "[FAIL] check_secrets (history): API key/token in git history:"
                echo "$HIST_KEY" | head -10 | while IFS= read -r line; do
                    echo "  $line"
                done
                HISTORY_FAIL=1
            fi
        done

        # ── History: Hardcoded credentials ──

        echo "Scanning history for hardcoded credentials..."
        for pattern in "${CREDENTIAL_PATTERNS[@]}"; do
            HIST_CRED=$(grep_history "$HIST_STREAM" "$pattern" | \
                grep -v 'badge-development-constitution/' | grep -v 'check_secrets\.sh' || true)
            if [ -n "$HIST_CRED" ]; then
                echo "[FAIL] check_secrets (history): Hardcoded credential in git history:"
                echo "$HIST_CRED" | head -10 | while IFS= read -r line; do
                    echo "  $line"
                done
                HISTORY_FAIL=1
            fi
        done

        # ── History: SSH strings ──

        echo "Scanning history for SSH strings..."
        HIST_SSH=$(grep_history "$HIST_STREAM" 'ssh.*@[0-9]' | \
            grep -v 'badge-development-constitution/' | _filter_history_false_positives || true)
        if [ -n "$HIST_SSH" ]; then
            echo "[FAIL] check_secrets (history): SSH connection string in git history:"
            echo "$HIST_SSH" | head -10 | while IFS= read -r line; do
                echo "  $line"
            done
            HISTORY_FAIL=1
        fi

        HIST_SSH_USER=$(grep_history "$HIST_STREAM" 'ssh\s+\w+@[a-zA-Z0-9.-]+' | \
            grep -v 'badge-development-constitution/' | _filter_history_false_positives || true)
        if [ -n "$HIST_SSH_USER" ]; then
            echo "[FAIL] check_secrets (history): SSH user@host in git history:"
            echo "$HIST_SSH_USER" | head -10 | while IFS= read -r line; do
                echo "  $line"
            done
            HISTORY_FAIL=1
        fi

        # ── History: Internal paths ──

        echo "Scanning history for internal paths..."
        for path_pattern in "${INTERNAL_PATH_PATTERNS[@]}"; do
            HIST_PATH=$(grep_history "$HIST_STREAM" "$path_pattern" | \
                grep -v 'badge-development-constitution/' | \
                grep -v 'RUN --mount=type=cache,target=/root/.cache' | \
                _filter_history_false_positives || true)
            if [ -n "$HIST_PATH" ]; then
                echo "[FAIL] check_secrets (history): Internal path ($path_pattern) in git history:"
                echo "$HIST_PATH" | head -10 | while IFS= read -r line; do
                    echo "  $line"
                done
                HISTORY_FAIL=1
            fi
        done

        # ── History: JWT tokens ──

        echo "Scanning history for JWT tokens..."
        HIST_JWT=$(grep_history "$HIST_STREAM" "$JWT_PATTERN" | \
            grep -v 'badge-development-constitution/' || true)
        if [ -n "$HIST_JWT" ]; then
            echo "[FAIL] check_secrets (history): JWT token in git history:"
            echo "$HIST_JWT" | head -10 | while IFS= read -r line; do
                echo "  $line"
            done
            HISTORY_FAIL=1
        fi

        # ── History: .env files that were once tracked ──

        echo "Scanning history for .env files..."
        if git log --all --diff-filter=A --name-only --format="" -- '.env' 2>/dev/null | grep -q '.'; then
            echo "[FAIL] check_secrets (history): .env file was tracked in git history:"
            git log --all --diff-filter=A --name-only --oneline -- '.env' 2>/dev/null | head -10 | while IFS= read -r line; do
                echo "  $line"
            done
            HISTORY_FAIL=1
        fi

        # ── History: Result ──

        if [ $HISTORY_FAIL -eq 0 ]; then
            echo "[PASS] check_secrets (history): No secrets found in git history."
        else
            FAIL=1
        fi
    fi
fi

# ─── Result ──────────────────────────────────────────────────────────────

if [ $FAIL -eq 0 ]; then
    echo "[PASS] check_secrets: No secrets found in tracked files."
fi
exit $FAIL