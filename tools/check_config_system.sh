#!/usr/bin/env bash
# check_config_system.sh — Verify configuration system conventions
# Part of BADGE Constitution §7.1, §7.2, §7.3
#
# Checks for:
#   - config_example.yaml exists
#   - Config loaded via pydantic (not manual yaml.load)
#   - No environment variable overrides for config values
#   - Template is well-commented
#
# Usage: ./check_config_system.sh [project_root]

set -euo pipefail

PROJECT_ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || echo '.')}"
cd "$PROJECT_ROOT"

FAIL=0

echo "Checking configuration system..."

# ─── 1. config_example.yaml exists ──────────────────────────────────────

CONFIG_EXAMPLE="$PROJECT_ROOT/config_example.yaml"
CONFIGS_DIR="$PROJECT_ROOT/configs"

if [ -f "$CONFIG_EXAMPLE" ]; then
    echo "  [OK] config_example.yaml exists"

    # Check comment density (should be well-commented)
    TOTAL_LINES=$(wc -l < "$CONFIG_EXAMPLE" 2>/dev/null || echo 0)
    COMMENT_LINES=$(grep -c '^\s*#' "$CONFIG_EXAMPLE" 2>/dev/null || echo 0)
    if [ "$TOTAL_LINES" -gt 0 ]; then
        COMMENT_RATIO=$((100 * COMMENT_LINES / TOTAL_LINES))
        if [ "$COMMENT_RATIO" -lt 10 ]; then
            echo "  [WARN] config_example.yaml has low comment density ($COMMENT_RATIO%)."
            echo "         Template should be well-commented as documentation (§7.3)."
        else
            echo "  [OK] config_example.yaml has good comment coverage ($COMMENT_RATIO%)."
        fi
    fi
elif [ -d "$CONFIGS_DIR" ] && [ -n "$(ls -A "$CONFIGS_DIR" 2>/dev/null)" ]; then
    echo "  [OK] configs/ directory with example configs exists"
else
    echo "[FAIL] check_config_system: No config_example.yaml or configs/ found (§7.3)."
    FAIL=1
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

# ─── 3. No environment variable config overrides ────────────────────────

if [ -d "$PROJECT_ROOT/src" ]; then
    # Check for os.environ.get / os.getenv used for config values (not infrastructure vars)
    ENV_CONFIG=$(grep -rnE '(os\.environ|os\.getenv)\[' "$PROJECT_ROOT/src/" 2>/dev/null | \
        grep -vE 'CUDA_VISIBLE_DEVICES|NCCL_|PYTORCH_|RANK|LOCAL_RANK|WORLD_SIZE|MASTER_ADDR|MASTER_PORT|OMP_' | \
        grep -v 'badge-development-constitution/' | grep -v '__pycache__' | head -10 || true)

    if [ -n "$ENV_CONFIG" ]; then
        echo "[FAIL] check_config_system: Environment variables used for config (not infrastructure):"
        echo "$ENV_CONFIG" | while IFS= read -r line; do
            echo "  $line"
        done
        echo "         Config should come from YAML file, not environment variables (§7.1)."
        FAIL=1
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
            echo "  [WARN] CLI has non-infrastructure arguments that may override config:"
            echo "$CLI_OVERRIDES" | while IFS= read -r line; do
                echo "  $line"
            done
            echo "         CLI should accept only --config + infrastructure params (§10.1)."
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
