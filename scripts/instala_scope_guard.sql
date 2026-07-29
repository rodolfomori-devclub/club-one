-- ClubHub — instala a Filter Function de escopo (item 3.1).
--
-- Gerado a partir de owui-functions/clubhub_scope_guard.py. Para atualizar,
-- edite o .py e regenere; nao edite o SQL a mao.
--
-- Modo padrao: 'fatiar' (anexa diretriz ao system prompt). Para recusar em vez
-- de fatiar, troque a valve pelo Admin ou:
--   UPDATE function SET valves = '{"mode":"bloquear"}' WHERE id='clubhub_scope_guard';
--
-- O modulo foi validado dentro do container real do OWUI (pydantic 2.13.4):
-- import OK, diretriz anexada preservando o prompt base, duvida legitima
-- intacta, admin isento, modo bloquear levanta excecao, content multimodal ok.
--
-- Rollback:
--   UPDATE function SET is_active=false, is_global=false WHERE id='clubhub_scope_guard';
--   -- ou remover de vez:
--   DELETE FROM function WHERE id='clubhub_scope_guard';

\pset pager off
\echo '=== ANTES ==='
SELECT count(*) AS filtros_instalados FROM function;

BEGIN;

INSERT INTO function (id, user_id, name, type, content, meta, created_at, updated_at, valves, is_active, is_global)
SELECT 'clubhub_scope_guard',
       (SELECT id FROM "user" WHERE role='admin' ORDER BY created_at LIMIT 1),
       'ClubHub Scope Guard',
       'filter',
       $PYFN$"""
title: ClubHub Scope Guard
author: DevClub
version: 1.2.0
description: >
  Mantém o ClubHub como assistente de estudo do dia a dia, não como gerador de
  aplicações completas. Detecta pedidos de "projeto inteiro" e, por padrão,
  instrui o modelo a entregar em partes (modo fatiar). Pode bloquear com uma
  mensagem educativa (modo bloquear) — trocável pela valve, sem editar código.

Instalação: Admin → Functions → New Function → colar → salvar → ativar como
Global. Roda no inlet, antes da chamada ao modelo. Admins não são afetados.
"""

import re
from typing import Optional

from pydantic import BaseModel, Field

# Verbo de criação + artefato = pedido de projeto. Grafias erradas são a regra
# nos dados de produção ("portaolio", "lange page", "fasa"), então os padrões
# são propositalmente frouxos. desenvolv(?!dor): não confundir com o substantivo
# "desenvolvedor" ("sou desenvolvedor e...").
_VERBO = (
    r'(cri[ae]r?|cria|fa[cçz][ae]?r?|\bfas\b|fasa|fizer|desenvolv[ae](?!dor)r?|mont[ae]r?|ger[ae]r?|'
    r'refa[cç]|recri[ae]|clon[ae]r?|estrutur(ar|e)\b|build|create|recreate|'
    r'preciso (de|criar|fazer|montar|iniciar)|'
    r'quero (um|uma|criar|fazer|montar|clonar|que voc[êe] (crie|fa[cç]a|gere|monte))|'
    r'gostaria de (criar|fazer|montar)|me (d[êeáa]r?|manda|envia)|(envi[ae]|mand[ae]) pra mim)'
)
_ARTEFATO = (
    r'(site|website|web ?site|port[a-z]{0,3}[oó]?li?o|landing ?page|lange ?page|lading ?page|'
    r'sistema|aplicativo|aplica[cç][aã]o|\bapp\b|plataforma|p[aá]gina (institucional|web|de)|'
    r'projeto (completo|do zero|institucional|todo|inteiro)|dashboard|painel administrativo|'
    r'loja( virtual| online)?|e-?commerce|\bapi\b|\bbot\b|\bjogo\b|\bgame\b|\bblog\b|\bcrud\b|'
    r'card[aá]pio|simulador|\bstore\b|\bsystem\b|\bo html d[aeo]\b)'
)

# Sinais INEQUÍVOCOS de "tudo de uma vez". Quando presentes junto do pedido de
# criação, vencem a precedência de _MANUTENCAO — senão "como criar um site
# completo?" passaria como dúvida. Só entradas sem duplo sentido: "full stack" e
# "html+css" flipavam pedidos legítimos de manutenção na amostra real.
_ESCOPO_OVERRIDE = [
    r'\bcomplet[ao]s?\b',
    r'\binteir[ao]s?\b',
    r'\bdo zero\b',
    r'\btodas as (p[aá]ginas|se[cç][oõ]es|telas)\b',
    r'\btudo (completo|pronto|de uma vez|junto)\b',
]

# INSISTÊNCIA pós-plano ("agora me manda tudo de uma vez"). Caso real de prod
# (2026-07-29 13:17): "agora me made toda a estructura completa" rendeu 232k
# chars. São sinais absolutos — disparam sozinhos, sem exigir verbo+artefato.
_INSISTENCIA_TOTAL = [
    r'\btudo de uma vez\b',
    r'\bsem dividir( em partes)?\b',
    r'\bmanda tudo\b',
    r'\bme d[aáêe] tudo\b',
    r'\btudo (completo|pronto|junto)\b',
]

# "estrutura completa", "projeto todo", "site inteiro" — substantivo+totalidade
# conta como pedido mesmo sem verbo de criação (típico de follow-up).
_TOTALIDADE = (
    r'\b(projeto|site|sistema|c[oó]digo|estruc?tura|p[aá]gina|aplica[cç][aã]o|app|landing ?page)s? '
    r'(tod[ao]s?|inteir[ao]s?|complet[ao]s?)\b'
)

# Criação POSSESSIVA ("criar meu site", "clonar esse site pra mim") é geração,
# não manutenção — vence os padrões de artefato-existente de _MANUTENCAO.
_CRIACAO_POSSESSIVA = re.compile(
    r'\b(cri[ae]r?\w*|fa[cçz][ae]?r?\w*|desenvolv(?!edor)\w+|mont[ae]r?\w*|clon[ae]r?\w*|refazer)\s+'
    r'(o\s|um\s|uma\s)?(meu|minha|nosso|nossa)\s+'
    r'(site|p[oó]?rt[a-z]{0,3}[oó]?li?o|p[aá]gina|projeto|loja|blog|app\b|aplicativo)'
)

# Conserto, dúvida e estudo — nunca contam como geração de projeto, mesmo que a
# frase mencione "site". Precede tudo.
_MANUTENCAO = [
    r'\berro\b',
    r'\bbug\b',
    r'n[aã]o (funciona|est[aá] funcionando|aparece|carrega|vai|pega)',
    r'\bcorrig[ie]',
    r'\bconserta',
    r'\bpor ?qu[eê]\b',
    r'\bo que (significa|quer dizer|[eé])\b',
    r'\bexplica',
    r'\brevis[ae]',
    r'\bcomo (fa[cç]o|faz|criar|posso|funciona|usar|colocar|deixar)\b',
    r'^\s*como\b',
    r'\bme ensina',
    r'\bqual (a|o|é)\b',
    r'\bd[êe] ?(me)? ?(dicas|ideias|sugest)',
    # Pedir recomendação ou requisitos é consultoria/planejamento, não dump de
    # código — ambos apareceram como falso positivo no tráfego real de 29/07.
    r'\brecomend',
    r'\brequisitos?\b',
    # Só as formas VERBAIS de melhorar: o padrão antigo casava o adjetivo nu
    # "melhor" e desativava o guard em frases como "quem melhor fizer a página".
    r'\bmelhor(e|a|em|ar|ando|ia|ias)\b',
    r'\banalis[ae]',
    # Artefato que já existe → é modificação, não geração de projeto novo.
    r'\batualiza[cçõ]?[aã]?o?\b',
    r'\balter[ae]r?\b',
    r'\b(ess[ea]|est[ea]|meu|minha|nosso|nossa) (site|projeto|p[aá]gina|c[oó]digo|portf[a-z]{0,3}[oó]?li?o)\b',
    r'\bque (eu )?(criei|fiz|desenvolvi)\b',
    r'\bj[aá] (tenho|criei|fiz|existe)\b',
    r'\btenho (esse|este|um|uma) (site|projeto|p[aá]gina)\b',
]

_DIRETRIZ_FATIAR = (
    '\n\n[Orientação do ClubHub — o pedido acima parece ser de um projeto inteiro. '
    'Não entregue tudo de uma vez. Comece confirmando em uma frase por qual parte '
    'vai começar (estrutura, uma seção, o CSS, uma funcionalidade), entregue só '
    'essa parte funcionando com a explicação das decisões, e ofereça a próxima ao '
    'final. Nunca mais de um arquivo completo por resposta.]'
)

_DIRETRIZ_PLANEJAR = (
    '\n\n[Orientação do ClubHub — o pedido acima é de um projeto, site ou sistema '
    'inteiro, e o ClubHub não gera projetos completos de uma vez. Abra dizendo em '
    'uma frase, direto e sem pedir desculpas, que aqui você não entrega o projeto '
    'pronto, e ofereça planejar junto. Em seguida entregue um plano para este '
    'pedido específico: as seções ou telas necessárias, a estrutura de arquivos, o '
    'que precisa ser decidido antes (conteúdo, imagens, cores, textos) e em que '
    'ordem construir. Termine perguntando por qual parte ele quer começar — a '
    'partir da resposta dele, aí sim escreva o código daquela parte, uma por vez. '
    'Nesta primeira resposta não escreva código do projeto. Escreva como quem '
    'conversa: nada de numerar ou repetir estas instruções, elas são internas e o '
    'aluno não deve vê-las.]'
)


def _texto_da_mensagem(msg: dict) -> str:
    """Extrai texto de content string ou lista de partes (multimodal)."""
    content = msg.get('content')
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        return ' '.join(p.get('text', '') for p in content if isinstance(p, dict) and p.get('type') == 'text')
    return ''


class Filter:
    class Valves(BaseModel):
        enabled: bool = Field(default=True, description='Liga/desliga o guard por completo.')
        mode: str = Field(
            default='planejar',
            description=(
                "'planejar' (padrão): o modelo diz que não gera projeto pronto e entrega um plano; "
                "'fatiar': entrega o projeto por partes, começando pela primeira; "
                "'bloquear': recusa com mensagem fixa, sem chamar o modelo."
            ),
        )
        block_message: str = Field(
            default=(
                'O ClubHub é seu assistente de estudo do dia a dia — tirar dúvidas, '
                'entender erros, revisar código e aprender conceitos. Ele não monta '
                'projetos inteiros de uma vez.\n\n'
                'Peça uma parte por vez e a gente constrói junto: comece pela estrutura '
                'HTML, ou por uma seção específica, ou pelo CSS de um componente. '
                'A cada passo eu explico as decisões — assim o projeto sai e você '
                'aprende a refazer sozinho.'
            ),
            description='Mensagem mostrada ao aluno no modo bloquear.',
        )
        max_prompt_chars: int = Field(
            default=0,
            description='Recusa mensagens acima deste tamanho. 0 desliga a checagem.',
        )
        long_prompt_message: str = Field(
            default=(
                'Essa mensagem é muito longa para o ClubHub. Cole só o trecho de código '
                'ou a parte do enunciado sobre a qual você tem dúvida — a resposta sai '
                'mais precisa assim.'
            ),
            description='Mensagem mostrada quando o prompt passa de max_prompt_chars.',
        )
        exempt_admins: bool = Field(default=True, description='Não aplica o guard a admins.')

    def __init__(self):
        self.valves = self.Valves()

    def _pede_projeto_inteiro(self, texto: str) -> bool:
        t = texto.lower()

        # Insistência absoluta ("tudo de uma vez") dispara sozinha.
        if any(re.search(p, t) for p in _INSISTENCIA_TOTAL):
            return True

        # Verbo de criação perto de um artefato (até ~60 chars entre eles),
        # ou substantivo+totalidade ("toda a estrutura completa") de follow-up.
        pede = bool(re.search(rf'{_VERBO}.{{0,60}}{_ARTEFATO}', t)) or bool(re.search(_TOTALIDADE, t))

        # Escopo total explícito ("completo", "do zero") vence a checagem de
        # manutenção — senão "como criar um site completo?" passaria como dúvida.
        if pede and any(re.search(p, t) for p in _ESCOPO_OVERRIDE):
            return True

        # "criar meu site" é geração, mesmo com possessivo (que normalmente
        # indicaria artefato existente em _MANUTENCAO).
        if _CRIACAO_POSSESSIVA.search(t):
            return True

        # Manutenção/dúvida sem escopo total: não é geração de projeto.
        if any(re.search(p, t) for p in _MANUTENCAO):
            return False

        return pede

    def inlet(self, body: dict, __user__: Optional[dict] = None) -> dict:
        if not self.valves.enabled:
            return body

        if self.valves.exempt_admins and (__user__ or {}).get('role') == 'admin':
            return body

        messages = body.get('messages') or []
        ultima = next((m for m in reversed(messages) if m.get('role') == 'user'), None)
        if not ultima:
            return body

        texto = _texto_da_mensagem(ultima)

        limite = self.valves.max_prompt_chars
        if limite and len(texto) > limite:
            raise Exception(self.valves.long_prompt_message)

        if not self._pede_projeto_inteiro(texto):
            return body

        if self.valves.mode == 'bloquear':
            raise Exception(self.valves.block_message)

        diretriz = _DIRETRIZ_FATIAR if self.valves.mode == 'fatiar' else _DIRETRIZ_PLANEJAR

        # Anexa a diretriz ao system prompt, preservando o que já existe (o system
        # do model entry é aplicado antes dos filtros, em openai.py).
        if messages and messages[0].get('role') == 'system':
            atual = _texto_da_mensagem(messages[0])
            messages[0]['content'] = f'{atual}{diretriz}'
        else:
            messages.insert(0, {'role': 'system', 'content': diretriz.strip()})

        body['messages'] = messages
        return body
$PYFN$,
       $META${"description": "Mantem o ClubHub como assistente de estudo do dia a dia: detecta pedido de projeto inteiro e instrui o modelo a entregar em partes.", "manifest": {}}$META$::text,
       extract(epoch from now())::bigint,
       extract(epoch from now())::bigint,
       '{}',
       true,
       true
ON CONFLICT (id) DO UPDATE
SET content    = EXCLUDED.content,
    name       = EXCLUDED.name,
    meta       = EXCLUDED.meta,
    is_active  = true,
    is_global  = true,
    updated_at = extract(epoch from now())::bigint;

\echo '=== DEPOIS ==='
SELECT id, name, type, is_active, is_global, length(content) AS tam_codigo FROM function;

COMMIT;
