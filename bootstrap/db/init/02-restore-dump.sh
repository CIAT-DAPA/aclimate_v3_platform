#!/bin/bash
# ============================================================
# Restore AClimate database dump on first start
# Runs only when the db_aclimate volume is empty.
# The dump must be placed at: bootstrap/db/dumps/aclimate_pg_20260804.dump
# ============================================================
set -e

DUMP_FILE="/dumps/aclimate_pg_20260804.dump"

if [ -f "$DUMP_FILE" ]; then
  echo "[restore] Found dump: $DUMP_FILE"
  echo "[restore] Restoring into database: $POSTGRES_DB"
  # pg_restore creates the schema/data on top of the database
  # created by POSTGRES_DB. Use --no-owner to avoid ownership issues.
  pg_restore --no-owner --no-privileges -U "$POSTGRES_USER" -d "$POSTGRES_DB" "$DUMP_FILE"
  echo "[restore] Restore completed successfully."
else
  echo "[restore] No dump file found — skipping restore."
fi