#!/bin/bash
# ============================================================
# AClimate v3 — Create frontend users database
# ============================================================
# Creates the `aclimate_frontend_users_db` database used by the
# Users API (aclimate_v3_frontend_users_webapi) and the Admin
# panel (DATABASE_URL_FRONT).
#
# Runs automatically on first DB init (empty volume).
# Idempotent: does nothing if the database already exists.
# ============================================================
set -e

DB_NAME="aclimate_frontend_users_db"

if psql -U "$POSTGRES_USER" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='${DB_NAME}'" | grep -q 1; then
  echo "[users-db] Database ${DB_NAME} already exists — skipping."
else
  echo "[users-db] Creating database ${DB_NAME}..."
  psql -U "$POSTGRES_USER" -d postgres -c "CREATE DATABASE ${DB_NAME}"
  echo "[users-db] Created successfully."
fi