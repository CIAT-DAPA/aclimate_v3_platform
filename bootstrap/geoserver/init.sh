#!/bin/bash
# ============================================================
# AClimate v3 — GeoServer data_dir bootstrap
# ============================================================
# Copies the pre-configured GeoServer data directory from
# /bootstrap-geoserver (bind mount) into the GeoServer data
# volume on first start.
#
# Idempotent: only runs if the data dir is empty (first start).
# If GeoServer already has data (workspaces/ present), it skips.
# ============================================================
set -e

TARGET_DATA_DIR="${GEOSERVER_DATA_DIR:-/opt/geoserver/data_dir}"
BOOTSTRAP_DIR="/bootstrap-geoserver/data_dir"

if [ -d "${TARGET_DATA_DIR}/workspaces" ]; then
  echo "[geoserver-init] data_dir already initialized — skipping."
  exit 0
fi

if [ ! -d "${BOOTSTRAP_DIR}" ]; then
  echo "[geoserver-init] No bootstrap data found at ${BOOTSTRAP_DIR} — starting empty."
  exit 0
fi

echo "[geoserver-init] Copying bootstrap data to ${TARGET_DATA_DIR}..."
cp -a "${BOOTSTRAP_DIR}/." "${TARGET_DATA_DIR}/"
chown -R geoserver:geoserver 2>/dev/null || chown -R 1000:1000 "${TARGET_DATA_DIR}"
echo "[geoserver-init] Bootstrap data copied."