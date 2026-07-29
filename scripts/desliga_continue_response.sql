-- ClubHub — desliga o botão "Continuar resposta" para alunos (4ª camada).
--
-- Por que em DOIS lugares: get_permissions combina permissões de grupo com o
-- default usando o valor MAIS PERMISSIVO (access_control/__init__.py:52,
-- True > False). O grupo 'alunos' (631 membros) tem chat.continue_response=true
-- explícito — mudar só o default user.permissions não teria efeito nenhum.
--
-- Motivação: com max_tokens=4096 no ar, o botão Continuar é o único caminho
-- restante para acumular um dump grande em parcelas (caso real de 232k chars
-- em 2026-07-29 provavelmente cresceu por aí). Admins não são afetados: o
-- frontend libera por role (ResponseMessage.svelte:1283).
--
-- Nota: a env var USER_PERMISSIONS_CHAT_CONTINUE_RESPONSE só define o DEFAULT
-- de código quando não há linha no banco — aqui há, então o banco é o caminho.
--
-- Rollback:
--   UPDATE config SET value = jsonb_set(value::jsonb, '{chat,continue_response}', 'true')::json WHERE key='user.permissions';
--   UPDATE "group" SET permissions = jsonb_set(permissions::jsonb, '{chat,continue_response}', 'true')::json WHERE name='alunos';

\pset pager off
\echo '=== ANTES ==='
SELECT 'config' AS onde, value::jsonb->'chat'->>'continue_response' AS continue_resp
FROM config WHERE key='user.permissions'
UNION ALL
SELECT 'grupo ' || name, permissions::jsonb->'chat'->>'continue_response'
FROM "group" WHERE permissions::jsonb ? 'chat';

BEGIN;

UPDATE config
SET value = jsonb_set(value::jsonb, '{chat,continue_response}', 'false')::json,
    updated_at = extract(epoch from now())::bigint
WHERE key = 'user.permissions'
  AND value::jsonb->'chat'->>'continue_response' IS DISTINCT FROM 'false';

-- Todos os grupos que declaram chat (hoje só 'alunos'), para não depender do nome.
UPDATE "group"
SET permissions = jsonb_set(permissions::jsonb, '{chat,continue_response}', 'false')::json,
    updated_at = extract(epoch from now())::bigint
WHERE permissions::jsonb ? 'chat'
  AND permissions::jsonb->'chat'->>'continue_response' IS DISTINCT FROM 'false';

\echo '=== DEPOIS (esperado: tudo false) ==='
SELECT 'config' AS onde, value::jsonb->'chat'->>'continue_response' AS continue_resp
FROM config WHERE key='user.permissions'
UNION ALL
SELECT 'grupo ' || name, permissions::jsonb->'chat'->>'continue_response'
FROM "group" WHERE permissions::jsonb ? 'chat';

COMMIT;
