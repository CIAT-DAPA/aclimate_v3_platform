#!/bin/bash
# ============================================================
# AClimate v3 — Ensure Keycloak admin exists in users table
# ============================================================
# Extracts the admin user's UUID dynamically from the realm JSON
# mounted at /realm.json (source of truth), and inserts the user
# into the admin panel `users` table so the permissions bootstrap
# (05-admin-permissions.sh) can grant full access.
#
# This is idempotent and robust: if the realm JSON admin UUID is
# changed, this script adapts automatically (no need to edit it).
# ============================================================
set -e

REALM_FILE="/realm.json"

if [ ! -f "$REALM_FILE" ]; then
  echo "[ensure-admin] ERROR: $REALM_FILE not found. Mount aclimate-realm.json into the db_aclimate container."
  exit 1
fi

# Extract the id of the user with username "admin" from the realm JSON.
# The "id" field appears just before "username": "admin".
ADMIN_UUID=$(grep -B2 '"username": *"admin"' "$REALM_FILE" | grep -o '"id"[^,]*' | sed 's/.*"\(.*\)"/\1/' | tr -d ' ')

if [ -z "$ADMIN_UUID" ]; then
  echo "[ensure-admin] ERROR: Could not extract admin UUID from $REALM_FILE"
  exit 1
fi

echo "[ensure-admin] Admin UUID from realm: $ADMIN_UUID"

# Insert admin if not exists (matched by keycloak_ext_id)
psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 --quiet \
  -c "INSERT INTO users (keycloak_ext_id, role_id, enable, register, updated)
      SELECT '${ADMIN_UUID}', r.id, true, now(), now()
      FROM role r
      WHERE r.name IN ('admin', 'adminsuper')
        AND NOT EXISTS (SELECT 1 FROM users WHERE keycloak_ext_id = '${ADMIN_UUID}')
      ORDER BY r.name='admin' DESC, r.id ASC
      LIMIT 1;"

echo "[ensure-admin] Admin user ensured."