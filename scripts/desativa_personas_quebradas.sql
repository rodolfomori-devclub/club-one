\pset pager off
\echo '=== BACKUP (estado antes) ==='
SELECT id, base_model_id, is_active FROM model
WHERE id IN ('izzy','landing-creator','mestre','modelo-business','protocolo-de-culpa','uxui-developerlatest');

BEGIN;

-- Só personas (base_model_id NOT NULL). A cláusula extra é trava de segurança:
-- em linha com base_model_id NULL, is_active=false removeria o modelo base do
-- seletor para todos (models.py:168).
UPDATE model
SET is_active = false, updated_at = extract(epoch from now())::bigint
WHERE id IN ('izzy','landing-creator','mestre','modelo-business','protocolo-de-culpa','uxui-developerlatest')
  AND base_model_id IS NOT NULL
  AND is_active = true;

\echo '=== ESTADO DEPOIS ==='
SELECT id, base_model_id, is_active FROM model
WHERE base_model_id IS NOT NULL ORDER BY is_active DESC, id;

COMMIT;
