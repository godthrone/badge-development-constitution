#!/usr/bin/env bash
# check_constitution_text.sh — Read-only invariant checks on the constitution
# text itself (§17.8: layer / modality / applicability markers, and the
# "layered restructure" evidence required by its 生效范围 clause ③).
#
# NOT registered in tools/check_all.sh, by design: check_all.sh is the
# compliance entry point for CONSUMER projects (all of its run_check targets are
# project properties). These five invariants are properties of the constitution
# text, so every consumer run would print a row of [SKIP]s and mix
# "self-compliance" into "project compliance". This script belongs to the
# release gate of the constitution repository only — see docs/release-checklist.md §1.
#
# Usage:
#   ./check_constitution_text.sh [options]
#
#   --zh <file>             Chinese edition (truth source). Default: newest
#                           BADGE-constitution-v*.zh-CN.md in the repo root.
#   --en <file>             English edition (translation). Default: newest
#                           BADGE-constitution-v*.en.md in the repo root.
#   --semantic-diff <file>  Semantic rewrite manifest for C5.
#                           Default: tools/constitution-v3-semantic-diff.txt
#   --prev-tag <tag>        Previous release tag to compare against in C5.
#                           Default: v2.10.0
#   --only <list>           Run only the listed checks, e.g. --only C1,C3.
#                           Default: C1,C2,C3,C4,C5. Every check is read-only
#                           and can be run on its own.
#   -h, --help              This text.
#
# The five checks (all read-only):
#   C1  Coverage & syntax — every real h1/h2/h3 (fence-aware; a code block's
#       comment lines are not headings) that is a *minimal normative unit*
#       carries exactly one marker at the end of its line, and every token of
#       that marker is in §17.8's closed set (layer / modality / category /
#       trigger form). Missing, duplicated or illegal markers → FAIL. The
#       document title and headings that have subsections are not units and
#       must NOT carry a marker.
#   C2  Bilingual marker sequence — the zh and en marker token sequences are
#       compared item by item after mapping the English tokens back to the
#       canonical Chinese form (§17.8 marker syntax / §3.4 of the framework
#       design: all↔全类, self↔宪自, each trigger word ↔ its Chinese word).
#       A difference in length or content → FAIL.
#   C3  L3 block markers — a fenced code block is a template landing point and
#       must be covered either by the block-level marker on the line
#       immediately above it (one blank line tolerated; zh 〔L3｜采用本模板时〕,
#       en 〔L3｜template-adopted〕) or by an L3 marker on its enclosing section
#       heading. The two counts must add up to the number of fenced blocks.
#       Only top-level fences (column 0) are counted: a fence indented inside a
#       list item is a snippet inside a clause body, not an adoptable template.
#       Those are counted and printed separately, so nothing goes invisible.
#   C4  L1 purity (WARN only) — the body of a section marked L1 must not carry
#       a concrete technology or a numeric criterion as a requirement. Reported
#       as a WARN list for human review; never fails the run (an L1 section may
#       legitimately cite an example while refuting it).
#   C5  Migration invariant (one-off, rerunnable) — the Chinese text with all
#       *markers* stripped (line-end markers and marker-only lines; inline 〔…〕
#       examples in prose are kept — that is the whole point) must differ from
#       the previous release, `git show <prev-tag>:<file>`, only inside the
#       ranges declared in the semantic rewrite manifest. Anything else means
#       an undeclared semantic edit → FAIL. A missing tag → SKIP, never FAIL.
#       The same manifest also carries *change records* ("what did this release
#       change?") in new-edition coordinates — N<n> a new clause, X<n> a revised
#       line. Each record is a positive assertion and is verified, so a wrong
#       line number or an anchor on an unchanged line FAILS rather than passing
#       silently. Range coverage alone cannot express "this section is new in
#       this release": a hunk is the finest granularity the range model has, and
#       an inserted section that abuts a rewritten paragraph shares that hunk
#       under every diff alignment.
#
# Output: one status line per check ([PASS]/[FAIL]/[WARN]/[SKIP]) and a final
# summary (Passed / Failed / Warnings / Skipped). Exit code: 0 when no check
# failed, 1 when any failed, 2 on a usage error.
#
# Only bash + grep/sed/awk/sort are used (no python), matching the rest of
# tools/.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# ─── §17.8 closed sets (single definition inside this script) ─────────────

ZH_LAYERS="L1 L2 L3"
EN_LAYERS="L1 L2 L3"
ZH_MODALITIES="M R"
EN_MODALITIES="M R"
ZH_CATEGORIES="A B C A/B 全类 宪自"
EN_CATEGORIES="A B C A/B all self"
# Trigger forms, in the order §17.8 lists them. `+` joins several; each part is
# checked against this list on its own.
ZH_TRIGGERS="无条件 有代码 有容器 有部署环境 有可选档位或量化结论 有数据产物 提供 CLI 有多套同接口实现 有配置文件 有自动化测试 有启动脚本 有版本发布 有 git 仓库 有 README 有提示词 使用 AI 助手 采用本模板时 长时运行 面向公开分发"
EN_TRIGGERS="unconditional code container deployment tiers-or-quantified-claims data-artifacts cli multiple-implementations config-files automated-tests startup-script versioned-releases git-repo readme prompt-text ai-assistant template-adopted long-running public-distribution"
# Block-level marker used by C3 (one line of its own, immediately above the block).
ZH_BLOCK_MARKER="〔L3｜采用本模板时〕"
EN_BLOCK_MARKER="〔L3｜template-adopted〕"

# ─── Argument parsing ────────────────────────────────────────────────────

ZH_FILE=""
EN_FILE=""
SEMANTIC_DIFF="$SCRIPT_DIR/constitution-v3-semantic-diff.txt"
PREV_TAG="v2.10.0"
ONLY="C1 C2 C3 C4 C5"

usage() {
    # Print this file's leading comment block: from line 2 up to the
    # `set -euo pipefail` line that closes it (excluded). Anchored on that line
    # instead of a hardcoded range so editing the header cannot truncate --help.
    sed -n '2,/^set -euo/{/^set -euo/d;p}' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

need_arg() {
    [ "$2" -ge 2 ] || { echo "Error: $1 needs a value." >&2; echo "Try --help." >&2; exit 2; }
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        --zh)
            need_arg --zh "$#"
            ZH_FILE="$2"; shift 2
            ;;
        --en)
            need_arg --en "$#"
            EN_FILE="$2"; shift 2
            ;;
        --semantic-diff)
            need_arg --semantic-diff "$#"
            SEMANTIC_DIFF="$2"; shift 2
            ;;
        --prev-tag)
            need_arg --prev-tag "$#"
            PREV_TAG="$2"; shift 2
            ;;
        --only)
            need_arg --only "$#"
            # Normalised to a space-separated list so `in_list` can match one id.
            ONLY="$(printf '%s' "$2" | tr ',' ' ' | tr '[:lower:]' '[:upper:]')"; shift 2
            ;;
        -*)
            echo "Error: unknown option $1." >&2
            echo "Try --help." >&2
            exit 2
            ;;
        *)
            echo "Error: unexpected argument $1 (all paths are given via --zh/--en)." >&2
            echo "Try --help." >&2
            exit 2
            ;;
    esac
done

# Version-independent default: the newest edition, whatever the version is, so
# bumping the version in the filename can never break the gate.
newest() {
    local suffix="$1"
    ls "$PROJECT_ROOT"/BADGE-constitution-v*."$suffix" 2>/dev/null | sort -V | tail -1 || true
}
[ -n "$ZH_FILE" ] || ZH_FILE="$(newest zh-CN.md)"
[ -n "$EN_FILE" ] || EN_FILE="$(newest en.md)"

# ─── Shared helpers ──────────────────────────────────────────────────────

PASSED=0
FAILED=0
WARNED=0
SKIPPED=0
FAILED_NAMES=()

# Status line per check. `$2` is the check id, `$3` the human-readable verdict.
status() {
    local verdict="$1" id="$2"
    shift 2
    printf '[%s] %s %s\n' "$verdict" "$id" "$*"
    case "$verdict" in
        PASS) PASSED=$((PASSED + 1)) ;;
        FAIL) FAILED=$((FAILED + 1)); FAILED_NAMES+=("$id") ;;
        WARN) WARNED=$((WARNED + 1)) ;;
        SKIP) SKIPPED=$((SKIPPED + 1)) ;;
    esac
}

# Which language a file is, from its name; also the label used in messages.
lang_of() {
    case "$1" in
        *.zh-CN.md) echo zh ;;
        *.en.md)    echo en ;;
        *)          echo zh ;;   # --zh override with an arbitrary name
    esac
}

# Emit every heading outside fenced code blocks, one record per line:
#   <line> <level> <is_leaf> <marker_count> <marker_at_end> <marker text|-> <raw line>
#
# is_leaf: no deeper heading follows before the next same-or-shallower one,
# i.e. this heading is a minimal normative unit (the level a marker belongs on).
# Fence awareness matters: `# config.toml — …` inside a template block is a
# comment, not an h1; the naive grep counted 15 h1s instead of the real 6.
scan_headings() {
    awk '
        /^[ \t]*```/ { infence = !infence; next }
        infence { next }
        /^#{1,3}[ \t]/ {
            n++
            lvl = 0; rest = $0
            while (substr(rest, 1, 1) == "#") { lvl++; rest = substr(rest, 2) }
            line[n] = FNR; lvl_of[n] = lvl; raw[n] = $0
            marker[n] = "-"
            if (match($0, /〔[^〕]*〕[ \t]*$/)) {
                marker[n] = substr($0, RSTART, RLENGTH)
                sub(/[ \t]+$/, "", marker[n])
            }
            tmp = $0; cnt[n] = gsub(/〔[^〕]*〕/, "", tmp)
            atend[n] = ($0 ~ /〔[^〕]*〕[ \t]*$/) ? 1 : 0
        }
        END {
            for (i = 1; i <= n; i++) {
                leaf = 1
                if (i < n && lvl_of[i + 1] > lvl_of[i]) leaf = 0
                printf "%d\t%d\t%d\t%d\t%d\t%s\t%s\n", \
                    line[i], lvl_of[i], leaf, cnt[i], atend[i], marker[i], raw[i]
            }
        }
    ' "$1"
}

# Line each *top-level* fenced code block opens on (fence at column 0).
#
# An indented fence (`   ```python` nested in a list item) is an inline example
# inside a clause body, not a template landing point: §17.8's rule about
# templates is about blocks a reader can adopt, and every such block in this
# text is at column 0. Indented snippets are counted separately and reported,
# so they stay visible without being asserted as templates.
scan_fences() {
    awk '/^```/ { if (!infence) { infence = 1; print FNR } else { infence = 0 } }' "$1"
}
scan_nested_fences() {
    awk '/^[ \t]+```/ { if (!infence) { infence = 1; n++ } else { infence = 0 } } END { print n + 0 }' "$1"
}

in_list() { # $1 = needle, $2 = space-separated list
    case " $2 " in
        *" $1 "*) return 0 ;;
        *) return 1 ;;
    esac
}

# Parse one marker into its four fields and validate each against the closed
# set of the given language. Prints one problem per line, nothing when clean.
#   $1 = marker without the 〔〕 brackets, $2 = zh|en
validate_marker() {
    local body="$1" lang="$2" layers mods cats triggers
    local layer_part cat_part layer modality category trigger part

    if [ "$lang" = en ]; then
        layers="$EN_LAYERS"; mods="$EN_MODALITIES"; cats="$EN_CATEGORIES"; triggers="$EN_TRIGGERS"
    else
        layers="$ZH_LAYERS"; mods="$ZH_MODALITIES"; cats="$ZH_CATEGORIES"; triggers="$ZH_TRIGGERS"
    fi

    # The field separator may be written either way (§17.8: the separators may
    # change shape); ｜ is the canonical form, so an ASCII | is normalised first.
    case "$body" in
        *｜*) : ;;
        *)    body="${body//|/｜}" ;;
    esac
    case "$body" in
        *｜*｜*) echo "more than one field separator ｜"; return 0 ;;
        *｜*) : ;;
        *) echo "missing field separator ｜ (expected 〔layer[·modality]｜category[·trigger]〕)"; return 0 ;;
    esac

    layer_part="${body%%｜*}"
    cat_part="${body#*｜}"

    # Layer, optionally ·modality.
    layer="${layer_part%%·*}"
    in_list "$layer" "$layers" || echo "illegal layer '$layer' (closed set: $layers)"
    case "$layer_part" in
        *·*)
            modality="${layer_part#*·}"
            in_list "$modality" "$mods" || echo "illegal modality '$modality' (closed set: $mods)"
            if [ "$layer" = "L1" ] || [ "$layer" = "L3" ]; then
                echo "modality '$modality' on '$layer' — §17.8: modality is written for L2 only"
            fi
            ;;
        *)
            # §17.8: every L2 clause carries its modality (M or R).
            [ "$layer" = "L2" ] && echo "L2 without modality — §17.8 requires M or R on every L2 marker"
            ;;
    esac

    # Category, optionally ·trigger 1[+trigger 2…].
    category="${cat_part%%·*}"
    in_list "$category" "$cats" || echo "illegal category '$category' (closed set: $cats)"
    case "$cat_part" in
        *·*)
            trigger="${cat_part#*·}"
            [ -n "$trigger" ] || echo "empty trigger form after ·"
            # `+` joins several forms; each part must be in the closed set.
            local rest="$trigger"
            while [ -n "$rest" ]; do
                part="${rest%%+*}"
                if [ "$part" = "$rest" ]; then rest=""; else rest="${rest#*+}"; fi
                [ -n "$part" ] || { echo "empty trigger form in '$trigger' (stray +)"; continue; }
                in_list "$part" "$triggers" || echo "illegal trigger form '$part' (closed set: $triggers)"
            done
            ;;
        *)
            # The trigger form is optional in §17.8's marker syntax
            # `〔layer[·modality]｜category[·trigger form]〕`: an L1 clause
            # applies to everything by definition, so it often carries only the
            # category. Absence is not an error; an ILLEGAL word is.
            :
            ;;
    esac
}

# Map an English marker body onto the canonical Chinese form so C2 can compare
# the two editions token by token (§17.8 marker syntax, framework design §3.4).
normalize_en() {
    local m="$1"
    m="$(printf '%s' "$m" | tr '|' '｜')"
    # Longest tokens first is unnecessary: no English token is a substring of
    # another one, but the order below keeps the intent readable.
    m="${m//tiers-or-quantified-claims/有可选档位或量化结论}"
    m="${m//multiple-implementations/有多套同接口实现}"
    m="${m//public-distribution/面向公开分发}"
    m="${m//versioned-releases/有版本发布}"
    m="${m//automated-tests/有自动化测试}"
    m="${m//template-adopted/采用本模板时}"
    m="${m//data-artifacts/有数据产物}"
    m="${m//config-files/有配置文件}"
    m="${m//startup-script/有启动脚本}"
    m="${m//long-running/长时运行}"
    m="${m//ai-assistant/使用 AI 助手}"
    m="${m//git-repo/有 git 仓库}"
    m="${m//deployment/有部署环境}"
    m="${m//unconditional/无条件}"
    m="${m//container/有容器}"
    m="${m//readme/有 README}"
    m="${m//prompt-text/有提示词}"
    m="${m//code/有代码}"
    m="${m//cli/提供 CLI}"
    m="${m//all/全类}"
    m="${m//self/宪自}"
    printf '%s' "$m"
}

# C2 needs the marker sequence only; the heading ordinal is used for messages.
marker_sequence() { # $1 = file, $2 = zh|en
    local file="$1" lang="$2"
    scan_headings "$file" | awk -F'\t' '$3 == 1 && $6 != "-" { printf "%d\t%s\n", $1, $6 }' |
        while IFS=$'\t' read -r ln mk; do
            body="${mk#〔}"; body="${body%〕}"
            if [ "$lang" = en ]; then body="$(normalize_en "$body")"; fi
            printf '%d\t〔%s〕\n' "$ln" "$body"
        done
}

want() { in_list "$1" "$ONLY"; }

echo "============================================"
echo " Constitution text invariants (§17.8)"
echo " zh: ${ZH_FILE:-<none>}"
echo " en: ${EN_FILE:-<none>}"
echo " checks: $(printf '%s' "$ONLY" | tr ' ' ',')"
echo "============================================"
echo ""

# ─── C1: coverage & syntax ───────────────────────────────────────────────

c1_one_file() {
    local file="$1" lang="$2" label issues units marked h1s
    label="$(basename "$file")"
    issues=0
    units=0
    marked=0
    h1s=0

    # One scan, reused for the loop and for the document-title test (the title is
    # the file's first heading; scanning once per heading would be O(n^2)).
    local headings
    headings="$(scan_headings "$file")"
    local title_line
    title_line="$(printf '%s\n' "$headings" | head -1 | cut -f1)"

    # Records: line level is_leaf marker_count marker_at_end marker raw
    while IFS=$'\t' read -r ln lvl leaf cnt atend marker raw; do
        [ "$lvl" -eq 1 ] && h1s=$((h1s + 1))
        # The document title is the first h1 of the file: a title, not a unit.
        local is_title=0
        if [ "$ln" = "$title_line" ] && [ "$lvl" -eq 1 ]; then
            is_title=1
        fi
        if [ "$is_title" -eq 1 ]; then
            continue
        fi
        if [ "$leaf" -eq 1 ]; then
            units=$((units + 1))
            if [ "$cnt" -eq 0 ]; then
                echo "  ${label}:${ln}: minimal normative unit has no marker at the end of the line"
                issues=$((issues + 1))
                continue
            fi
            if [ "$cnt" -gt 1 ] || [ "$atend" -ne 1 ]; then
                echo "  ${label}:${ln}: expected exactly one marker at the end of the line, found ${cnt}"
                issues=$((issues + 1))
                continue
            fi
            marked=$((marked + 1))
            local body="${marker#〔}"; body="${body%〕}"
            local problems
            problems="$(validate_marker "$body" "$lang")"
            if [ -n "$problems" ]; then
                while IFS= read -r p; do
                    [ -n "$p" ] && echo "  ${label}:${ln}: ${p}"
                done <<< "$problems"
                issues=$((issues + 1))
            fi
        else
            # A heading with subsections is not the landing point (§17.8).
            if [ "$cnt" -gt 0 ]; then
                echo "  ${label}:${ln}: marker on a heading with subsections ('${marker}') — §17.8 puts it on the minimal normative unit"
                issues=$((issues + 1))
            fi
        fi
    done <<< "$headings"

    echo "  ${label}: ${marked}/${units} minimal normative units carry exactly one legal marker; ${h1s} real h1 (fence-aware)"
    return "$issues"
}

if want C1; then
    echo "── C1 coverage & syntax ──"
    c1_issues=0
    missing_file=0
    for spec in "$ZH_FILE:zh" "$EN_FILE:en"; do
        f="${spec%:*}"; l="${spec##*:}"
        if [ -z "$f" ] || [ ! -f "$f" ]; then
            echo "  [SKIP] no edition for '$l' (pass --$l <file> or add the file to the repo root)"
            missing_file=1
            continue
        fi
        c1_one_file "$f" "$l" || c1_issues=$((c1_issues + $?))
    done
    if [ "$missing_file" -eq 1 ] && [ "$c1_issues" -eq 0 ]; then
        status SKIP C1 "no constitution edition found."
    elif [ "$c1_issues" -eq 0 ]; then
        status PASS C1 "every minimal normative unit carries exactly one legal marker on both editions."
    else
        status FAIL C1 "${c1_issues} marker problem(s) — see the list above."
    fi
    echo ""
fi

# ─── C2: bilingual marker sequence ───────────────────────────────────────

if want C2; then
    echo "── C2 bilingual marker sequence ──"
    if [ -z "$ZH_FILE" ] || [ -z "$EN_FILE" ] || [ ! -f "$ZH_FILE" ] || [ ! -f "$EN_FILE" ]; then
        status SKIP C2 "both editions are required (pass --zh and --en)."
    else
        ZH_SEQ="$(marker_sequence "$ZH_FILE" zh)"
        EN_SEQ="$(marker_sequence "$EN_FILE" en)"
        zh_n=$(printf '%s\n' "$ZH_SEQ" | grep -c . || true)
        en_n=$(printf '%s\n' "$EN_SEQ" | grep -c . || true)
        c2_issues=0
        if [ "$zh_n" -ne "$en_n" ]; then
            echo "  marker count differs: zh=${zh_n}, en=${en_n} (§17.8: both editions carry the same clause set)"
            c2_issues=$((c2_issues + 1))
        fi
        # Compare item by item; report the first mismatch and then keep counting
        # so the size of the drift is visible.
        i=0
        while IFS=$'\t' read -r zl zm; do
            i=$((i + 1))
            el="$(printf '%s\n' "$EN_SEQ" | sed -n "${i}p" | cut -f1)"
            em="$(printf '%s\n' "$EN_SEQ" | sed -n "${i}p" | cut -f2)"
            [ -n "${em:-}" ] || break
            if [ "$zm" != "$em" ]; then
                c2_issues=$((c2_issues + 1))
                if [ "$c2_issues" -le 10 ]; then
                    echo "  item ${i}: zh:${zl} ${zm}"
                    echo "            en:${el} ${em}  (mapped back to the canonical form)"
                fi
            fi
        done <<< "$ZH_SEQ"
        if [ "$c2_issues" -eq 0 ]; then
            status PASS C2 "zh and en marker sequences are identical (${zh_n} markers)."
        else
            status FAIL C2 "${c2_issues} difference(s) between the zh and en marker sequences."
        fi
    fi
    echo ""
fi

# ─── C3: L3 block markers ────────────────────────────────────────────────

c3_one_file() {
    local file="$1" lang="$2" block_marker="$3"
    local label blocks covered_by_block covered_by_section total issues ln prev prev2 heading_marker
    label="$(basename "$file")"
    blocks=0
    covered_by_block=0
    covered_by_section=0
    issues=0

    # Enclosing section marker for a given line: the closest preceding heading.
    # The heading table is scanned once and reused for every block.
    local headings
    headings="$(scan_headings "$file")"
    section_marker_at() {
        printf '%s\n' "$headings" |
            awk -F'\t' -v target="$1" '$1 < target { m = $6 } END { print m }'
    }

    while IFS= read -r ln; do
        [ -n "$ln" ] || continue
        blocks=$((blocks + 1))
        prev="$(sed -n "$((ln - 1))p" "$file")"
        prev2="$(sed -n "$((ln - 2))p" "$file")"
        if [ "$prev" = "$block_marker" ]; then
            covered_by_block=$((covered_by_block + 1))
        elif [ -z "$(printf '%s' "$prev" | tr -d '[:space:]')" ] && [ "$prev2" = "$block_marker" ]; then
            # One blank line between the marker and the fence is tolerated.
            covered_by_block=$((covered_by_block + 1))
        else
            heading_marker="$(section_marker_at "$ln")"
            case "$heading_marker" in
                '〔L3'*)
                    # The enclosing section is itself L3, so its blocks inherit it.
                    covered_by_section=$((covered_by_section + 1))
                    ;;
                *)
                    echo "  ${label}:${ln}: fenced block has no L3 block marker on the line above and its section is not L3"
                    issues=$((issues + 1))
                    ;;
            esac
        fi
    done < <(scan_fences "$file")

    # The other direction: a block marker that is not above a fenced block is a
    # misplaced marker (its block was moved or deleted).
    while IFS= read -r ln; do
        case "$ln" in ''|*[!0-9]*) continue ;; esac
        next1="$(sed -n "$((ln + 1))p" "$file")"
        next2="$(sed -n "$((ln + 2))p" "$file")"
        case "$next1" in
            '```'*|' '*```*|$'\t'*```*) continue ;;
        esac
        if [ -z "$(printf '%s' "$next1" | tr -d '[:space:]')" ]; then
            case "$next2" in
                '```'*|' '*```*|$'\t'*```*) continue ;;
            esac
        fi
        echo "  ${label}:${ln}: block-level L3 marker is not immediately above a fenced block"
        issues=$((issues + 1))
    done < <(grep -n -F -x "$block_marker" "$file" 2>/dev/null | cut -d: -f1 || true)

    total=$((covered_by_block + covered_by_section))
    nested="$(scan_nested_fences "$file")"
    echo "  ${label}: ${total}/${blocks} fenced blocks covered (${covered_by_block} by a block marker, ${covered_by_section} by an L3 section); ${nested} indented snippet(s) inside clause bodies, not templates"
    return "$issues"
}

if want C3; then
    echo "── C3 L3 block markers ──"
    c3_issues=0
    c3_seen=0
    for spec in "$ZH_FILE:zh:$ZH_BLOCK_MARKER" "$EN_FILE:en:$EN_BLOCK_MARKER"; do
        f="${spec%%:*}"; rest="${spec#*:}"; l="${rest%%:*}"; bm="${rest#*:}"
        if [ -z "$f" ] || [ ! -f "$f" ]; then
            continue
        fi
        c3_seen=$((c3_seen + 1))
        c3_one_file "$f" "$l" "$bm" || c3_issues=$((c3_issues + $?))
    done
    if [ "$c3_seen" -eq 0 ]; then
        status SKIP C3 "no constitution edition found."
    elif [ "$c3_issues" -eq 0 ]; then
        status PASS C3 "every fenced block is covered by a block marker or an L3 section."
    else
        status FAIL C3 "${c3_issues} fenced block(s) without an L3 marker."
    fi
    echo ""
fi

# ─── C4: L1 purity (warning only) ────────────────────────────────────────

if want C4; then
    echo "── C4 L1 purity (warn-only) ──"
    c4_warns=0
    c4_sections=0
    for f in "$ZH_FILE" "$EN_FILE"; do
        if [ -z "$f" ] || [ ! -f "$f" ]; then
            continue
        fi
        label="$(basename "$f")"
        # Slice each L1 section (heading → next heading of any level) and look
        # for a requirement pinned to a concrete technology or a number.
        while IFS=$'\t' read -r start end; do
            c4_sections=$((c4_sections + 1))
            hits="$(sed -n "${start},${end}p" "$f" | grep -nE \
                '(每个|所有|任何)项目必须|(必须|禁止|不得).{0,12}(Docker|docker|pytest|pydantic|pyproject|requirements\.txt|\.toml|uv\.lock|uv )|(必须|禁止|不得)[^。；！？]{0,12}[0-9]+' \
                2>/dev/null || true)"
            if [ -n "$hits" ]; then
                while IFS= read -r h; do
                    [ -n "$h" ] || continue
                    c4_warns=$((c4_warns + 1))
                    if [ "$c4_warns" -le 12 ]; then
                        echo "  ${label}:$((start + ${h%%:*} - 1)): L1 section states a requirement on a concrete technology or number — review by hand"
                        echo "    ${h#*:}"
                    fi
                done <<< "$hits"
            fi
        done < <(scan_headings "$f" | awk -F'\t' '
            { line[NR] = $1; mk[NR] = $6 }
            END {
                for (i = 1; i <= NR; i++) {
                    if (mk[i] ~ /^〔L1/) {
                        # body runs to the line before the next heading
                        end = (i < NR) ? line[i + 1] - 1 : line[i]
                        printf "%d\t%d\n", line[i], end
                    }
                }
            }')
    done
    if [ "$c4_sections" -eq 0 ]; then
        status SKIP C4 "no L1 section found."
    elif [ "$c4_warns" -eq 0 ]; then
        status PASS C4 "no L1 section pins a requirement to a concrete technology or number (${c4_sections} L1 sections)."
    else
        status WARN C4 "${c4_warns} L1 section line(s) worth a human look (warn-only, does not affect the exit code)."
    fi
    echo ""
fi

# ─── C5: migration invariant ─────────────────────────────────────────────

if want C5; then
    echo "── C5 migration invariant (markers stripped vs $PREV_TAG) ──"
    if [ -z "$ZH_FILE" ] || [ ! -f "$ZH_FILE" ]; then
        status SKIP C5 "no Chinese edition to compare."
    elif ! git -C "$PROJECT_ROOT" rev-parse --git-dir >/dev/null 2>&1; then
        status SKIP C5 "not a git repository — the previous release cannot be read."
    elif ! git -C "$PROJECT_ROOT" rev-parse -q --verify "refs/tags/$PREV_TAG" >/dev/null 2>&1; then
        # A missing tag is an environment condition, not a defect in the text.
        status SKIP C5 "previous release tag $PREV_TAG not found."
    elif [ ! -f "$SEMANTIC_DIFF" ]; then
        status SKIP C5 "semantic rewrite manifest not found: $SEMANTIC_DIFF"
    else
        prev_path="$(git -C "$PROJECT_ROOT" ls-tree --name-only "$PREV_TAG" |
            grep -E '^BADGE-constitution-v.*\.zh-CN\.md$' | sort -V | tail -1 || true)"
        if [ -z "$prev_path" ]; then
            status SKIP C5 "$PREV_TAG has no Chinese edition."
        else
            tmpdir="$(mktemp -d)"
            trap 'rm -rf "$tmpdir"' EXIT
            git -C "$PROJECT_ROOT" show "$PREV_TAG:$prev_path" > "$tmpdir/prev.md" 2>/dev/null || true
            # Strip rule (fixed, do not widen):
            #   1. a marker at the END of a line is metadata → delete it;
            #   2. a line that is ONLY a marker (block-level L3) → delete it.
            # Inline 〔…〕 inside prose (§17.8's syntax paragraph) is clause
            # text and MUST survive: a global 〔〕 deletion would hide real edits.
            sed -E 's/[ \t]*〔[^〕]*〕[ \t]*$//' "$ZH_FILE" |
                sed -E '/^[ \t]*〔[^〕]*〕[ \t]*$/d' > "$tmpdir/stripped.md"

            # Hunks without context, in previous-release coordinates.
            diff -U0 "$tmpdir/prev.md" "$tmpdir/stripped.md" |
                sed -nE 's/^@@ -([0-9]+)(,([0-9]+))? \+\+?[0-9]+.*/\1\t\3/p' > "$tmpdir/hunks.txt" || true

            # Declared ranges from the manifest: "<ids> <start>-<end> <note>".
            # Change records ("<N|X><n> <line> <anchor>") use new-edition line
            # numbers and are verified separately below — they are NOT coverage
            # ranges, so they are filtered out here.
            grep -vE '^[[:space:]]*(#|$)' "$SEMANTIC_DIFF" |
                grep -vE '^[[:space:]]*[NX][0-9]' |
                awk '{ n = split($2, a, "-"); start = a[1]; end = (n > 1) ? a[2] : a[1]; printf "%s\t%s\t%s\n", start, end, $1 }' \
                > "$tmpdir/declared.txt" || true

            if [ ! -s "$tmpdir/hunks.txt" ]; then
                status PASS C5 "the stripped text is byte-identical to $PREV_TAG:$prev_path."
            else
                # Every hunk must sit inside one declared range.
                # NB: `NR == FNR` cannot be used here — with an EMPTY first file
                # it is still true for the second file's first line, which would
                # silently turn every hunk into a "declared range" and make the
                # check pass with no manifest at all. Compare FILENAME instead.
                uncovered="$(awk -F'\t' '
                    FILENAME == ARGV[1] {
                        dstart[++nd] = $1; dend[nd] = $2; ids[nd] = $3
                        next
                    }
                    {
                        s = $1; c = ($2 == "" ? 1 : $2)
                        e = (c == 0) ? s : s + c - 1
                        found = 0
                        for (i = 1; i <= nd; i++) {
                            if (s >= dstart[i] && e <= dend[i]) { found = 1; break }
                        }
                        if (!found) printf "%s-%s\n", s, e
                    }
                ' "$tmpdir/declared.txt" "$tmpdir/hunks.txt")"

                # Declared ranges that no longer produce a hunk: the manifest is
                # stale, which weakens the evidence but breaks no invariant.
                stale="$(awk -F'\t' '
                    FILENAME == ARGV[1] {
                        s = $1; c = ($2 == "" ? 1 : $2)
                        hs = (++nh); hstart[nh] = s; hend[nh] = (c == 0) ? s : s + c - 1
                        next
                    }
                    {
                        hit = 0
                        for (i = 1; i <= nh; i++) {
                            if (hstart[i] >= $1 && hend[i] <= $2) { hit = 1; break }
                        }
                        if (!hit) printf "%s-%s %s\n", $1, $2, $3
                    }
                ' "$tmpdir/hunks.txt" "$tmpdir/declared.txt")"

                n_declared=$(grep -c . "$tmpdir/declared.txt" || true)
                n_hunks=$(grep -c . "$tmpdir/hunks.txt" || true)

                # ── Change records: what this release actually changed ────
                # "<N|X><n>  <line>  <anchor>  — note", new-edition line
                # numbers.  A record asserts something, so a wrong record must
                # fail rather than pass quietly:
                #   * the anchor must sit on the declared line;
                #   * the anchor must be scope-unique — N: the only *heading*
                #     containing it, X: the only *line* — so a mistyped line
                #     number cannot match by luck;
                #   * the full text of that line, after the marker strip, must
                #     NOT occur verbatim in PREV_TAG: a line that did not
                #     change is not a change;
                #   * N must be a heading (a new clause), X must not be (that
                #     would be a new clause declared as a revision).
                records="$(grep -E '^[[:space:]]*[NX][0-9]+[[:space:]]' "$SEMANTIC_DIFF" || true)"
                n_records=0
                rec_issues=""
                if [ -n "$records" ]; then
                    while IFS= read -r rec; do
                        [ -n "$rec" ] || continue
                        n_records=$((n_records + 1))
                        rid="$(printf '%s\n' "$rec" | awk '{print $1}')"
                        rline="$(printf '%s\n' "$rec" | awk '{print $2}')"
                        ranchor="$(printf '%s\n' "$rec" | awk '{print $3}')"
                        case "$rline" in
                            ''|*[!0-9]*)
                                rec_issues="${rec_issues}  ${rid}: line number '${rline}' is not a number"$'\n'
                                continue ;;
                        esac
                        if [ -z "$ranchor" ]; then
                            rec_issues="${rec_issues}  ${rid}: no anchor given (expected '<id> <line> <anchor> — note')"$'\n'
                            continue
                        fi
                        rtext="$(sed -n "${rline}p" "$ZH_FILE")"
                        if [ -z "$rtext" ]; then
                            rec_issues="${rec_issues}  ${rid}: $(basename "$ZH_FILE") line ${rline} is empty or missing — the declared line is wrong"$'\n'
                            continue
                        fi
                        case "$rtext" in
                            *"$ranchor"*) : ;;
                            *)
                                rec_issues="${rec_issues}  ${rid}: anchor '${ranchor}' is not on $(basename "$ZH_FILE"):${rline} — the declared line is wrong"$'\n'
                                continue ;;
                        esac
                        case "$rid" in
                            N*)
                                case "$rtext" in
                                    '#'*) : ;;
                                    *)
                                        rec_issues="${rec_issues}  ${rid}: declares a NEW clause but line ${rline} is not a heading"$'\n'
                                        continue ;;
                                esac
                                hits="$(grep -E '^#{1,3}[ \t]' "$ZH_FILE" | grep -Fc -- "$ranchor" || true)"
                                ;;
                            *)
                                case "$rtext" in
                                    '#'*)
                                        rec_issues="${rec_issues}  ${rid}: declares a REVISED line but line ${rline} is a heading (a new clause belongs in N<n>)"$'\n'
                                        continue ;;
                                esac
                                hits="$(grep -Fc -- "$ranchor" "$ZH_FILE" || true)"
                                ;;
                        esac
                        if [ "${hits:-0}" -ne 1 ]; then
                            rec_issues="${rec_issues}  ${rid}: anchor '${ranchor}' matches ${hits:-0} line(s) in scope — it must be distinctive (exactly 1)"$'\n'
                            continue
                        fi
                        # Compare on the marker-stripped line: `prev.md` is the
                        # previous release, where a heading carries no 〔…〕
                        # marker (the marker system postdates it).  Comparing the
                        # RAW line against it could never match — every heading
                        # record would pass the "is it really a change?" test
                        # vacuously, which is worse than not testing at all.
                        # Same strip rule as C5's hunk comparison, applied to the
                        # one line (a marker-only line strips to empty and is
                        # then "identical" to the blank lines of the old file,
                        # i.e. correctly not a change).
                        rtext_s="$(printf '%s\n' "$rtext" | sed -E 's/[ \t]*〔[^〕]*〕[ \t]*$//')"
                        if grep -Fxq -- "$rtext_s" "$tmpdir/prev.md"; then
                            rec_issues="${rec_issues}  ${rid}: $(basename "$ZH_FILE"):${rline} is identical to $PREV_TAG after the marker strip — a declared change must differ from it"$'\n'
                            continue
                        fi
                    done <<< "$records"
                fi

                echo "  $n_hunks hunk(s) after stripping, $n_declared declared range(s), $n_records change record(s) in $(basename "$SEMANTIC_DIFF")"

                if [ -n "$rec_issues" ]; then
                    printf '%s' "$rec_issues"
                fi

                if [ -n "$uncovered" ] || [ -n "$rec_issues" ]; then
                    # Cap the detail: a wholly undeclared edit would otherwise
                    # print every hunk of the document.
                    shown=0
                    while IFS= read -r u; do
                        [ -n "$u" ] || continue
                        shown=$((shown + 1))
                        [ "$shown" -le 20 ] || continue
                        s="${u%-*}"; e="${u#*-}"
                        anchor="$(awk -v target="$s" '
                            /^#{1,3}[ \t]/ && FNR <= target { h = $0 }
                            END { print h }
                        ' "$tmpdir/prev.md" | cut -c1-70)"
                        echo "  $PREV_TAG:${u}: difference outside the declared rewrite list — under ${anchor:-<document start>}"
                    done <<< "$uncovered"
                    if [ "$shown" -gt 20 ]; then
                        echo "  … $(($shown - 20)) more undeclared hunk(s) not listed"
                    fi
                    c5_why=""
                    if [ -n "$uncovered" ]; then
                        c5_why="$(printf '%s\n' "$uncovered" | grep -c .) undeclared difference(s) vs $PREV_TAG"
                    fi
                    if [ -n "$rec_issues" ]; then
                        [ -z "$c5_why" ] || c5_why="$c5_why and "
                        c5_why="${c5_why}$(printf '%s\n' "$rec_issues" | grep -c .) invalid change record(s)"
                    fi
                    status FAIL C5 "$c5_why — either the edit is out of scope (§17.8 condition ③) or the manifest is wrong."
                else
                    if [ -n "$stale" ]; then
                        # Highlighted with a plain `note:` rather than a [WARN]
                        # status line: the invariant itself still passes, and the
                        # summary must not report a warning the status line denies.
                        echo "  note: declared range(s) with no difference (manifest hygiene, not a failure):"
                        printf '%s\n' "$stale" | while IFS= read -r line; do
                            [ -n "$line" ] && echo "    $line"
                        done
                    fi
                    status PASS C5 "all differences vs $PREV_TAG fall inside the declared rewrite list, and every declared change record verifies."
                fi
            fi
        fi
    fi
    echo ""
fi

# ─── Summary ─────────────────────────────────────────────────────────────

echo "============================================"
echo " Summary"
echo "============================================"
echo "  Passed: $PASSED"
echo "  Failed: $FAILED"
echo "  Warnings: $WARNED (see [WARN] lines above; warnings do not affect the exit code)"
echo "  Skipped: $SKIPPED"
if [ "$FAILED" -gt 0 ]; then
    echo ""
    echo "  Failed checks: ${FAILED_NAMES[*]}"
    exit 1
fi
exit 0
