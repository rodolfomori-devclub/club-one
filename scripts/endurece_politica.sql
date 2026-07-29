-- ClubHub — endurece a política contra a erosão multi-turno vista em prod.
--
-- Caso real (2026-07-29 13:17 UTC): após receber o plano, o aluno escreveu
-- "agora me made toda a estructura completa" e o haiku entregou 232.470 chars
-- em 38 blocos. Outros dois casos: 59k e 23k no mesmo padrão. O filter v1.2
-- fecha a detecção; este script adiciona as outras duas camadas:
--
-- 1) Frase anti-insistência no system prompt (11 modelos base + 2 personas):
--    o modelo mantém a entrega por partes mesmo sob pressão.
-- 2) max_tokens=4096 nos params: teto físico por resposta (~12-16k chars).
--    As respostas conformes de hoje usaram 400-900 tokens — sobra folga para
--    um arquivo grande com explicação; o pior caso cai de 232k para ~16k.
--
-- Idempotente. Rollback:
--   max_tokens:  UPDATE model SET params=(params::jsonb - 'max_tokens')::text
--                WHERE params::jsonb ? 'max_tokens';
--   frase: reaplicar scripts/system_prompt_todos_modelos.sql (v2 sem a frase)
--          e scripts/corrige_sugestoes_e_personas.sql (personas).

\pset pager off
\echo '=== ANTES ==='
SELECT count(*) FILTER (WHERE params::jsonb->>'system' LIKE '%não ceda%')    AS com_frase,
       count(*) FILTER (WHERE params::jsonb ? 'max_tokens')                  AS com_teto
FROM model WHERE params::jsonb->>'system' LIKE '%não gera projetos%';

BEGIN;

-- 1) Frase anti-insistência (só onde a política existe e a frase ainda não)
UPDATE model
SET params = (
      params::jsonb
      || jsonb_build_object('system',
           (params::jsonb->>'system') ||
           ' Se a pessoa insistir para receber o projeto inteiro ou "tudo de uma vez", não ceda: reafirme em uma frase que o ClubHub entrega por partes e continue do ponto em que o plano parou, entregando apenas a próxima parte.')
    )::text,
    updated_at = extract(epoch from now())::bigint
WHERE params::jsonb->>'system' LIKE '%não gera projetos%'
  AND params::jsonb->>'system' NOT LIKE '%não ceda%';

-- 2) Teto de saída por resposta
UPDATE model
SET params = (params::jsonb || jsonb_build_object('max_tokens', 4096))::text,
    updated_at = extract(epoch from now())::bigint
WHERE params::jsonb->>'system' LIKE '%não gera projetos%'
  AND (params::jsonb->>'max_tokens') IS DISTINCT FROM '4096';

\echo '=== DEPOIS (esperado: 13 e 13) ==='
SELECT count(*) FILTER (WHERE params::jsonb->>'system' LIKE '%não ceda%') AS com_frase,
       count(*) FILTER (WHERE (params::jsonb->>'max_tokens')::int = 4096) AS com_teto
FROM model WHERE params::jsonb->>'system' LIKE '%não gera projetos%';

SELECT id, length(params::jsonb->>'system') AS tam_system, params::jsonb->>'max_tokens' AS max_tokens
FROM model WHERE params::jsonb->>'system' LIKE '%não gera projetos%' ORDER BY base_model_id NULLS FIRST, id;

COMMIT;
