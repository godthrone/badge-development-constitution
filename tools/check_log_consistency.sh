#!/usr/bin/env bash
# check_log_consistency.sh — Cross-reference log file names in READMEs with
# actual log file paths in source code (§13.3, §17.1).
#
# README documentation of log files must match what the code actually creates.
# This script extracts log file names from both sides and reports mismatches.
#
# Usage: ./check_log_consistency.sh [project_root]

set -euo pipefail

PROJECT_ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || echo '.')}"
cd "$PROJECT_ROOT"

FAIL=0

README_EN="$PROJECT_ROOT/README.md"
README_CN="$PROJECT_ROOT/README.zh-CN.md"

# ─── Extract log file names from READMEs ───────────────────────────────────

extract_log_names() {
    local file="$1"
    if [ ! -f "$file" ]; then
        return
    fi
    # Match patterns like:
    #   - `logs/train.log`: ...
    #   - `logs/rollouts.readable.jsonl`: ...
    grep -oE 'logs/[a-zA-Z0-9_./-]+\.(log|jsonl|txt|json)' "$file" 2>/dev/null | \
        sed 's|.*logs/||' | sort -u || true
}

README_LOG_NAMES_EN=$(extract_log_names "$README_EN")
README_LOG_NAMES_CN=$(extract_log_names "$README_CN")
README_LOG_NAMES=$( (echo "$README_LOG_NAMES_EN"; echo "$README_LOG_NAMES_CN") | sort -u | grep -v '^$' || true)

if [ -z "$README_LOG_NAMES" ]; then
    echo "[SKIP] check_log_consistency: No log file references found in READMEs."
    exit 0
fi

echo "Log files referenced in READMEs:"
echo "$README_LOG_NAMES" | while IFS= read -r name; do
    [ -n "$name" ] && echo "  - logs/$name"
done

# ─── Extract log file names from source code ───────────────────────────────

CODE_LOG_NAMES=""
if [ -d "$PROJECT_ROOT/src" ]; then
    # Match patterns like:
    #   FileHandler(... / "training.log" ...)
    #   path / "training.log"
    #   open(".../train.log")
    #   "train.log"
    #   'rollouts.readable.jsonl'
    CODE_LOG_NAMES=$(grep -rhoE "['\"]([a-zA-Z0-9_./-]+\.(log|jsonl|txt))['\"]" \
        "$PROJECT_ROOT/src/" 2>/dev/null | \
        tr -d "'\"" | \
        sed 's|.*/||' | \
        grep -v '\.pyc\|\.egg-info\|__pycache__' | \
        sort -u || true)
fi

if [ -n "$CODE_LOG_NAMES" ]; then
    echo ""
    echo "Log files created in source code:"
    echo "$CODE_LOG_NAMES" | while IFS= read -r name; do
        [ -n "$name" ] && echo "  - $name"
    done
fi

# ─── Cross-reference ──────────────────────────────────────────────────────

echo ""
echo "Cross-referencing..."

while IFS= read -r readme_name; do
    [ -z "$readme_name" ] && continue

    # Check if this log name appears in source code
    if echo "$CODE_LOG_NAMES" | grep -qF "$readme_name" 2>/dev/null; then
        echo "  [OK] logs/$readme_name — found in README and source code"
    else
        # Try fuzzy match (e.g., train.log vs training.log)
        BASE="${readme_name%.*}"  # strip extension
        EXT="${readme_name##*.}"
        SIMILAR=$(echo "$CODE_LOG_NAMES" | grep -E "^${BASE:0:5}" || true)
        if [ -n "$SIMILAR" ]; then
            echo "  [FAIL] logs/$readme_name — in README but NOT in source code."
            echo "         Did you mean one of these?"
            echo "$SIMILAR" | while IFS= read -r s; do
                echo "           $s"
            done
            FAIL=1
        else
            echo "  [WARN] logs/$readme_name — in README but NOT found in source code. Verify manually."
        fi
    fi
done <<< "$README_LOG_NAMES"

# ─── Reverse: check source log names that should be in README ─────────────

# Only check .log files (not structured JSONL which may be intentionally undocumented)
CODE_LOG_FILES=$(echo "$CODE_LOG_NAMES" | grep '\.log$' || true)

while IFS= read -r code_name; do
    [ -z "$code_name" ] && continue
    if ! echo "$README_LOG_NAMES" | grep -qF "$code_name" 2>/dev/null; then
        echo "  [WARN] $code_name — in source code but NOT in README. Consider documenting it."
    fi
done <<< "$CODE_LOG_FILES"

echo ""
if [ $FAIL -eq 0 ]; then
    echo "[PASS] check_log_consistency: README log file references are consistent with source code."
else
    echo "[FAIL] check_log_consistency: Mismatches found."
fi
exit $FAIL
