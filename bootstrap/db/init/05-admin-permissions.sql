-- ============================================================
-- AClimate v3 — Bootstrap admin permissions
-- ============================================================
-- Grants FULL permissions (create/read/update/delete) to every
-- user with the admin role, for EVERY country and EVERY module.
--
-- This runs automatically on first DB init (empty volume) and is
-- idempotent: safe to re-run at any time. It ensures the Keycloak
-- admin user can use the admin panel immediately after first OAuth
-- login, without manual configuration.
-- ============================================================

-- Grant full permissions to all active admin users
INSERT INTO user_access (user_id, country_id, role_id, module, "create", "read", "update", "delete")
SELECT
    u.id AS user_id,
    c.id AS country_id,
    u.role_id,
    m.module::modules,
    true AS "create",
    true AS "read",
    true AS "update",
    true AS "delete"
FROM users u
CROSS JOIN mng_country c
CROSS JOIN (
    VALUES ('GEOGRAPHIC'), ('CLIMATE_DATA'), ('CROP_DATA'),
           ('INDICATORS_DATA'), ('STRESS_DATA'), ('PHENOLOGICAL_STAGE'),
           ('USER_MANAGEMENT'), ('CONFIGURATION')
) AS m(module)
WHERE u.enable = true
  AND u.role_id IN (SELECT id FROM role WHERE name IN ('admin', 'adminsuper'))
ON CONFLICT (user_id, country_id, role_id, module) DO NOTHING;
