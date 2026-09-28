#!/usr/bin/env bash
# check_dockerfile.sh — Verify Dockerfile follows §14.3 requirements
# Part of BADGE Constitution §14.3
#
# Checks for:
#   - Dockerfile exists
#   - Base image uses specific version (not :latest)
#   - Two-layer build (dependency layer + source layer, §14.3)
#   - uv is used for dependency installation (not pip install -r requirements.txt)
#   - build.sh or docker/build.sh exists
#   - No build-time source ENV directives and no ARG→ENV laundering
#     (§14.3 代理不得污染运行时): the name group PROXY|INDEX|MIRROR|REGISTRY in an
#     ENV directive — or laundered into ENV via `ARG X` + `ENV Y=$X` — is a FAIL
#     for **every** class A/B/C. ENV = runtime pollution, never class-graded.
#   - ARG with a build-time value name (PROXY|INDEX|MIRROR|REGISTRY) is FAIL for
#     class A, WARN for class B/C (§14.3 取值规则): ARG = build-history exposure,
#     which is class-graded precisely because it does NOT enter Config.Env.
#
# Complemented by: check_docker_version.sh (build.sh tag verification)
#                  check_reproducibility.sh (SHA256 digest check)
#
# Usage: ./check_dockerfile.sh [--class=A|B|C] [project_root]
#   --class=A (default): passing an intranet address via --build-arg is forbidden
#                        (§14.3 取值规则), so an `ARG` whose name looks like a
#                        build-time source (PROXY|INDEX|MIRROR|REGISTRY) is a FAIL.
#   --class=B / --class=C: an `ARG` naming a build-time source is only a WARN —
#                        its value stays out of Config.Env and is merely recorded
#                        in `docker history`, so class B/C may accept that exposure.
#                        An ENV directive naming a build-time source, and the
#                        `ARG X` + `ENV X=$X` laundering spelling, stay FAILs at
#                        every class: ENV pollutes the runtime and §14.3 does not
#                        relax that by class. --class changes 8c's verdict only.
#   --class=C: a missing Dockerfile is NOT a failure — §0 does not require Docker
#              deployment for class C. When a Dockerfile is present it is checked
#              against §14.3 in full, like any other class.
#   Class A / B: a missing Dockerfile still fails (§14.3 requires Docker deployment).
#
# The name match in 8a / 8b / 8c is a deliberate heuristic: a static scan cannot
# see where a value points, and §14.3's value rules cover proxy hosts and private
# pip/npm mirrors alike. It therefore errs toward over-reporting — a false positive
# costs one look at §14.3's value table, while a false negative would let an
# intranet address into the image unnoticed.

set -euo pipefail

CLASS="A"
PROJECT_ROOT=""
for arg in "${@}"; do
    case "$arg" in
        --class=A|--class=B|--class=C) CLASS="${arg#--class=}" ;;
        -*) echo "Usage: check_dockerfile.sh [--class=A|B|C] [project_root]" >&2; exit 2 ;;
        *) PROJECT_ROOT="$arg" ;;
    esac
done

PROJECT_ROOT="${PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || echo '.')}"
cd "$PROJECT_ROOT"

FAIL=0

echo "Checking Dockerfile..."

# ─── 1. Dockerfile existence ────────────────────────────────────────────

DOCKERFILE=""
if [ -f "$PROJECT_ROOT/Dockerfile" ]; then
    DOCKERFILE="$PROJECT_ROOT/Dockerfile"
elif [ -f "$PROJECT_ROOT/docker/Dockerfile" ]; then
    DOCKERFILE="$PROJECT_ROOT/docker/Dockerfile"
fi

if [ -z "$DOCKERFILE" ]; then
    if [ "$CLASS" = "C" ]; then
        # §0: class C is not required to provide a Docker deployment, so "no
        # Dockerfile" is not a violation for C — it is a silent skip. A class C
        # project that DOES ship a Dockerfile falls through to the checks below
        # and §14.3 applies to it in full.
        echo "  [SKIP] No Dockerfile found — §14.3 does not require Docker deployment for class C."
        exit 0
    fi
    echo "[FAIL] check_dockerfile: No Dockerfile found (Docker deployment required by §14.3)."
    exit 1
fi

echo "  [OK] Dockerfile found: ${DOCKERFILE#$PROJECT_ROOT/}"

# ─── 2. No :latest tag ─────────────────────────────────────────────────

LATEST_FROM=$(grep -nE '^FROM\s+\S+:latest\b' "$DOCKERFILE" 2>/dev/null | grep -v '^\s*#' || true)
if [ -n "$LATEST_FROM" ]; then
    echo "[FAIL] check_dockerfile: Base image uses :latest tag (pin to specific version per §14.3):"
    echo "$LATEST_FROM" | while IFS= read -r line; do echo "  $line"; done
    FAIL=1
else
    echo "  [OK] Base image uses specific version tag (not :latest)"
fi

# ─── 3. Two-layer build check ──────────────────────────────────────────

# §14.3 requires a **two-layer** build — a dependency layer (uv.lock +
# pyproject.toml) and a source layer — so the dependency layer stays cached. It
# does NOT ask for a multi-stage build: the §14.3 template is single-FROM.
#
# The old heuristic only looked for `FROM … AS builder` / `COPY --from=`,
# so a compliant single-FROM file was reported as "No multi-stage build",
# contradicting check_reproducibility.sh on the very same Dockerfile.
#
# Accepted forms (warning only, never a hard gate):
#   1. the §14.3 two-layer shape — uv.lock/pyproject.toml COPYed before the
#      source COPY; or
#   2. a multi-stage build, which reaches the same caching goal.
if grep -qE '^[[:space:]]*COPY[[:space:]].*(uv\.lock|pyproject\.toml)' "$DOCKERFILE" 2>/dev/null && \
   grep -qE '^[[:space:]]*COPY[[:space:]].*(src/|src[[:space:]]|[[:space:]]\.[[:space:]]*$)' "$DOCKERFILE" 2>/dev/null; then
    echo "  [OK] Two-layer build: dependency layer (uv.lock + pyproject.toml) precedes the source layer (§14.3)"
elif grep -qE 'COPY --from=' "$DOCKERFILE" 2>/dev/null || \
     grep -qE 'FROM.*AS[[:space:]]+(builder|deps|build|base)' "$DOCKERFILE" 2>/dev/null; then
    echo "  [OK] Multi-stage build detected (dependency caching satisfied, §14.3)"
else
    echo "  [WARN] No two-layer (dependency layer + source layer) build detected — the dependency layer may not stay cached."
    echo "         Follow the §14.3 template: COPY uv.lock pyproject.toml … and install first, then COPY the source."
fi

# ─── 4. uv usage for dependency installation ────────────────────────────

if grep -qE '(uv sync|uv pip install)' "$DOCKERFILE" 2>/dev/null; then
    echo "  [OK] Uses uv for dependency installation"
else
    echo "  [WARN] uv sync / uv pip install not found in Dockerfile."
    echo "         Dependencies should be installed via uv for version consistency (§14.2, §14.3)."
fi

# ─── 5. pip install -r requirements.txt in Dockerfile ──────────────────

if grep -qE 'pip install.*-r.*requirements' "$DOCKERFILE" 2>/dev/null; then
    echo "[FAIL] check_dockerfile: Dockerfile uses pip install -r requirements.txt"
    echo "         Use uv sync or uv pip install with uv.lock instead (§14.2)."
    FAIL=1
fi

# Fold backslash continuations so that one logical instruction becomes one line,
# prefixed with the number of the line it starts on (`<lineno>:<text>`, the shape
# `grep -n` produces). Docker treats `ENV A=1 \` + a continuation line as ONE
# instruction that writes BOTH assignments into Config.Env, so a gate reading
# physical lines sees only the first name and misses the rest. Do not remove this
# folding: `ENV A=1 HTTP_PROXY=…` and its continuation spelling are both legal
# Docker and must both be caught (8a); an ARG declaration may be continued for
# the same reason (8b / 8c), and §14.3's cache-mount template continues a `RUN`
# across lines (gate 6).
#
# Comment lines are dropped before this folding, matching the Dockerfile parser:
# comments do not support line continuations (`# note \` is a complete comment —
# it does NOT swallow the next instruction, verified against `docker build` +
# `Config.Env`), and a comment appearing *inside* a continuation is stripped
# while the continuation still carries on (`ENV FOO=1 \` + `# c` + `BAR=2`
# writes both FOO and BAR). Dropping them here therefore both closes the
# `# comment \` blind spot and keeps a commented continuation intact.
fold_continuations() {
    awk '
        {
            line = $0
            sub(/\r$/, "", line)
            if (line ~ /^[[:space:]]*#/) next
            if (buf == "") start = NR
            if (line ~ /\\[[:space:]]*$/) {
                sub(/\\[[:space:]]*$/, "", line)
                buf = buf line " "
                next
            }
            printf "%d:%s\n", start, buf line
            buf = ""
        }
        END { if (buf != "") printf "%d:%s\n", start, buf }
    ' "$1"
}

# ─── 6. BuildKit cache mount for uv ─────────────────────────────────────

# §14.3 requires the cache mount on the `uv sync` / `uv pip install` command
# itself, and its own template writes the mount flag as a continuation line:
# `RUN --mount=type=cache,target=/root/.cache/uv \` + `uv sync …`. The signal is
# therefore the *pair* on one LOGICAL line, i.e. after folding continuations:
#   * keying on `RUN --mount=type=cache.*uv` alone missed the recommended
#     template, because `RUN` and `uv` sit on different physical lines;
#   * keying on `--mount=type=cache` anywhere is too loose — an apt-only mount
#     (`--mount=type=cache,target=/var/cache/apt`) on a line of its own would be
#     credited to a `uv sync` line that has no mount (false negative).
# Both halves must share the folded line, in either order. Warning only.
# The match is collected into a variable instead of ending the pipeline with
# `grep -q`: under `set -o pipefail`, a `grep -q` that exits on the first hit can
# SIGPIPE the upstream grep and turn a real hit into a non-zero pipeline status.
CACHE_MOUNT_UV=$(fold_continuations "$DOCKERFILE" \
    | grep -E -- '--mount=type=cache' \
    | grep -E '(^|[^[:alnum:]_-])uv[[:space:]]+(sync|pip[[:space:]]+install)([^[:alnum:]_-]|$)' \
    || true)
if [ -n "$CACHE_MOUNT_UV" ]; then
    echo "  [OK] BuildKit cache mount for uv (prevents re-download on rebuild)"
else
    echo "  [WARN] No BuildKit cache mount for uv found."
    echo "         Add: RUN --mount=type=cache,target=/root/.cache/uv uv sync ..."
    echo "         This prevents re-downloading all packages when a layer is rebuilt (§14.3)."
fi

# ─── 7. build.sh exists ────────────────────────────────────────────────

if [ -f "$PROJECT_ROOT/build.sh" ]; then
    echo "  [OK] build.sh exists"
elif [ -f "$PROJECT_ROOT/docker/build.sh" ]; then
    echo "  [OK] docker/build.sh exists"
else
    echo "  [WARN] No build.sh found — recommend encapsulating build command (§14.3)."
fi

# ─── 8. Build-time sources must not pollute the runtime — §14.3 ───────────
#
# The binary distinction, in one line — do not conflate the two halves:
#   ENV = 环境污染: the value enters Config.Env and the runtime container inherits
#         it → FAIL for **every** class A/B/C; §14.3 forbids it unconditionally.
#   ARG = 构建历史暴露: the value stays out of Config.Env and merely lands in
#         `docker history` → class-graded (FAIL for A, WARN for B/C), gate 8c.
#
# §14.3's 代理不得污染运行时 reads "不因项目类别放宽": grading by class is valid
# ONLY for the ARG spelling. Never copy 8c's grading into 8a / 8b — ENV cannot be
# relaxed for B/C, because the polluted Config.Env is inherited at runtime no
# matter how private the project is.
#
# Two spellings reach the image's configuration metadata (`docker inspect`
# `Config.Env`) and are therefore both unconditional FAILs:
#   1. a build-time source variable in an ENV directive (8a) — uppercase or
#      lowercase, both land in Config.Env, so the match is case-insensitive;
#   2. `ARG X` followed by `ENV Y=$X` (or `${X}` / the shell default-value
#      spellings `${X:-…}` and `${X-…}`) (8b) — the laundering spelling that
#      smuggles a build-arg into ENV and therefore into Config.Env. The ENV name
#      need not equal the ARG name (`ARG HTTP_PROXY` + `ENV MY_PROXY=$HTTP_PROXY`
#      launder the same value).
# Both spellings use the same *name* group (PROXY|INDEX|MIRROR|REGISTRY): §14.3's
# value table covers private pip/npm mirror sources (`UV_DEFAULT_INDEX`,
# `PIP_INDEX_URL`, `*_MIRROR`, `*_REGISTRY`) in the same breath as proxy hosts, and
# a mirror address in Config.Env breaks the runtime exactly like a stale proxy.
# The group is deliberately *not* applied to every build parameter: §14.3 keeps the
# template `ARG VERSION` + `ENV SETUPTOOLS_SCM_PRETEND_VERSION=${VERSION}` legal,
# because a version number is not a secret and passing it through ENV is not banned.
#
# The match is a heuristic (see the header note): it reads names, not values.

SOURCE_NAMES='PROXY|INDEX|MIRROR|REGISTRY'

DOCKERFILE_LOGICAL=$(fold_continuations "$DOCKERFILE")
# 8a / 8b read ENV through this view; 8b / 8c read ARG through it. Both filters
# are anchored on the directive keyword, so folded `RUN … --mount=…` lines stay
# out of the way.
ENV_LOGICAL=$(printf '%s\n' "$DOCKERFILE_LOGICAL" | grep -iE '^[0-9]+:[[:space:]]*ENV[[:space:]]' || true)
ARG_LOGICAL=$(printf '%s\n' "$DOCKERFILE_LOGICAL" | grep -iE '^[0-9]+:[[:space:]]*ARG[[:space:]]' || true)

# 8a. Every assignment declared by an ENV instruction is tested against the name
# group — not just the first. The name is matched over its *whole* length (the
# group may appear anywhere inside it: `UV_INDEX_URL`, `NPM_REGISTRY`,
# `HTTP_PROXY`), and both the `NAME=value` form and the legacy whitespace form
# (`ENV HTTP_PROXY http://…`, whose key carries no `=`) contribute a candidate.
# Anchoring the group at the end of the name would miss `UV_INDEX_URL=…`, which
# is precisely the spelling this check exists for.
SOURCE_ENV=""
if [ -n "$ENV_LOGICAL" ]; then
    while IFS= read -r logical_line; do
        [ -n "$logical_line" ] || continue
        env_text="${logical_line#*:}"
        if [[ "$env_text" =~ ^[[:space:]]*[Ee][Nn][Vv][[:space:]]+(.*)$ ]]; then
            env_args="${BASH_REMATCH[1]}"
        else
            continue
        fi
        read -ra env_words <<< "$env_args" || true
        for word in "${env_words[@]}"; do
            name="${word%%=*}"
            # A word with no `=` is either the legacy-form key or part of a
            # value; only identifier-shaped words can be a variable name.
            printf '%s' "$name" | grep -qE '^[A-Za-z_][A-Za-z0-9_]*$' || continue
            if printf '%s' "$name" | grep -qiE "(${SOURCE_NAMES})"; then
                SOURCE_ENV="${SOURCE_ENV}${logical_line}"$'\n'
                break
            fi
        done
    done <<< "$ENV_LOGICAL"
    SOURCE_ENV="${SOURCE_ENV%$'\n'}"
fi
if [ -n "$SOURCE_ENV" ]; then
    # Unconditional FAIL, every class: §14.3 forbids ENV pollution of the runtime
    # without any class relaxation. Only 8c's ARG route is graded by class.
    echo "[FAIL] check_dockerfile: Build-time source variable (${SOURCE_NAMES}) set in ENV directive (class $CLASS)."
    echo "         ENV values enter Config.Env, are inherited by the runtime container,"
    echo "         and break the runtime wherever the proxy/mirror is unreachable."
    echo "         This is runtime pollution — §14.3 代理不得污染运行时 forbids it for"
    echo "         every class A/B/C and is not relaxed by project class; class grading"
    echo "         in this script applies to the ARG spelling (8c) only."
    echo "         Pass the value as a build-time value instead: a BuildKit secret mount"
    echo "         for any credential or class A intranet address, or --build-arg for a"
    echo "         non-credential intranet address in class B/C (that route stays out"
    echo "         of Config.Env)."
    echo "         Name-based heuristic: if the value is a public address or a non-secret"
    echo "         build parameter, re-check §14.3's value table before treating this as final."
    echo "$SOURCE_ENV" | while IFS= read -r line; do echo "  $line"; done
    FAIL=1
else
    echo "  [OK] No build-time source ENV directives found"
fi

# 8b. `ARG X` → `ENV Y=$X` laundering of a build-time source/credential value —
# the equivalent spelling of (1). Two conditions must BOTH hold:
#   a. the ENV value reads a declared build argument back (`$X` / `${X}`), and
#   b. either the ARG name or the ENV name is source/proxy/credential-class.
# (b) keeps the constitution's own template legal: `ARG VERSION` +
# `ENV SETUPTOOLS_SCM_PRETEND_VERSION=${VERSION}` passes, because §14.3 bans
# passing *proxy / mirror* variables (and their equivalent spellings) into `ENV`,
# not the passing of non-secret build parameters.
# `SOURCE_NAMES` is defined once, up in 8a: both gates must use the same name
# group, otherwise `ENV UV_INDEX_URL=…` and its laundering spelling drift apart.
SENSITIVE_NAMES="${SOURCE_NAMES}|TOKEN|SECRET|PASSWORD|PASSWD|PWD|KEY"

# Declared build arguments, taken from the continuation-folded view and split per
# assignment: `ARG A=1 ` + continuation `B=2` declares both A and B. The same
# pass collects the ARG lines whose name hits the source group (gate 8c).
ARG_NAMES=""
ARG_SOURCE=""
if [ -n "$ARG_LOGICAL" ]; then
    while IFS= read -r logical_line; do
        [ -n "$logical_line" ] || continue
        arg_text="${logical_line#*:}"
        if [[ "$arg_text" =~ ^[[:space:]]*[Aa][Rr][Gg][[:space:]]+([^[:space:]]+) ]]; then
            arg_name="${BASH_REMATCH[1]%%=*}"
        else
            continue
        fi
        printf '%s' "$arg_name" | grep -qE '^[A-Za-z_][A-Za-z0-9_]*$' || continue
        ARG_NAMES="${ARG_NAMES}${arg_name}"$'\n'
        if printf '%s' "$arg_name" | grep -qiE "(${SOURCE_NAMES})"; then
            ARG_SOURCE="${ARG_SOURCE}${logical_line}"$'\n'
        fi
    done <<< "$ARG_LOGICAL"
    ARG_NAMES=$(printf '%s' "$ARG_NAMES" | sed '/^$/d' | awk '!seen[$0]++')
    ARG_SOURCE="${ARG_SOURCE%$'\n'}"
fi

ARG_ENV_LAUNDER=""
if [ -n "$ARG_NAMES" ]; then
    while IFS= read -r name; do
        [ -n "$name" ] || continue
        # (a) Pull the ENV line(s) whose declared value reads this build
        # argument back (`$X` / `${X}`) — the ENV variable's own name is
        # deliberately not constrained here, so a renamed ENV is caught too.
        # The folded view is used so that an assignment carried on a
        # continuation line is tested like any other.
        # The `$` and `{}` are matched via bracket expressions: `\$` needs a
        # different number of backslashes inside a double-quoted ERE depending
        # on the caller, which is exactly the kind of quoting trap this check
        # must not fall into.
        # ${NAME}, and the shell default-value spellings ${NAME:-…} and
        # ${NAME-…}, all expand to the build argument's value and all end up in
        # Config.Env. In the brace spelling the closing delimiter (`}`, `:` or
        # `-`) terminates the name unambiguously, so the trailing boundary is
        # required only for the bare `$NAME` form — that is what keeps a longer
        # name (`${HTTP_PROXY_EXTRA}`, `$HTTP_PROXY_EXTRA`) from matching.
        env_lines=$(printf '%s\n' "$ENV_LOGICAL" | \
            grep -E "([$][{]${name}[}:-]|[$]${name}([^A-Za-z0-9_]|$))" || true)
        [ -n "$env_lines" ] || continue
        # (b) Either side matching the sensitive pattern is enough.
        if printf '%s' "$name" | grep -qiE "$SENSITIVE_NAMES"; then
            ARG_ENV_LAUNDER="${ARG_ENV_LAUNDER}${env_lines}"$'\n'
            continue
        fi
        # Collect every assignment name declared on the matched ENV line(s) and
        # test those against the same pattern (`ENV A=1 MY_TOKEN=$X` included).
        env_names=$(printf '%s\n' "$env_lines" | \
            grep -oE '[A-Za-z_][A-Za-z0-9_]*[[:space:]]*=' || true)
        if printf '%s\n' "$env_names" | grep -qiE "(${SENSITIVE_NAMES})[[:space:]]*="; then
            ARG_ENV_LAUNDER="${ARG_ENV_LAUNDER}${env_lines}"$'\n'
        fi
    done <<< "$ARG_NAMES"
    ARG_ENV_LAUNDER=$(printf '%s' "$ARG_ENV_LAUNDER" | sed '/^$/d' | awk '!seen[$0]++')
fi
if [ -n "$ARG_ENV_LAUNDER" ]; then
    echo "[FAIL] check_dockerfile: Build-time source/credential argument laundered into ENV"
    echo "         (e.g. \`ARG HTTP_PROXY\` + \`ENV MY_PROXY=\$HTTP_PROXY\`)."
    echo "         This is the ENV spelling in disguise: the value ends up in Config.Env"
    echo "         and the runtime container inherits it (§14.3 代理不得污染运行时)."
    echo "$ARG_ENV_LAUNDER" | while IFS= read -r line; do echo "  $line"; done
    FAIL=1
else
    echo "  [OK] No source/credential build argument is laundered into ENV"
fi

# 8c. An `ARG` whose name identifies a build-time source (PROXY|INDEX|MIRROR|
# REGISTRY) — the --build-arg route. Allowed for class B/C (the value lands in
# `docker history`), forbidden for class A / any public repository. §14.3's value
# table covers private pip/npm mirrors (`UV_DEFAULT_INDEX`, `PIP_INDEX_URL`,
# `*_MIRROR`, `*_REGISTRY`) alongside proxies, so the same gate applies to them.
# `ARG_SOURCE` was collected above from the folded ARG view.
if [ -n "$ARG_SOURCE" ]; then
    if [ "$CLASS" = "A" ]; then
        echo "[FAIL] check_dockerfile: \`ARG *(${SOURCE_NAMES})*\` declares the --build-arg route (§14.3 取值规则)."
        echo "         Class A / public repositories must pass an intranet proxy or"
        echo "         mirror as a BuildKit secret (--mount=type=secret,...);"
        echo "         --build-arg would write the intranet address into docker history."
        echo "         Name-based heuristic: if the value is in fact a public address,"
        echo "         re-check §14.3's value table before treating this as final."
        echo "$ARG_SOURCE" | while IFS= read -r line; do echo "  $line"; done
        FAIL=1
    else
        echo "[WARN] check_dockerfile: \`ARG *(${SOURCE_NAMES})*\` uses the --build-arg route (allowed for class $CLASS)."
        echo "         The value does not enter Config.Env, but it IS recorded in"
        echo "         \`docker history --no-trunc\`; treat the image push scope as the"
        echo "         secret boundary and never switch this to ENV (§14.3)."
        echo "         Name-based heuristic: a public address may be a false positive."
        echo "$ARG_SOURCE" | while IFS= read -r line; do echo "  $line"; done
    fi
else
    echo "  [OK] No ARG with a build-time source name (${SOURCE_NAMES}) found"
fi

# 8d. Advisory only: a proxy written to a persistent config file inside a RUN.
# A reliable gate is impossible with a regex (the constitution allows the file to
# exist so long as it is created AND removed within the same RUN), so this never
# sets FAIL. It requires a proxy variable name and a persistent config path on
# the same line, which keeps it quiet on the many unrelated Dockerfile lines
# that merely mention an etc-style directory.
PROXY_PERSIST=$(grep -inE '(HTTP_PROXY|HTTPS_PROXY|FTP_PROXY|ALL_PROXY|http_proxy|https_proxy|ftp_proxy|all_proxy)' "$DOCKERFILE" 2>/dev/null | \
    grep -E '/etc/environment|/etc/profile|/etc/profile\.d/|\.bashrc|\.profile|/etc/apt/apt\.conf\.d/|/etc/pip\.conf|\.pip/pip\.conf|\.npmrc|/etc/npmrc|\.wgetrc|/etc/curlrc|/etc/gitconfig|\.gitconfig|\.docker/config\.json|uv/uv\.toml' || true)
if [ -n "$PROXY_PERSIST" ]; then
    echo "[WARN] check_dockerfile: Proxy value written to a persistent config file — confirm it is removed in the same RUN."
    echo "         Per §14.3 the file may only exist inside the RUN that creates it;"
    echo "         a cross-layer residue pollutes the runtime."
    echo "$PROXY_PERSIST" | while IFS= read -r line; do echo "  $line"; done
fi

echo ""
if [ $FAIL -eq 0 ]; then
    echo "[PASS] check_dockerfile: Dockerfile follows constitution."
else
    echo "[FAIL] check_dockerfile: Issues found."
fi
exit $FAIL
