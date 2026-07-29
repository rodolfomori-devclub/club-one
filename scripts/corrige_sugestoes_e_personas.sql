-- ClubHub — corrige dois achados do pente fino de 2026-07-29:
--
-- 1) SUGESTÕES DA TELA INICIAL: a chave ui.prompt_suggestions do banco
--    (persistida em 2026-07-19, herdada do prod antigo) contém as 6 sugestões
--    stock em inglês e SOBREPÕE os defaults pt-BR do fork (config.py) — nem as
--    chips DevClub de 27/07 nem a "Construir por partes" jamais foram servidas.
--    Substitui pelas 7 do fork.
--
-- 2) PERSONAS ATIVAS SEM A POLÍTICA: o system prompt v2 do modelo base NÃO é
--    herdado por personas (openai.py:1130 usa apenas model_info do persona).
--    'programador' não tem system nenhum — testado em prod: nesse estado o
--    gpt-5-nano despeja 20,5k chars de projeto (T4 da auditoria). 'freelancer'
--    tem um system de 81 chars que não fala de escopo. Corrige: programador
--    recebe o v2 (copiado da linha do gpt-5-nano, fonte única); freelancer
--    mantém a identidade e ganha o parágrafo de escopo.
--
-- Rollback:
--   UPDATE config SET value = '<valor antigo>' WHERE key='ui.prompt_suggestions';
--   UPDATE model SET params = (params::jsonb - 'system')::text WHERE id='programador';
--   (freelancer: reponha o system antigo de 81 chars)

\pset pager off
\echo '=== ANTES ==='
SELECT key, jsonb_array_length(value::jsonb) AS qtd FROM config WHERE key='ui.prompt_suggestions';
SELECT id, length(params::jsonb->>'system') AS tam_system FROM model WHERE id IN ('programador','freelancer');

BEGIN;

-- 1) Sugestões pt-BR do fork (config.py DEFAULT_PROMPT_SUGGESTIONS, 7 chips)
UPDATE config SET value = $JS$[
  {"title": ["Me explique esse erro", "cole o erro do seu código"],
   "content": "Vou colar um erro que apareceu no meu código. Me explique o que ele significa e como corrigir, passo a passo."},
  {"title": ["Revise meu código", "melhorias pontuais e boas práticas"],
   "content": "Vou colar um trecho de código. Revise apontando melhorias pontuais de legibilidade, boas práticas e possíveis bugs — sem reescrever tudo."},
  {"title": ["Explique um conceito", "de forma simples, com exemplo"],
   "content": "Me explique um conceito de programação de forma simples, com um exemplo prático curto em JavaScript. Pode perguntar qual conceito eu quero."},
  {"title": ["Me ajude a estudar", "com perguntas e correções"],
   "content": "Quero estudar um tema de programação. Me faça perguntas, uma de cada vez, e corrija minhas respostas explicando o porquê."},
  {"title": ["Construir por partes", "uma seção do seu projeto por vez"],
   "content": "Quero construir uma parte do meu projeto. Comece perguntando qual seção eu quero fazer agora, entregue só ela funcionando e me explique as decisões antes de seguir para a próxima."},
  {"title": ["Simule uma entrevista", "técnica de programação"],
   "content": "Simule uma entrevista técnica para uma vaga de desenvolvedor júnior: faça uma pergunta por vez e me dê feedback das minhas respostas."},
  {"title": ["Monte um plano de estudos", "para a sua meta na programação"],
   "content": "Me ajude a montar um plano de estudos semanal e realista para evoluir na programação. Comece perguntando meu nível atual e minha meta."}
]$JS$::json,
    updated_at = extract(epoch from now())::bigint
WHERE key = 'ui.prompt_suggestions';

-- 2a) programador: recebe o v2 inteiro (copiado da linha do gpt-5-nano)
UPDATE model
SET params = (
      coalesce(nullif(params,''), '{}')::jsonb
      || jsonb_build_object('system',
           (SELECT params::jsonb->>'system' FROM model WHERE id = 'gpt-5-nano'))
    )::text,
    updated_at = extract(epoch from now())::bigint
WHERE id = 'programador' AND base_model_id IS NOT NULL;

-- 2b) freelancer: identidade própria + parágrafo de escopo do v2
UPDATE model
SET params = (
      params::jsonb
      || jsonb_build_object('system',
           (params::jsonb->>'system') || $POL$

Você não gera projetos, sites ou sistemas completos — não é para isso que a ferramenta serve. Quando pedirem algo assim, diga isso em uma frase, direto e sem pedir desculpas, e ofereça o que resolve de verdade: planejar o projeto junto. Entregue um plano para o pedido específico — as seções ou telas necessárias, a estrutura de arquivos, o que precisa ser decidido antes (conteúdo, imagens, cores) e em que ordem construir. Depois que a pessoa escolher por onde começar, aí sim escreva o código daquela parte — uma de cada vez, nunca mais de um arquivo por resposta.

Responda sempre em português do Brasil.$POL$)
    )::text,
    updated_at = extract(epoch from now())::bigint
WHERE id = 'freelancer' AND base_model_id IS NOT NULL
  AND params::jsonb->>'system' NOT LIKE '%não gera projetos%';

\echo '=== DEPOIS ==='
SELECT key, jsonb_array_length(value::jsonb) AS qtd,
       value::jsonb->4->'title'->>0 AS chip_5
FROM config WHERE key='ui.prompt_suggestions';
SELECT id, length(params::jsonb->>'system') AS tam_system,
       (params::jsonb->>'system') LIKE '%não gera projetos%' AS tem_politica
FROM model WHERE id IN ('programador','freelancer');

COMMIT;
