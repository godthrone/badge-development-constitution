#!/usr/bin/env bash
# check_exception_handling.sh — Detect swallowed exceptions and bare excepts
# Part of BADGE Constitution §13.1
#
# Checks for:
#   - `except Exception: pass` or `except Exception:pass`
#   - `except: pass` (bare except + pass)
#   - `except ... :` followed by a line with only `pass`
#   - Empty except blocks
#
# Usage: ./check_exception_handling.sh [project_root]

set -euo pipefail

PROJECT_ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || echo '.')}"
cd "$PROJECT_ROOT"

FAIL=0

# Collect Python source files
if ! git rev-parse --git-dir &>/dev/null 2>&1; then
    echo "[SKIP] check_exception_handling: Not a git repository."
    exit 0
fi

PY_FILES=$(git ls-files --cached --others --exclude-standard 2>/dev/null | \
    grep '\.py$' | grep -v '__pycache__/' | grep -v '\.egg-info/' | \
    grep -v 'badge-development-constitution/' || true)

if [ -z "$PY_FILES" ]; then
    echo "[PASS] check_exception_handling: No Python files to check."
    exit 0
fi

echo "Checking for swallowed exceptions..."

# ─── 1. Single-line: except ... : pass ──────────────────────────────────

# Match: except [ExceptionType]: pass (same line)
SINGLE_LINE_SWALLOW=$(echo "$PY_FILES" | xargs grep -nE 'except[^:]*:\s*pass\s*(#.*)?$' 2>/dev/null || true)
# Filter out false positives:
# - Comments like "# noqa", "# nosec"
# - Blocks that fall through intentionally with a comment explaining why
SINGLE_LINE_SWALLOW=$(echo "$SINGLE_LINE_SWALLOW" | grep -vE '#\s*(noqa|nosec|intentional|allowed|expected)' || true)

if [ -n "$SINGLE_LINE_SWALLOW" ]; then
    echo "[FAIL] check_exception_handling: Swallowed exception (except ... : pass):"
    echo "$SINGLE_LINE_SWALLOW" | while IFS= read -r line; do
        echo "  $line"
    done
    FAIL=1
fi

# ─── 2. Bare except: (no exception type) ────────────────────────────────
#
# §13.1 (C:723) forbids `except Exception: pass` and 裸 `except: pass` — i.e. the
# *swallowing* forms — and requires every `except` block to carry explicit
# handling. A bare `except:` that still handles the error (e.g. `except: log(); raise`)
# is therefore NOT forbidden by the letter of §13.1: report it as advisory, not FAIL.

# `-H` forces the filename prefix even when only ONE file is searched: GNU grep
# omits "file:" for a single argument, which would make the hit_file/hit_line
# parsing below read the line number as the file name (single-.py-file projects).
BARE_EXCEPT=$(echo "$PY_FILES" | xargs grep -HnE '^\s*except\s*:' 2>/dev/null | \
    grep -vE '#\s*(noqa|nosec|intentional|allowed)' || true)

if [ -n "$BARE_EXCEPT" ]; then
    BARE_SWALLOW=""
    BARE_ADVISORY=""
    while IFS= read -r hit; do
        [ -z "$hit" ] && continue
        hit_file="${hit%%:*}"
        hit_rest="${hit#*:}"
        hit_line="${hit_rest%%:*}"
        # Inline `except: pass`
        if printf '%s\n' "$hit" | grep -qE 'except\s*:\s*pass\s*(#.*)?$'; then
            BARE_SWALLOW="${BARE_SWALLOW}${hit}"$'\n'
            continue
        fi
        # Next line is exactly `pass` (optionally with a trailing comment)
        next_content=$(sed -n "$((hit_line + 1))p" "$hit_file" 2>/dev/null | sed 's/^[[:space:]]*//' || true)
        if printf '%s\n' "$next_content" | grep -qE '^pass\s*(#.*)?$'; then
            BARE_SWALLOW="${BARE_SWALLOW}${hit}"$'\n'
        else
            BARE_ADVISORY="${BARE_ADVISORY}${hit}"$'\n'
        fi
    done <<< "$BARE_EXCEPT"

    if [ -n "$BARE_SWALLOW" ]; then
        echo "[FAIL] check_exception_handling: Swallowed exception (bare except: pass):"
        printf '%s' "$BARE_SWALLOW" | while IFS= read -r line; do
            [ -n "$line" ] && echo "  $line"
        done
        echo "         §13.1 绝对禁止裸 except: pass —— 块内必须有明确处理逻辑。"
        FAIL=1
    fi
    if [ -n "$BARE_ADVISORY" ]; then
        echo "[WARN] check_exception_handling: Bare except with explicit handling (allowed by §13.1, but narrow it):"
        printf '%s' "$BARE_ADVISORY" | while IFS= read -r line; do
            [ -n "$line" ] && echo "  $line"
        done
    fi
fi

# ─── 3. except Exception: pass (broad catch + swallow) ───────────────────

BROAD_SWALLOW=$(echo "$PY_FILES" | xargs grep -nE 'except\s+(Exception|BaseException)\s*:\s*pass\s*(#.*)?$' 2>/dev/null | \
    grep -vE '#\s*(noqa|nosec|intentional)' || true)

if [ -n "$BROAD_SWALLOW" ]; then
    echo "[FAIL] check_exception_handling: except Exception: pass (swallowed broad exception):"
    echo "$BROAD_SWALLOW" | while IFS= read -r line; do
        echo "  $line"
    done
    FAIL=1
fi

# ─── 4. Multi-line empty except blocks ──────────────────────────────────

# Find except lines followed by just pass (on next line) with nothing else
# We use a heuristic: files with 'except' that also have 'pass' on the very next line
while IFS= read -r file; do
    [ -z "$file" ] && continue
    if [ ! -f "$file" ]; then continue; fi
    # Find line numbers of 'except' and check if next non-comment line is 'pass'
    EXCEPT_LINES=$(grep -nE '^\s*except[^:]*:' "$file" 2>/dev/null | cut -d: -f1 || true)
    for line_no in $EXCEPT_LINES; do
        # Bare `except:` is owned by check 2 above (same swallow, clearer message)
        except_src=$(sed -n "${line_no}p" "$file" 2>/dev/null || true)
        if printf '%s\n' "$except_src" | grep -qE '^\s*except\s*:'; then
            continue
        fi
        next_line=$((line_no + 1))
        NEXT_CONTENT=$(sed -n "${next_line}p" "$file" 2>/dev/null | sed 's/^[[:space:]]*//' || true)
        if [ "$NEXT_CONTENT" = "pass" ]; then
            # Check it's not preceded by a comment explaining why
            prev_line=$((line_no - 1))
            PREV_CONTENT=$(sed -n "${prev_line}p" "$file" 2>/dev/null || true)
            if ! echo "$PREV_CONTENT" | grep -qE '#\s*(noqa|nosec|intentional|allowed|expected)'; then
                echo "[FAIL] check_exception_handling: Empty except block:"
                echo "  $file:$line_no: $(sed -n "${line_no}p" "$file" | sed 's/^[[:space:]]*//')"
                FAIL=1
            fi
        fi
    done
done <<< "$PY_FILES"

# ─── Summary ─────────────────────────────────────────────────────────────

echo ""
if [ $FAIL -eq 0 ]; then
    echo "[PASS] check_exception_handling: No swallowed exceptions found."
else
    echo "[FAIL] check_exception_handling: Swallowed exceptions found. Every except block must have explicit handling (§13.1)."
fi
exit $FAIL
