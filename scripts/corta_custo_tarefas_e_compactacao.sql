-- ClubHub — corta os dois custos invisíveis descobertos em 2026-07-29
-- (dia de $20 até meio-dia; haiku sozinho: 14M tokens de entrada, $17).
--
-- 1) TAREFAS DE BACKGROUND NO HAIKU: task.model.default e task.model.external
--    estão vazios, então título, tags e os 3 follow-ups gerados A CADA resposta
--    rodam no modelo do chat (haiku) com o histórico inteiro — chamadas que nem
--    aparecem no histórico. Aponta ambos para gpt-5-nano (o mais barato).
--
-- 2) COMPACTAÇÃO DE CONTEXTO DESLIGADA: chat.context_compaction.enable=false.
--    Média real de 173.802 tokens de entrada POR RESPOSTA hoje — o histórico
--    reenviado cresce sem teto e já flerta com o limite de 200k do haiku.
--    Liga a compactação global (threshold default 80k: acima disso o fork
--    resume o histórico num checkpoint e segue dali).
--
-- Obs: a 3ª alavanca (prompt caching na rota Anthropic) é no litellm/config.yaml
-- e vai por deploy — testada localmente: 2ª chamada leu 7.289/7.292 tokens do
-- cache (99,9% a 0,1x do preço).
--
-- Rollback:
--   UPDATE config SET value='""'::json    WHERE key IN ('task.model.default','task.model.external');
--   UPDATE config SET value='false'::json WHERE key='chat.context_compaction.enable';

\pset pager off
\echo '=== ANTES ==='
SELECT key, value::text FROM config
WHERE key IN ('task.model.default','task.model.external','chat.context_compaction.enable')
ORDER BY key;

BEGIN;

INSERT INTO config (key, value, updated_at) VALUES
  ('task.model.default',            '"gpt-5-nano"'::json, extract(epoch from now())::bigint),
  ('task.model.external',           '"gpt-5-nano"'::json, extract(epoch from now())::bigint),
  ('chat.context_compaction.enable','true'::json,         extract(epoch from now())::bigint)
ON CONFLICT (key) DO UPDATE
SET value = EXCLUDED.value,
    updated_at = EXCLUDED.updated_at;

\echo '=== DEPOIS (esperado: gpt-5-nano, gpt-5-nano, true) ==='
SELECT key, value::text FROM config
WHERE key IN ('task.model.default','task.model.external','chat.context_compaction.enable')
ORDER BY key;

COMMIT;
