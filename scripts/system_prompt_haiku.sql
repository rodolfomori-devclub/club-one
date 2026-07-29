-- ClubHub — define o system prompt do claude-haiku-4-5 (item 1.1).
--
-- Efeito: params.system na entrada do modelo base sobrescreve o payload do
-- cliente (routers/openai.py:1141-1148) e substitui o system prompt do aluno
-- (misc.py:518, add_or_update_system_message com append=False). Ou seja, não
-- tem como anular pelas configurações do chat.
--
-- Validado em produção via A/B no litellm com o prompt real do desafio DevClub:
--   sem system prompt  -> 8.000 tokens de saída, finish_reason=length (truncado)
--   com system prompt  -> 3.777 tokens, finish_reason=stop, 1 arquivo,
--                         encerrando com "Próximo passo... Quer que eu continue?"
--
-- Rollback:
--   UPDATE model SET params = (params::jsonb - 'system')::text
--   WHERE id = 'claude-haiku-4-5';

\pset pager off
\echo '=== ANTES ==='
SELECT id, coalesce(params, '(null)') AS params FROM model WHERE id = 'claude-haiku-4-5';

BEGIN;

-- Merge: preserva qualquer outra chave que exista em params.
-- base_model_id IS NULL garante que é a entrada do modelo base, não uma persona.
UPDATE model
SET params = (
      coalesce(params::jsonb, '{}'::jsonb)
      || jsonb_build_object('system', $SYS$Você é o ClubHub, o assistente de IA da DevClub. Seu papel é ajudar no dia a dia de quem está aprendendo a programar: tirar dúvidas, explicar erros, revisar código, ensinar conceitos e apoiar a carreira.

Você não é uma ferramenta de gerar projetos prontos. Quando pedirem um site, sistema ou aplicação inteira, não despeje tudo de uma vez: diga em uma frase por qual parte vai começar, entregue só ela funcionando com a explicação das decisões, e ofereça a próxima ao final. Nunca mais de um arquivo completo por resposta.

Para dúvidas, erros e revisões, responda direto e no ponto: corrija o que foi perguntado, sem reescrever o código inteiro.

Responda sempre em português do Brasil.$SYS$)
    )::text,
    updated_at = extract(epoch from now())::bigint
WHERE id = 'claude-haiku-4-5'
  AND base_model_id IS NULL;

\echo '=== DEPOIS ==='
SELECT id,
       (params::jsonb->>'system' IS NOT NULL) AS tem_system,
       length(params::jsonb->>'system')       AS tam_system
FROM model WHERE id = 'claude-haiku-4-5';

COMMIT;
