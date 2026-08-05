#!/bin/bash
# ============================================================
# Restore AClimate database dump on first start
# Runs only when the db_aclimate volume is empty.
# Finds the first *.dump file in /dumps automatically.
# ------------------------------------------------------------
# How to provide your dump:
#   Copy your .dump file into bootstrap/db/dumps/ on the host.
#   Any name works, e.g. aclimate_pg_20260804.dump
# ============================================================
set -e

DUMP_FILE=$(ls /dumps/*.dump 2>/dev/null | head -1)

if [ -n "$DUMP_FILE" ] && [ -f "$DUMP_FILE" ]; then
  echo "[restore] Found dump: $DUMP_FILE"
  echo "[restore] Restoring into database: $POSTGRES_DB"
  # pg_restore creates the schema/data on top of the database
  # created by POSTGRES_DB. Use --no-owner to avoid ownership issues.
  pg_restore --no-owner --no-privileges -U "$POSTGRES_USER" -d "$POSTGRES_DB" "$DUMP_FILE"
  echo "[restore] Restore completed successfully."
else
  echo "[restore] No dump file found — skipping restore."
fi