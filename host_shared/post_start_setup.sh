#!/usr/bin/env bash
set -euo pipefail

# Post-start setup (PyFinder + ShakeMap)
SYSOP_USER="${SYSOP_USER:-sysop}"
USER_HOME="/home/${SYSOP_USER}"
HOST_SHARED="${HOST_SHARED:-${USER_HOME}/host_shared}"

echo "=== Post-start setup (PyFinder + ShakeMap) ==="

# -----------------------------------------------------------------------------
# 1) Install regional ShakeMap profile (if provided by host)
# -----------------------------------------------------------------------------
SRC_TGZ="${HOST_SHARED}/shakemap_config.tgz"
DST_BASE="${USER_HOME}/shakemap_profiles/default/install"
DST_CFG="${DST_BASE}/config"

if [[ -f "$SRC_TGZ" ]]; then
  echo "[shakemap-config] Installing regional config from $SRC_TGZ"
  mkdir -p "$DST_BASE"

  if [[ -d "$DST_CFG" ]]; then
    # Backup existing config once
    if [[ ! -d "${DST_CFG}.bak" ]]; then
      echo "[shakemap-config] Backing up existing config to ${DST_CFG}.bak"
      mv "$DST_CFG" "${DST_CFG}.bak"
    fi
  fi

  tar -xzf "$SRC_TGZ" -C "$DST_BASE"
  chown -R "${SYSOP_USER}:${SYSOP_USER}" "$DST_BASE" || true
  echo "[shakemap-config] Installed to $DST_CFG"
else
  echo "[shakemap-config] Skipped: $SRC_TGZ not found"
fi

# -----------------------------------------------------------------------------
# 2) Optional: copy extra map layers (.wkt) if present on host
# -----------------------------------------------------------------------------
if [[ -d "${USER_HOME}/shakemap_wkt" ]]; then
  mkdir -p "${DST_BASE}/data/layers/"
  cp -f "${USER_HOME}/shakemap_wkt"/*.wkt "${DST_BASE}/data/layers/" 2>/dev/null || true
fi

echo "=== Post-start setup complete ==="
