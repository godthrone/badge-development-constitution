#!/usr/bin/env bash
# check_config_system.sh — Verify configuration system conventions
# Part of BADGE Constitution §7.1, §7.2, §7.3
#
# Checks for:
#   - config.toml (base, preferred) or legacy config_example.toml/.yaml exists
#   - Config loaded via pydantic (not manual yaml.load)
#   - No environment variable overrides for config values
#   - Template is well-commented
#
# Usage: ./check_config_system.sh [--class=A|B|C] [project_root]
#   --class=B: relax config-file check (advisory, not mandatory), relax __main__.py check

set -euo pipefail

CLASS="A"
PROJECT_ROOT=""
for arg in "${@}"; do
    case "$arg" in
        --class=A|--class=B|--class=C) CLASS="${arg#--class=}" ;;
        -*) echo "Usage: check_config_system.sh [--class=A|B|C] [project_root]" >&2; exit 2 ;;
        *) PROJECT_ROOT="$arg" ;;
    esac
done

PROJECT_ROOT="${PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || echo '.')}"
cd "$PROJECT_ROOT"

FAIL=0

echo "Checking configuration system..."

# ─── 1. config.toml (base) or legacy config_example.* exists ───────────

# Recursively search for config.toml (base config, preferred), legacy
# config_example.toml/.yaml, or a configs/ directory.
# TOML is preferred (§7.3); legacy .yaml projects remain supported.
# Projects may place configs in subdirectories (e.g. samples/configs/).
CONFIG_EXAMPLE=$(find "$PROJECT_ROOT" \( -name "config.toml" -o -name "config_example.toml" -o -name "config_example.yaml" \) \
    -not -path "*/.local/*" -not -path "*/node_modules/*" \
    -not -path "*/__pycache__/*" -not -path "*/.venv/*" 2>/dev/null | head -1)
CONFIGS_DIR=$(find "$PROJECT_ROOT" -type d -name "configs" \
    -not -path "*/.local/*" -not -path "*/node_modules/*" \
    -not -path "*/__pycache__/*" -not -path "*/.venv/*" 2>/dev/null | head -1)

if [ -n "$CONFIG_EXAMPLE" ] && [ -f "$CONFIG_EXAMPLE" ]; then
    echo "  [OK] Config template found at $CONFIG_EXAMPLE"

    # Check comment density (should be well-commented)
    TOTAL_LINES=$(wc -l < "$CONFIG_EXAMPLE" 2>/dev/null || echo 0)
    COMMENT_LINES=$(grep -c '^\s*#' "$CONFIG_EXAMPLE" 2>/dev/null || echo 0)
    if [ "$TOTAL_LINES" -gt 0 ]; then
        COMMENT_RATIO=$((100 * COMMENT_LINES / TOTAL_LINES))
        if [ "$COMMENT_RATIO" -lt 10 ]; then
            echo "  [WARN] Config template has low comment density ($COMMENT_RATIO%)."
            echo "         Template should be well-commented as documentation (§7.3)."
        else
            echo "  [OK] Config template has good comment coverage ($COMMENT_RATIO%)."
        fi
    fi
elif [ -n "$CONFIGS_DIR" ] && [ -d "$CONFIGS_DIR" ] && [ -n "$(ls -A "$CONFIGS_DIR" 2>/dev/null)" ]; then
    echo "  [OK] configs/ directory with example configs found at $CONFIGS_DIR"
else
    if [ "$CLASS" = "B" ]; then
        echo "  [WARN] No config.toml, legacy config_example.toml/.yaml, or configs/ found (§7.3) — advisory for Class B."
    else
        echo "[FAIL] check_config_system: No config.toml, legacy config_example.toml/.yaml, or configs/ found (§7.3)."
        echo "         Searched recursively; excluded .local/, node_modules/, __pycache__/, .venv/."
        FAIL=1
    fi
fi

# ─── 2. Check for pydantic config loading ───────────────────────────────

if [ -d "$PROJECT_ROOT/src" ]; then
    # Look for pydantic BaseModel with Config or model_config (pydantic v2)
    PYDANTIC_CONFIG=$(grep -rl 'BaseModel' "$PROJECT_ROOT/src/" 2>/dev/null | \
        xargs grep -l 'class.*Config\|model_config' 2>/dev/null | head -5 || true)

    if [ -n "$PYDANTIC_CONFIG" ]; then
        echo "  [OK] Pydantic models with config found (configuration validated at load time §7.2)"
    else
        echo "  [WARN] No pydantic BaseModel with Config/model_config found in src/."
        echo "         Config should be validated at load time using pydantic (§7.2)."
    fi

    # Check for model_validate usage (pydantic v2 validation)
    MODEL_VALIDATE=$(grep -rl 'model_validate\|parse_obj\|parse_raw' "$PROJECT_ROOT/src/" 2>/dev/null | head -3 || true)
    if [ -n "$MODEL_VALIDATE" ]; then
        echo "  [OK] Pydantic model validation used (model_validate / parse_obj)"
    fi
fi

# ─── 3. Environment variable config overrides (§7.1 C:339, C:343) ───────
#
# §7.1: 环境变量不能作为配置的单一真相源，只允许三种用途：
#   ① 标准基础设施变量（CUDA_VISIBLE_DEVICES、NCCL_*、PYTORCH_*、RANK 等）；
#   ② 第三方组件只接受环境变量、无法通过配置适配时（作为适配层）；
#   ③ 极小型项目确实只有一个配置时。
# 用户自行用 `.env` 承载本地机密不在此限，但项目不得把它当作配置真相源
# （§15.2 C:898-906）。检测三种写法：os.environ[...] / os.environ.get(...) / os.getenv(...)。

if [ -d "$PROJECT_ROOT/src" ]; then
    ENV_ALL=$(grep -rnE '(os\.environ\[|os\.environ\.get\(|os\.getenv\()' "$PROJECT_ROOT/src/" 2>/dev/null | \
        grep -v '__pycache__' | head -50 || true)

    # ① 标准基础设施变量（§7.1 C:343 列举 + 同类 CUDA/NCCL/torchrun 变量）
    INFRA_VARS='CUDA_VISIBLE_DEVICES|NCCL_|PYTORCH_|TORCH_|RANK|LOCAL_RANK|WORLD_SIZE|LOCAL_WORLD_SIZE|NODE_RANK|NPROC_PER_NODE|MASTER_ADDR|MASTER_PORT|OMP_|MKL_|GLOO_|NVIDIA_|CUDA_'
    # §15.2 用户本地机密（.env）：密钥 / 口令 / token 类变量名
    SECRET_VARS='(_KEY|_TOKEN|_SECRET|_PASSWORD|_PASSWD|_CREDENTIAL|_API_KEY)'
    # ② 第三方组件只接受环境变量的适配层（常见样例，非穷举）
    THIRDPARTY_VARS='(HTTP_PROXY|HTTPS_PROXY|NO_PROXY|http_proxy|https_proxy|no_proxy|HF_HOME|HF_TOKEN|HUGGINGFACE_|WANDB_|OPENAI_|ANTHROPIC_|AWS_|AZURE_|GOOGLE_|PIP_INDEX_URL|PIP_EXTRA_INDEX_URL|UV_|DOTENV_)'

    ENV_INFRA=$(printf '%s\n' "$ENV_ALL" | grep -E "$INFRA_VARS" | grep -v '^$' || true)
    ENV_SECRET=$(printf '%s\n' "$ENV_ALL" | grep -vE "$INFRA_VARS" | grep -E "$SECRET_VARS" | grep -v '^$' || true)
    ENV_THIRDPARTY=$(printf '%s\n' "$ENV_ALL" | grep -vE "$INFRA_VARS" | grep -vE "$SECRET_VARS" | \
        grep -E "$THIRDPARTY_VARS" | grep -v '^$' || true)
    ENV_CONFIG=$(printf '%s\n' "$ENV_ALL" | grep -vE "$INFRA_VARS" | grep -vE "$SECRET_VARS" | \
        grep -vE "$THIRDPARTY_VARS" | grep -v '^$' || true)

    if [ -n "$ENV_INFRA" ]; then
        echo "  [OK] Only standard infrastructure env vars used (exception ①, §7.1)"
    fi
    if [ -n "$ENV_SECRET" ]; then
        echo "  [INFO] Secret-like env vars read — allowed when carried by user-local .env (§15.2):"
        printf '%s\n' "$ENV_SECRET" | while IFS= read -r line; do [ -n "$line" ] && echo "    $line"; done
    fi
    if [ -n "$ENV_THIRDPARTY" ]; then
        echo "  [WARN] Third-party env vars read (exception ②, §7.1 — verify it is an adapter layer):"
        printf '%s\n' "$ENV_THIRDPARTY" | while IFS= read -r line; do [ -n "$line" ] && echo "    $line"; done
    fi

    if [ -n "$ENV_CONFIG" ]; then
        if [ -z "$CONFIG_EXAMPLE" ] && [ -z "$CONFIGS_DIR" ]; then
            # ③ 极小型项目确实只有一个配置（§7.1 C:343）
            echo "  [WARN] Environment variables used for config, and no config.toml/configs/ found —"
            echo "         possibly exception ③ (tiny single-config project, §7.1). Verify manually."
            printf '%s\n' "$ENV_CONFIG" | while IFS= read -r line; do [ -n "$line" ] && echo "    $line"; done
        else
            echo "[FAIL] check_config_system: Environment variables used for config (not infrastructure, §7.1):"
            printf '%s\n' "$ENV_CONFIG" | while IFS= read -r line; do [ -n "$line" ] && echo "  $line"; done
            echo "         Config must come from the git-tracked config.toml, not environment variables (§7.1 C:339)."
            echo "         Allowed exceptions: ① infra vars, ② third-party-only env components, ③ tiny single-config project;"
            echo "         .env is for user-local secrets only (§15.2). Env-borne config must be read centrally"
            echo "         at startup and normalized into the same load path — never scattered at use sites."
            FAIL=1
        fi
    else
        echo "  [OK] No config-level environment variable usage detected"
    fi
fi

# ─── 4. Check for CLI flags overriding config (heuristic) ──────────────

if [ -f "$PROJECT_ROOT/src"/*/cli.py ] 2>/dev/null || [ -f "$PROJECT_ROOT/src"/*/__main__.py ] 2>/dev/null; then
    CLI_FILES=$(find "$PROJECT_ROOT/src" -name 'cli.py' -o -name '__main__.py' 2>/dev/null | head -5 || true)
    if [ -n "$CLI_FILES" ]; then
        # Check for argparse flags that look like they override config
        CLI_OVERRIDES=$(grep -nE "add_argument\('--(?!gpu|master_port|help)" $CLI_FILES 2>/dev/null | \
            grep -v 'config' | head -5 || true)
        if [ -n "$CLI_OVERRIDES" ]; then
            if [ "$CLASS" = "B" ]; then
                echo "  [INFO] CLI has non-infrastructure arguments (relaxed for Class B):"
                echo "$CLI_OVERRIDES" | while IFS= read -r line; do
                    echo "  $line"
                done
            else
                echo "  [WARN] CLI has non-infrastructure arguments that may override config:"
                echo "$CLI_OVERRIDES" | while IFS= read -r line; do
                    echo "  $line"
                done
                echo "         CLI should accept only --config + parameters that meet the three principles (§10.1):"
                        echo "         input-locating, runtime-environment, or run-boundary. Review each manually."
            fi
        fi
    fi
fi

echo ""
if [ $FAIL -eq 0 ]; then
    echo "[PASS] check_config_system: Configuration system follows constitution."
else
    echo "[FAIL] check_config_system: Issues found."
fi
exit $FAIL
