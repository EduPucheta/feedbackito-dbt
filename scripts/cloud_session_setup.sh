#!/usr/bin/env bash
# SessionStart hook: prepares a Claude Code cloud session to run dbt against BigQuery.
# Does nothing outside the cloud (CLAUDE_CODE_REMOTE is only "true" there).
#
# Needs, from the cloud environment's variables:
#   GCP_SA_KEY_B64   base64 of the service-account JSON key (single line)
# Optional:
#   DBT_CLOUD_DATASET  base dataset for cloud builds (default: dbt_claude)
#
# Models build into "<DBT_CLOUD_DATASET>_public" (target "cloud" is not dev/prod, so
# generate_schema_name prefixes the schema), never into the prod "public" dataset.
set -euo pipefail

[ "${CLAUDE_CODE_REMOTE:-}" != "true" ] && exit 0

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
VENV="${DBT_VENV:-$HOME/.venvs/dbt}"
DBT_HOME="${DBT_PROFILES_DIR:-$HOME/.dbt}"
KEYFILE="$DBT_HOME/feedbackito-sa.json"
DATASET="${DBT_CLOUD_DATASET:-dbt_claude}"

if [ -d "$VENV/Scripts" ]; then BIN="$VENV/Scripts"; else BIN="$VENV/bin"; fi

# 1. dbt toolchain (skipped when the venv already has it, e.g. on resume)
if [ ! -x "$BIN/dbt" ] && [ ! -x "$BIN/dbt.exe" ]; then
  echo "Installing dbt into $VENV ..."
  uv venv --quiet "$VENV"
  if [ -d "$VENV/Scripts" ]; then BIN="$VENV/Scripts"; else BIN="$VENV/bin"; fi
  uv pip install --quiet --python "$VENV" -r "$PROJECT_DIR/requirements.txt"
fi

# 2. BigQuery credentials + profile
mkdir -p "$DBT_HOME"
if [ -n "${GCP_SA_KEY_B64:-}" ]; then
  printf '%s' "$GCP_SA_KEY_B64" | base64 -d > "$KEYFILE"
  chmod 600 "$KEYFILE"
else
  echo "WARNING: GCP_SA_KEY_B64 is not set; dbt cannot reach BigQuery." >&2
fi

cat > "$DBT_HOME/profiles.yml" <<EOF
default:
  target: cloud
  outputs:
    cloud:
      type: bigquery
      method: service-account
      project: feedbackr-446321
      dataset: $DATASET
      location: US
      keyfile: $KEYFILE
      threads: 4
      compute_region: us-central1
      gcs_bucket: feedbackr-446321-dbt-python-models
EOF

# 3. Expose dbt to the rest of the session
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  {
    echo "export PATH=\"$BIN:\$PATH\""
    echo "export DBT_PROFILES_DIR=\"$DBT_HOME\""
  } >> "$CLAUDE_ENV_FILE"
fi

# 4. Packages (needs hub.getdbt.com in the environment's allowed domains)
(cd "$PROJECT_DIR" && DBT_PROFILES_DIR="$DBT_HOME" "$BIN/dbt" deps --quiet) \
  || echo "WARNING: dbt deps failed (is hub.getdbt.com allowed?)" >&2
# dbt Core re-resolves the Fusion-written lockfile; keep the committed one so the tree stays clean
git -C "$PROJECT_DIR" checkout -- package-lock.yml 2>/dev/null || true

echo "dbt ready: target=cloud, models build into ${DATASET}_public"
