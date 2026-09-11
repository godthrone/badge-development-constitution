#!/usr/bin/env bash
# check_secrets.sh — Scan tracked files, git history, and commit metadata for
# secrets and personal information (§15.1)
# Part of BADGE Constitution §15.1
#
# Checks for:
#   - IP addresses (internal/private ranges flagged)
#   - API keys, tokens, private keys
#   - Hardcoded passwords and secrets
#   - JWT tokens, base64-encoded credentials
#   - Internal file paths, SSH connection strings
#   - .env tracked by git
#   - Personal information (PII): emails, IM accounts, phone numbers, IDs
#   - Commit metadata: personal emails in author/committer identities
#
# Usage:
#   ./check_secrets.sh [project_root]               tree + history + metadata
#   ./check_secrets.sh --no-history [project_root]  working tree only
#   ./check_secrets.sh --pii=off|warn|fail          PII severity for content and
#                                                   git history (default: fail)
#   ./check_secrets.sh --meta-pii=off|warn|fail     PII severity for commit
#                                                   metadata (default: warn)
#   project_root defaults to the git repo root of the current directory.
#
# Public repositories should run with --meta-pii=fail so that a personal
# author/committer email fails the check (see §15.1 category 5).

set -euo pipefail

# ─── Argument parsing ────────────────────────────────────────────────────

HISTORY_MODE=true
PII_MODE="fail"        # content/history PII severity: off|warn|fail
META_PII_MODE="warn"   # commit-metadata PII severity: off|warn|fail
PROJECT_ROOT=""
for arg in "${@}"; do
    case "$arg" in
        --no-history) HISTORY_MODE=false ;;
        --pii=off|--pii=warn|--pii=fail) PII_MODE="${arg#--pii=}" ;;
        --meta-pii=off|--meta-pii=warn|--meta-pii=fail) META_PII_MODE="${arg#--meta-pii=}" ;;
        -*) echo "Usage: check_secrets.sh [--no-history] [--pii=off|warn|fail] [--meta-pii=off|warn|fail] [project_root]" >&2; exit 2 ;;
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
    # Generic API key patterns (quotes optional; whitespace around = / : allowed)
    'api[_-]?key\s*[=:]\s*["'"'"']?[a-zA-Z0-9_-]{16,}["'"'"']?'
    'api[_-]?secret\s*[=:]\s*["'"'"']?[a-zA-Z0-9_-]{16,}["'"'"']?'
)

# Hardcoded credential patterns (whitespace around = / : allowed, e.g. TOML style)
CREDENTIAL_PATTERNS=(
    'password\s*[=:]\s*["'"'"'][^"'"'"']{4,}["'"'"']'
    'passwd\s*[=:]\s*["'"'"'][^"'"'"']{4,}["'"'"']'
    'secret\s*[=:]\s*["'"'"'][a-zA-Z0-9_-]{8,}["'"'"']'
    'token\s*[=:]\s*["'"'"'][a-zA-Z0-9_-]{16,}["'"'"']'
    'access[_-]?key\s*[=:]\s*["'"'"'][a-zA-Z0-9]{8,}["'"'"']'
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

# Personal information (PII) patterns — §15.1 category 4
PII_EMAIL_PATTERN='[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'
PII_PATTERNS=(
    "$PII_EMAIL_PATTERN"
    # Mainland China mobile number (11 digits, starts with 1[3-9])
    '(^|[^0-9])1[3-9][0-9]{9}($|[^0-9])'
    # Mainland China landline (area code + 7-8 digit number)
    '(^|[^0-9])0[0-9]{2,3}-?[0-9]{7,8}($|[^0-9])'
    # QQ / WeChat / other IM accounts (keyword required, to limit false positives)
    '([Qq][Qq]|wechat|weixin|微信)[号:：= ]*[0-9]{5,12}'
    'wxid_[a-zA-Z0-9_-]{5,}'
    # Mainland China resident ID card (18 digits, last may be X)
    '(^|[^0-9])[1-9][0-9]{5}(19|20)[0-9]{2}(0[1-9]|1[0-2])(0[1-9]|[12][0-9]|3[01])[0-9]{3}[0-9Xx]($|[^0-9])'
)

# Addresses that are legitimately public / documented, exempt from PII findings:
# project mailboxes, example/reserved domains, placeholders, local addresses.
PII_ALLOWLIST='(example\.(com|org|net)|@example\.|noreply@|users\.noreply\.github\.com|maintainers?@|git@github\.com|anthropic\.com|REPLACE_ME|your-?email|placeholder|@[a-zA-Z0-9.-]*\.local)'

# ─── Helpers ─────────────────────────────────────────────────────────────

grep_tracked() {
    local pattern="$1"
    # -e keeps patterns that begin with '-' (e.g. the PEM private-key header)
    # from being parsed as grep options, which silently disabled that check.
    # -H keeps the filename prefix even when only one file matches.
    # -i lets keyword patterns match API_KEY / PASSWORD / TOKEN in any case.
    echo "$FILES" | xargs grep -nEHi -e "$pattern" 2>/dev/null || true
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
    # Added lines from every patch, tagged with the commit hash. The @@ marker
    # is emitted by --format so the hash survives: --format replaces git's
    # "commit <hash>" header, which the old awk parser never matched, leaving
    # the commit field empty in every finding.
    git log --all -p --format='@@BADGE-COMMIT %h @@' 2>/dev/null | awk '
        /^@@BADGE-COMMIT / { commit=$2; next }
        /^\+\+\+ /         { file=$0; sub(/^\+\+\+ b\//, "", file); next }
        /^\+/              { if ($0 !~ /^\+\+\+/) print commit ":" file ":" substr($0,2) }
    ' > "$stream"
    # Commit messages are part of what a push publishes — scan them as well.
    git log --all --format='@@BADGE-COMMIT %h @@%n%B' 2>/dev/null | awk '
        /^@@BADGE-COMMIT / { commit=$2; next }
        { if (length($0) > 0) print commit ":" "(commit-message):" $0 }
    ' >> "$stream"
}

grep_history() {
    local stream="$1"
    local pattern="$2"
    if [ -s "$stream" ]; then
        grep -nEi -e "$pattern" "$stream" 2>/dev/null || true
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
        grep -vE '^[[:space:]]*#' | \
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

# ─── Scan: Personal information (PII) — §15.1 category 4 ─────────────────
#
# Severity controlled by --pii=off|warn|fail (default: fail). Emails and phone
# numbers are high-false-positive categories, so PII_ALLOWLIST exempts project
# mailboxes, example domains and explicit placeholders.

if [ "$PII_MODE" != "off" ]; then
    echo "Scanning for personal information (PII)..."
    PII_HITS=""
    for pattern in "${PII_PATTERNS[@]}"; do
        HIT=$(grep_tracked "$pattern" | \
            grep -vE "$PII_ALLOWLIST" | \
            grep -v 'check_secrets\.sh' | \
            grep -v '\.env-example' || true)
        PII_HITS="${PII_HITS}${HIT}"$'\n'
    done
    PII_HITS=$(printf '%s' "$PII_HITS" | sed '/^$/d' | awk '!seen[$0]++')
    if [ -n "$PII_HITS" ]; then
        if [ "$PII_MODE" = "fail" ]; then
            echo "[FAIL] check_secrets: Personal information (PII) found:"
            FAIL=1
        else
            echo "[WARN] check_secrets: Personal information (PII) found (review manually):"
        fi
        echo "$PII_HITS" | head -20 | while IFS= read -r line; do echo "  $line"; done
        PII_COUNT=$(printf '%s\n' "$PII_HITS" | wc -l)
        if [ "$PII_COUNT" -gt 20 ]; then
            echo "  ... and $((PII_COUNT - 20)) more lines"
        fi
    fi
fi

# ─────────────────────────────────────────────────────────────────────────
# Phase 2: Git history scan (default on; disable with --no-history)
# ─────────────────────────────────────────────────────────────────────────

if $HISTORY_MODE; then
    echo ""
    echo "─── Scanning git history for secrets and PII ───"

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
            grep -v 'badge-development-constitution/' | \
            grep -v 'check_secrets\.sh' | _filter_history_false_positives || true)
        if [ -n "$HIST_SSH" ]; then
            echo "[FAIL] check_secrets (history): SSH connection string in git history:"
            echo "$HIST_SSH" | head -10 | while IFS= read -r line; do
                echo "  $line"
            done
            HISTORY_FAIL=1
        fi

        HIST_SSH_USER=$(grep_history "$HIST_STREAM" 'ssh\s+\w+@[a-zA-Z0-9.-]+' | \
            grep -v 'badge-development-constitution/' | \
            grep -v 'check_secrets\.sh' | _filter_history_false_positives || true)
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
            # Exclude the scanner's own source (mirrors the working-tree scan):
            # INTERNAL_PATH_PATTERNS contains strings like /root/ and /var/log/,
            # which would otherwise match their own definitions in history.
            # Commit messages are excluded here too: they legitimately discuss
            # such paths (including these very pattern definitions), which would
            # produce self-referential false positives. Content/patch lines are
            # still scanned.
            HIST_PATH=$(grep_history "$HIST_STREAM" "$path_pattern" | \
                grep -v 'badge-development-constitution/' | \
                grep -v 'check_secrets\.sh' | \
                grep -v '(commit-message):' | \
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

        # ── History: Personal information (PII) ──

        if [ "$PII_MODE" != "off" ]; then
            echo "Scanning history for personal information (PII)..."
            HIST_PII=""
            for pattern in "${PII_PATTERNS[@]}"; do
                HIT=$(grep_history "$HIST_STREAM" "$pattern" | \
                    grep -vE "$PII_ALLOWLIST" | \
                    grep -v 'badge-development-constitution/' | \
                    grep -v 'check_secrets\.sh' | \
                    grep -v '\.env-example' || true)
                HIST_PII="${HIST_PII}${HIT}"$'\n'
            done
            HIST_PII=$(printf '%s' "$HIST_PII" | sed '/^$/d' | awk '!seen[$0]++')
            if [ -n "$HIST_PII" ]; then
                if [ "$PII_MODE" = "fail" ]; then
                    echo "[FAIL] check_secrets (history): Personal information (PII) in git history:"
                    HISTORY_FAIL=1
                else
                    echo "[WARN] check_secrets (history): Personal information (PII) in git history (review manually):"
                fi
                echo "$HIST_PII" | head -20 | while IFS= read -r line; do echo "  $line"; done
                HIST_PII_COUNT=$(printf '%s\n' "$HIST_PII" | wc -l)
                if [ "$HIST_PII_COUNT" -gt 20 ]; then
                    echo "  ... and $((HIST_PII_COUNT - 20)) more lines"
                fi
            fi
        fi

        # ── History: Result ──

        if [ $HISTORY_FAIL -eq 0 ]; then
            echo "[PASS] check_secrets (history): No secrets or PII found in git history."
        else
            FAIL=1
        fi
    fi
fi

# ─────────────────────────────────────────────────────────────────────────
# Phase 3: Commit metadata scan (author/committer identity) — §15.1 cat. 5
# ─────────────────────────────────────────────────────────────────────────
#
# A push publishes commit metadata as well. Content/patch scans cannot see the
# author/committer identity, so it is checked separately here. Default severity
# is warn; public repositories should pass --meta-pii=fail.

if $HAS_GIT && [ "$META_PII_MODE" != "off" ]; then
    echo ""
    echo "─── Scanning commit metadata for personal emails ───"
    META_RAW=$(git log --all --format='%h|%an <%ae>|%cn <%ce>' 2>/dev/null || true)
    META_HITS=$(printf '%s\n' "$META_RAW" | grep -vE "$PII_ALLOWLIST" | grep -E "$PII_EMAIL_PATTERN" || true)
    if [ -n "$META_HITS" ]; then
        if [ "$META_PII_MODE" = "fail" ]; then
            echo "[FAIL] check_secrets (metadata): Personal email in commit author/committer identity:"
            FAIL=1
        else
            echo "[WARN] check_secrets (metadata): Personal email in commit author/committer identity (review manually):"
        fi
        echo "$META_HITS" | head -20 | while IFS= read -r line; do echo "  $line"; done
        META_COUNT=$(printf '%s\n' "$META_HITS" | wc -l)
        if [ "$META_COUNT" -gt 20 ]; then
            echo "  ... and $((META_COUNT - 20)) more lines"
        fi
    else
        echo "[PASS] check_secrets (metadata): No personal email in commit metadata."
    fi
fi

# ─── Result ──────────────────────────────────────────────────────────────

if [ $FAIL -eq 0 ]; then
    echo "[PASS] check_secrets: No secrets or PII found in tracked files."
fi
exit $FAIL