-- ClubHub — system prompt de escopo v2: NAO gera projeto pronto, oferece planejamento.
--
-- v1 mandava "entregue em partes"; v2 muda a politica para "nao entrego o projeto,
-- planejo com voce e depois construimos parte por parte". Alinhado com o modo
-- 'planejar' da Filter Function (owui-functions/clubhub_scope_guard.py).
--
-- Substitui scripts/system_prompt_haiku.sql (que cobria só o haiku). Idempotente:
-- cria a linha em `model` para quem não tem e faz merge em params para quem já
-- tem, preservando as outras chaves.
--
-- Por que em todos: params.system só vale para o modelo escolhido. O gpt-5-nano
-- é hoje o mais usado (57 respostas em 24h contra 42 do haiku); cobrir só o
-- haiku deixaria a maior parte do tráfego sem a política.
--
-- NÃO toca: personas (base_model_id NOT NULL) — elas têm system prompt próprio,
-- que vence em apply_system_prompt_to_body.
--
-- Rollback:
--   UPDATE model SET params = (params::jsonb - 'system')::text
--   WHERE base_model_id IS NULL AND params::jsonb ? 'system';

\pset pager off
\echo '=== ANTES ==='
SELECT id, (params::jsonb ? 'system') AS tem_system
FROM model WHERE base_model_id IS NULL AND params::jsonb ? 'system';

BEGIN;

WITH prompt AS (
  SELECT $SYS$Você é o ClubHub, o assistente de IA da DevClub. Seu papel é ajudar no dia a dia de quem está aprendendo a programar: tirar dúvidas, explicar erros, revisar código, ensinar conceitos e apoiar a carreira.

Você não gera projetos, sites ou sistemas completos — não é para isso que a ferramenta serve. Quando pedirem algo assim, diga isso em uma frase, direto e sem pedir desculpas, e ofereça o que resolve de verdade: planejar o projeto junto. Entregue um plano para o pedido específico — as seções ou telas necessárias, a estrutura de arquivos, o que precisa ser decidido antes (conteúdo, imagens, cores) e em que ordem construir. Depois que a pessoa escolher por onde começar, aí sim escreva o código daquela parte — uma de cada vez, nunca mais de um arquivo por resposta.

Para dúvidas, erros e revisões, responda direto e no ponto: corrija o que foi perguntado, sem reescrever o código inteiro.

Responda sempre em português do Brasil.$SYS$::text AS txt
),
admin AS (
  SELECT id FROM "user" WHERE role = 'admin' ORDER BY created_at LIMIT 1
),
alvos(model_id) AS (
  VALUES ('gpt-5-nano'), ('gpt-5.4-nano'), ('gpt-5-mini'), ('gpt-4o-mini'),
         ('gpt-4.1-mini'), ('gpt-5.6-luna'), ('claude-haiku-4-5'),
         ('gemini-3.5-flash-lite'), ('gemini-3.1-flash-lite'),
         ('sonar-pro'), ('grok-4-latest')
)
INSERT INTO model (id, user_id, base_model_id, name, meta, params, created_at, updated_at, is_active)
SELECT a.model_id,
       (SELECT id FROM admin),
       NULL,
       a.model_id,
       '{"profile_image_url": "/static/favicon.png", "description": null, "capabilities": {"vision": true, "file_upload": true, "web_search": true, "image_generation": true, "code_interpreter": true, "citations": true, "status_updates": true, "usage": true}, "suggestion_prompts": null, "tags": []}',
       jsonb_build_object('system', (SELECT txt FROM prompt))::text,
       extract(epoch from now())::bigint,
       extract(epoch from now())::bigint,
       true
FROM alvos a
ON CONFLICT (id) DO UPDATE
SET params = (
      coalesce(model.params::jsonb, '{}'::jsonb)
      || jsonb_build_object('system', EXCLUDED.params::jsonb->>'system')
    )::text,
    updated_at = extract(epoch from now())::bigint;

\echo '=== DEPOIS ==='
SELECT id,
       (params::jsonb ? 'system') AS tem_system,
       length(params::jsonb->>'system') AS tam,
       is_active
FROM model
WHERE id IN ('gpt-5-nano','gpt-5.4-nano','gpt-5-mini','gpt-4o-mini','gpt-4.1-mini',
             'gpt-5.6-luna','claude-haiku-4-5','gemini-3.5-flash-lite',
             'gemini-3.1-flash-lite','sonar-pro','grok-4-latest')
ORDER BY id;

COMMIT;
