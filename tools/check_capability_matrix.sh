#!/usr/bin/env bash
# check_capability_matrix.sh — Verify the capability & availability tier matrix
# per §17.7.
# Part of BADGE Constitution §17.7
#
# §17.7 requires every project that publishes a capability/availability tier
# matrix to keep the machine-readable data as the single source of truth, to
# regenerate the human-readable view byte-for-byte from it, to tag every tier
# with one of four verification states that agree with the two availability
# criteria, to state the measurement basis (口径) of every reference effect
# value and of every pass/fail criterion, and to declare the commitment
# boundary. The constitution fixes the *categories*; this script fixes the
# concrete matching patterns (declaration convention and data grammar), the
# same way §15.1 assigns "具体判定由 tools/ 脚本定义".
#
# ─── Applicability ────────────────────────────────────────────────────────
# §17.7 applies only to a project that actually publishes a capability matrix.
# A project declares one by adding a marker file at its repository root:
#
#     .badge-capability-matrix.conf
#
# No marker file → one [SKIP] line and exit 0. A project without a matrix can
# never fail here.
#
# ─── Declaration grammar (.badge-capability-matrix.conf) ──────────────────
# Line-oriented `key = value`; blank lines and `#` comments are ignored; paths
# are relative to the repository root; one layer of surrounding quotes is
# stripped. Unknown keys are [WARN] only — they cannot silently disable the
# check, because `data` and `view` are validated on their own:
#
#   data      = <path>   machine-readable matrix data (single source of truth)
#   view      = <path>   human-readable view, regenerated from `data`
#   generator = <cmd>    optional shell command that rewrites `view` from
#                        `data`; run with cwd = repository root via `bash -c`
#
# ─── Matrix data grammar (<path from `data`) ──────────────────────────────
# A TOML subset: `[section]` headers plus `key = value` lines, optional
# surrounding double quotes, ` #` starts a trailing comment. Section kinds:
#
#   [meta]                  optional metadata, not checked
#   [tier.<id>]             one availability tier
#     status                verified-available | verified-unavailable |
#                           unverified | not-in-scope
#                           (Chinese equivalents 已验证可用 / 已验证不可用 /
#                            尚未验证 / 未纳入验收 are accepted as well)
#     criterion-complete    pass|fail — criterion ①: runs end to end
#     criterion-effect      pass|fail — criterion ②: effect meets target
#     criterion-failed      required iff status = verified-unavailable;
#                           names the failed criterion: complete / effect
#   [metric.<id>]           one reference effect value or one criterion
#     kind                  criterion | effect-value
#     dataset-id            evaluation dataset identifier
#     dataset-source        dataset source / provenance
#     dataset-availability  whether that dataset is available to the reader
#     sample-size           positive integer
#     model                 model under evaluation
#     tier-config           tier / precision / batch configuration
#     criterion-id          identifier of the criterion being judged
#     threshold             target value (kind = criterion; must hold a number)
#     value                 measured effect value (kind = effect-value)
#     measurement-conditions  how the number was measured
#   [boundary]              three mandatory keys, wording free:
#     tier-availability          which tiers are covered / available
#     platform-dataset-conclusion  conclusion drawn on the platform dataset
#     user-effect-out-of-scope   user-visible effect is not a commitment
#
# Checks (all fail-closed — a hit is [FAIL] and exit 1):
#   1. byte-exact rebuild of `view` from `data` + declared generator
#      (only when `generator` is declared; otherwise an explicit [SKIP])
#   2. the four verification states agree with the two availability criteria
#   3. measurement-basis (口径) completeness of every [metric.<id>]
#   4. presence of the three commitment-boundary statements
#
# Usage: ./check_capability_matrix.sh [--class=A|B|C] [project_root]
# Exit:  0 all checks pass (including skip), 1 any check fails, 2 usage error.

set -euo pipefail

PROJECT_ROOT=""
for arg in "${@}"; do
    case "$arg" in
        --class=A|--class=B|--class=C) ;;   # accepted; §17.7 is class-independent
        -*) echo "Usage: check_capability_matrix.sh [--class=A|B|C] [project_root]" >&2; exit 2 ;;
        *) PROJECT_ROOT="$arg" ;;
    esac
done

PROJECT_ROOT="${PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || echo '.')}"
cd "$PROJECT_ROOT" || { echo "[FAIL] check_capability_matrix: cannot enter project root: $PROJECT_ROOT"; exit 1; }

DECL_FILE=".badge-capability-matrix.conf"

if [ ! -f "$DECL_FILE" ]; then
    echo "[SKIP] check_capability_matrix: no capability matrix declared (no $DECL_FILE); §17.7 does not apply."
    exit 0
fi

echo "Checking capability & availability tier matrix (§17.7)..."

FAIL=0
ISSUES=0            # total [FAIL] lines; per-check deltas decide the [OK] line
fail() { echo "  [FAIL] $*"; FAIL=1; ISSUES=$((ISSUES + 1)); }

# ─── 0. Parse the declaration ─────────────────────────────────────────────

DATA_PATH=""
VIEW_PATH=""
GENERATOR=""

while IFS= read -r raw || [ -n "$raw" ]; do
    line="${raw%$'\r'}"
    case "$line" in ''|'#'*) continue ;; esac
    # Trim leading whitespace so an indented comment is still a comment.
    ltrim="${line#"${line%%[![:space:]]*}"}"
    [ "${ltrim:0:1}" = "#" ] && continue
    line="$ltrim"

    if [ "${line#*=}" = "$line" ]; then
        echo "  [WARN] $DECL_FILE: malformed line (no '=') ignored: $line"
        continue
    fi
    key="${line%%=*}"
    val="${line#*=}"
    key="$(printf '%s' "$key" | tr -d '[:space:]')"
    val="$(printf '%s' "$val" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
    case "$val" in
        \"*\") val="${val#\"}"; val="${val%\"}" ;;
        \'*\') val="${val#\'}"; val="${val%\'}" ;;
    esac
    case "$key" in
        data) DATA_PATH="$val" ;;
        view) VIEW_PATH="$val" ;;
        generator) GENERATOR="$val" ;;
        *) echo "  [WARN] $DECL_FILE: unknown key '$key' ignored (known: data, view, generator)." ;;
    esac
done < "$DECL_FILE"

[ -n "$DATA_PATH" ] || fail "$DECL_FILE declares no 'data' path — the machine-readable matrix is required."
[ -n "$VIEW_PATH" ] || fail "$DECL_FILE declares no 'view' path — the human-readable view is required."
if [ -n "$DATA_PATH" ] && [ ! -f "$DATA_PATH" ]; then
    fail "Declared matrix data file not found: $DATA_PATH"
fi
if [ -n "$VIEW_PATH" ] && [ ! -f "$VIEW_PATH" ]; then
    fail "Declared human-readable view not found: $VIEW_PATH"
fi

# ─── Helpers for the data grammar ─────────────────────────────────────────

section_names() {
    grep -oE '^[[:space:]]*\[[^]]+\]' "$DATA_PATH" 2>/dev/null \
        | sed -E 's/^[[:space:]]*\[//; s/\][[:space:]]*$//' || true
}

# Print "key<TAB>value" for every key inside section $1.
extract_section() {
    awk -v want="$1" '
        /^[[:space:]]*\[/ {
            s = $0
            sub(/^[[:space:]]*\[/, "", s)
            sub(/\][[:space:]]*$/, "", s)
            cur = s
            next
        }
        cur == want {
            v = $0
            sub(/\r$/, "", v)
            if (match(v, /[[:space:]]#/)) v = substr(v, 1, RSTART - 1)
            p = index(v, "=")
            if (p > 0) {
                k = substr(v, 1, p - 1)
                val = substr(v, p + 1)
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", k)
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", val)
                if (k != "") print k "\t" val
            }
        }
    ' "$DATA_PATH" 2>/dev/null || true
}

# get_val SECTION KEY → value with one layer of quotes removed
get_val() {
    local sec="$1" want="$2" k v
    while IFS=$'\t' read -r k v; do
        if [ "$k" = "$want" ]; then
            case "$v" in
                \"*\") v="${v#\"}"; v="${v%\"}" ;;
                \'*\') v="${v#\'}"; v="${v%\'}" ;;
            esac
            printf '%s' "$v"
            return 0
        fi
    done < <(extract_section "$sec")
    return 0
}

norm_bool() {
    case "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" in
        pass|true|yes|ok|1|通过) printf 'pass' ;;
        fail|false|no|0|未通过) printf 'fail' ;;
        '') printf '' ;;
        *) printf 'invalid' ;;
    esac
}

# Maps a status literal to available|unavailable|unverified|outscope|invalid.
norm_status() {
    case "$1" in
        verified-available|已验证可用) printf 'available' ;;
        verified-unavailable|已验证不可用) printf 'unavailable' ;;
        unverified|尚未验证) printf 'unverified' ;;
        not-in-scope|未纳入验收) printf 'outscope' ;;
        *) printf 'invalid' ;;
    esac
}

contains_digit() { case "$1" in *[0-9]*) return 0 ;; *) return 1 ;; esac; }

# ─── 1. Human-readable view must rebuild byte-for-byte ────────────────────

if [ -z "$VIEW_PATH" ] || [ ! -f "$VIEW_PATH" ]; then
    echo "  [SKIP] Byte-exact rebuild not checked — declared view file is missing or undeclared."
elif [ -z "$GENERATOR" ]; then
    echo "  [SKIP] Byte-exact rebuild not checked — $DECL_FILE declares no 'generator' command."
    echo "         §17.7 makes the view regenerable from the data; declare one to make that checkable."
else
    ORIG="$(mktemp)"
    cp -- "$VIEW_PATH" "$ORIG"
    gen_out=""
    gen_rc=0
    gen_out="$(bash -c "$GENERATOR" 2>&1)" || gen_rc=$?
    if [ "$gen_rc" -ne 0 ]; then
        fail "Declared generator command failed (exit $gen_rc) — the view cannot be rebuilt from the data."
        if [ -n "$gen_out" ]; then
            printf '%s\n' "$gen_out" | head -n 8 | sed 's/^/         | /'
        fi
    elif [ ! -f "$VIEW_PATH" ]; then
        fail "Generator did not produce the declared view file: $VIEW_PATH"
    elif ! cmp -s "$ORIG" "$VIEW_PATH"; then
        fail "Regenerated view differs byte-for-byte from the on-disk file — hand-edited, or the generator is not deterministic."
        diff -u "$ORIG" "$VIEW_PATH" 2>/dev/null | head -n 12 | sed 's/^/         | /' || true
    else
        echo "  [OK] View regenerates byte-for-byte identically from the data (deterministic generator)."
    fi
    # A check must never leave the tree modified: restore the on-disk view.
    cp -- "$ORIG" "$VIEW_PATH"
    rm -f -- "$ORIG"
fi

if [ -z "$DATA_PATH" ] || [ ! -f "$DATA_PATH" ]; then
    echo ""
    echo "[FAIL] check_capability_matrix: matrix data missing — the four §17.7 checks cannot run."
    exit 1
fi

# ─── 2. Four verification states must agree with the criteria ─────────────

echo "  [--] Verification states & availability criteria:"
F2_BEFORE=$ISSUES
TIERS="$(section_names | grep '^tier\.' | sed 's/^tier\.//' || true)"
VERIFIED_SEEN=0
EFFECT_PASS_SEEN=0

if [ -z "$TIERS" ]; then
    fail "Matrix declares no [tier.<id>] section — every tier must carry an explicit verification state."
fi

for t in $TIERS; do
    [ -n "$t" ] || continue
    sec="tier.$t"
    status_raw="$(get_val "$sec" status)"
    st="$(norm_status "$status_raw")"
    c="$(norm_bool "$(get_val "$sec" criterion-complete)")"
    e="$(norm_bool "$(get_val "$sec" criterion-effect)")"
    cf="$(get_val "$sec" criterion-failed)"

    if [ "$st" = invalid ]; then
        fail "tier '$t': status '$status_raw' is not one of the four allowed states."
        continue
    fi
    if [ "$c" = invalid ]; then
        fail "tier '$t': criterion-complete must be pass|fail (got '$status_raw')."
        c=""
    fi
    if [ "$e" = invalid ]; then
        fail "tier '$t': criterion-effect must be pass|fail."
        e=""
    fi
    if [ "$e" = pass ]; then
        EFFECT_PASS_SEEN=1
    fi

    case "$st" in
        available)
            VERIFIED_SEEN=1
            if [ "$c" = pass ] && [ "$e" = pass ]; then
                if [ -n "$cf" ]; then
                    fail "tier '$t': status verified-available but criterion-failed is set ('$cf') — contradictory."
                fi
            else
                fail "tier '$t': verified-available requires BOTH criteria met (criterion-complete='${c:-missing}', criterion-effect='${e:-missing}')."
            fi
            ;;
        unavailable)
            VERIFIED_SEEN=1
            failed_list=""
            if [ "$c" = fail ]; then failed_list="complete"; fi
            if [ "$e" = fail ]; then failed_list="${failed_list:+$failed_list }effect"; fi
            if [ -z "$failed_list" ]; then
                fail "tier '$t': verified-unavailable but neither criterion is marked fail."
            elif [ -z "$cf" ]; then
                fail "tier '$t': verified-unavailable must name the failed criterion in criterion-failed (complete|effect)."
            else
                for tok in $(printf '%s' "$cf" | tr ',' ' '); do
                    case "$tok" in
                        complete|effect)
                            case " $failed_list " in
                                *" $tok "*) ;;
                                *) fail "tier '$t': criterion-failed names '$tok' but criterion-$tok is not marked fail." ;;
                            esac
                            ;;
                        *) fail "tier '$t': criterion-failed token '$tok' is not 'complete' or 'effect'." ;;
                    esac
                done
            fi
            ;;
        unverified|outscope)
            if [ "$c" = pass ] && [ "$e" = pass ]; then
                fail "tier '$t': both criteria pass but status is '$status_raw' — it should be verified-available."
            fi
            ;;
    esac
done

if [ "$ISSUES" -eq "$F2_BEFORE" ]; then
    echo "  [OK] Every tier carries one of the four states and its criteria are consistent."
fi

# ─── 3. Measurement-basis (口径) completeness of every metric ─────────────

echo "  [--] Measurement basis (口径) of reference values and criteria:"
F3_BEFORE=$ISSUES
METRICS="$(section_names | grep '^metric\.' | sed 's/^metric\.//' || true)"
CRIT_IDS=""
METRIC_COUNT=0

# First pass: collect every declared criterion identifier, so an effect-value
# metric may reference a criterion declared later in the file.
for m in $METRICS; do
    [ -n "$m" ] || continue
    if [ "$(get_val "metric.$m" kind)" = "criterion" ]; then
        cid="$(get_val "metric.$m" criterion-id)"
        [ -n "$cid" ] && CRIT_IDS="$CRIT_IDS $cid"
    fi
done

for m in $METRICS; do
    [ -n "$m" ] || continue
    METRIC_COUNT=$((METRIC_COUNT + 1))
    sec="metric.$m"

    for k in dataset-id dataset-source dataset-availability sample-size \
             model tier-config measurement-conditions; do
        if [ -z "$(get_val "$sec" "$k")" ]; then
            fail "metric '$m': missing measurement-basis field '$k'."
        fi
    done

    ss="$(get_val "$sec" sample-size)"
    if [ -n "$ss" ]; then
        case "$ss" in
            ''|*[!0-9]*) fail "metric '$m': sample-size '$ss' must be a positive integer." ;;
            *) if [ "$ss" -le 0 ]; then fail "metric '$m': sample-size must be greater than zero."; fi ;;
        esac
    fi

    case "$(get_val "$sec" kind)" in
        criterion)
            cid="$(get_val "$sec" criterion-id)"
            th="$(get_val "$sec" threshold)"
            [ -n "$cid" ] || fail "metric '$m' (criterion): missing 'criterion-id'."
            if [ -z "$th" ]; then
                fail "metric '$m' (criterion): missing 'threshold' — a pass/fail criterion must state its target value."
            elif ! contains_digit "$th"; then
                fail "metric '$m' (criterion): threshold '$th' states no target value (no number found)."
            fi
            ;;
        effect-value)
            val="$(get_val "$sec" value)"
            if [ -z "$val" ]; then
                fail "metric '$m' (effect-value): missing 'value'."
            elif ! contains_digit "$val"; then
                fail "metric '$m' (effect-value): value '$val' contains no number."
            fi
            cid="$(get_val "$sec" criterion-id)"
            if [ -z "$cid" ]; then
                fail "metric '$m' (effect-value): missing 'criterion-id' — a reference effect value must name the criterion it is compared against."
            else
                case " $CRIT_IDS " in
                    *" $cid "*) ;;
                    *) fail "metric '$m': criterion-id '$cid' does not resolve to any [metric.*] with kind = criterion." ;;
                esac
            fi
            ;;
        '')
            fail "metric '$m': missing 'kind' (criterion|effect-value)."
            ;;
        *)
            fail "metric '$m': kind '$(get_val "$sec" kind)' is not 'criterion' or 'effect-value'."
            ;;
    esac
done

if [ "$METRIC_COUNT" -eq 0 ]; then
    if [ "$VERIFIED_SEEN" -eq 1 ]; then
        fail "Matrix marks a tier as verified but declares no [metric.<id>] — an availability claim has no measurement basis."
    else
        echo "  [INFO] No [metric.<id>] declared; no tier claims verification, so no measurement basis is required."
    fi
else
    [ "$EFFECT_PASS_SEEN" -eq 0 ] || [ -n "$CRIT_IDS" ] \
        || fail "A tier passes criterion-effect but no [metric.*] with kind = criterion declares the effect threshold."
fi

if [ "$ISSUES" -eq "$F3_BEFORE" ]; then
    echo "  [OK] Every declared metric states its full measurement basis (口径)."
fi

# ─── 4. The commitment boundary must cover the three required points ──────

echo "  [--] Commitment boundary:"
F4_BEFORE=$ISSUES
BOUNDARY_SEC="$(section_names | grep -x 'boundary' || true)"

if [ -z "$BOUNDARY_SEC" ]; then
    fail "No [boundary] section — §17.7 requires the commitment boundary to be written out explicitly."
else
    for k in tier-availability platform-dataset-conclusion user-effect-out-of-scope; do
        if [ -z "$(get_val boundary "$k")" ]; then
            fail "[boundary]: missing '$k' — all three required boundary points must be present (tier availability, platform-dataset conclusion, user effect out of scope)."
        fi
    done
fi

if [ "$ISSUES" -eq "$F4_BEFORE" ]; then
    echo "  [OK] The commitment boundary covers tier availability, the platform-dataset conclusion and the out-of-scope user effect."
fi

# ─── Summary ──────────────────────────────────────────────────────────────

echo ""
if [ "$FAIL" -eq 0 ]; then
    echo "[PASS] check_capability_matrix: Capability matrix is regenerable, consistent and fully documented (§17.7)."
else
    echo "[FAIL] check_capability_matrix: Issues found."
fi
exit $FAIL
