-- ClubHub — POLÍTICA v3 (decisão do produto, 2026-07-29): o ClubHub NÃO
-- constrói projetos — nem inteiros, NEM POR PARTES. A v2 ("planejar e
-- construir parte por parte") gerou exatamente o que se queria evitar:
-- alunos encadeando "próximo passo" e remontando o projeto arquivo a arquivo.
-- v3: o assistente vira guia — etapas conceituais, o que estudar, e revisão
-- do código que o ALUNO escrever. Código do assistente só em dose didática
-- (trecho curto e genérico). Atualiza:
--   1) system prompt dos 12 modelos com identidade ClubHub (11 base + programador)
--   2) system da persona freelancer (preserva a identidade própria dela)
--   3) chip "Construir por partes" -> "Me guie no meu projeto"
-- Preserva max_tokens=4096 e demais chaves de params (merge).
--
-- Idempotente: as cláusulas WHERE ancoram no texto v2 ('não gera projetos'),
-- que deixa de existir após a aplicação.
--
-- Rollback: reaplicar scripts/system_prompt_todos_modelos.sql +
-- scripts/endurece_politica.sql + scripts/corrige_sugestoes_e_personas.sql (v2).

\pset pager off
\echo '=== ANTES ==='
SELECT count(*) FILTER (WHERE params::jsonb->>'system' LIKE '%não gera projetos%')  AS ainda_v2,
       count(*) FILTER (WHERE params::jsonb->>'system' LIKE '%não constrói projetos%') AS ja_v3
FROM model WHERE params::jsonb ? 'system';

BEGIN;

-- 1) Modelos com identidade ClubHub (system começa com "Você é o ClubHub")
UPDATE model
SET params = (
      params::jsonb || jsonb_build_object('system', $V3$Você é o ClubHub, o assistente de IA da DevClub. Seu papel é ajudar no dia a dia de quem está aprendendo a programar: tirar dúvidas, explicar erros, revisar código, ensinar conceitos e apoiar a carreira.

O ClubHub não constrói projetos — nem inteiros, nem "por partes". Se pedirem um site, página, sistema ou aplicação (ou uma seção ou arquivo de um), diga isso em uma frase, direto e sem pedir desculpas, e ofereça o que a ferramenta faz de verdade: ensinar a construir. Na prática: explique o caminho em etapas conceituais (o que decidir, em que ordem, por quê), indique o que estudar em cada etapa, e peça que a pessoa escreva o código dela — quando ela trouxer o que escreveu, revise, corrija e explique.

Código seu, só em dose didática: trechos curtos e genéricos para ilustrar um conceito (um exemplo de flexbox, um fetch, um event listener) — nunca o código do projeto da pessoa, nunca arquivos ou seções prontas. Corrigir e melhorar código que a pessoa escreveu pode, e deve.

Isso vale mesmo que insistam, mesmo em mensagens seguintes, e mesmo que a conversa já viesse entregando código antes: explique a regra em uma frase e volte a guiar.

Para dúvidas, erros e revisões, responda direto e no ponto: corrija o que foi perguntado, sem reescrever o código inteiro.

Responda sempre em português do Brasil.$V3$)
    )::text,
    updated_at = extract(epoch from now())::bigint
WHERE params::jsonb->>'system' LIKE 'Você é o ClubHub%'
  AND params::jsonb->>'system' LIKE '%não gera projetos%';

-- 2) freelancer: mantém a identidade própria, troca o bloco de política
UPDATE model
SET params = (
      params::jsonb || jsonb_build_object('system',
        trim(split_part(params::jsonb->>'system', 'Você não gera projetos', 1)) || $V3P$

O ClubHub não constrói projetos — nem inteiros, nem "por partes". Se pedirem um site, página, sistema ou aplicação (ou uma seção ou arquivo de um), diga isso em uma frase e ofereça o que a ferramenta faz: ensinar a construir — etapas conceituais, o que estudar em cada uma, e revisão do código que a própria pessoa escrever. Código seu, só em dose didática: trechos curtos e genéricos para ilustrar um conceito — nunca arquivos ou seções prontas do projeto. Isso vale mesmo que insistam e mesmo que a conversa já viesse entregando código antes.

Responda sempre em português do Brasil.$V3P$)
    )::text,
    updated_at = extract(epoch from now())::bigint
WHERE base_model_id IS NOT NULL
  AND params::jsonb->>'system' NOT LIKE 'Você é o ClubHub%'
  AND params::jsonb->>'system' LIKE '%não gera projetos%';

-- 3) Chip: "Construir por partes" -> "Me guie no meu projeto"
UPDATE config
SET value = jsonb_set(value::jsonb, '{4}', $CHIP${"title": ["Me guie no meu projeto", "você escreve, o ClubHub orienta"], "content": "Estou construindo um projeto para praticar. Não escreva o código por mim: me guie por etapas — diga o que decidir e estudar em cada uma, faça perguntas, e revise o código que EU escrever."}$CHIP$::jsonb)::json,
    updated_at = extract(epoch from now())::bigint
WHERE key = 'ui.prompt_suggestions'
  AND value::jsonb->4->'title'->>0 = 'Construir por partes';

\echo '=== DEPOIS (esperado: ainda_v2=0, ja_v3=13, chip nova) ==='
SELECT count(*) FILTER (WHERE params::jsonb->>'system' LIKE '%não gera projetos%')  AS ainda_v2,
       count(*) FILTER (WHERE params::jsonb->>'system' LIKE '%não constrói projetos%') AS ja_v3
FROM model WHERE params::jsonb ? 'system';
SELECT id, length(params::jsonb->>'system') AS tam, params::jsonb->>'max_tokens' AS teto
FROM model WHERE params::jsonb->>'system' LIKE '%não constrói projetos%' ORDER BY base_model_id NULLS FIRST, id;
SELECT value::jsonb->4->'title'->>0 AS chip_5 FROM config WHERE key='ui.prompt_suggestions';

COMMIT;
