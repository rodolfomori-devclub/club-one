"""
title: ClubHub Scope Guard
author: DevClub
version: 1.0.0
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
# são propositalmente frouxos.
_VERBO = (
    r'(cri[ae]r?|cria|fa[cçz][ae]?r?|fasa|desenvolv[ae]r?|mont[ae]r?|ger[ae]r?|'
    r'refa[cç]|recri[ae]|build|create|recreate|preciso (de|criar|fazer|montar|iniciar)|'
    r'quero (um|uma|criar|fazer|montar)|gostaria de (criar|fazer|montar)|me (d[êe]|manda|envia))'
)
_ARTEFATO = (
    r'(site|website|web ?site|port[a-z]{0,3}[oó]?li?o|landing ?page|lange ?page|lading ?page|'
    r'sistema|aplicativo|aplica[cç][aã]o|\bapp\b|plataforma|p[aá]gina (institucional|web|de)|'
    r'projeto (completo|do zero|institucional)|dashboard|painel administrativo)'
)

# Sinais de escopo total — hoje servem só como severidade (log/decisão futura),
# não são exigidos para acionar o guard.
_ESCOPO_TOTAL = [
    r'\bcomplet[ao]s?\b',
    r'\binteir[ao]s?\b',
    r'\bdo zero\b',
    r'\bfull ?stack\b',
    r'\btodas as (p[aá]ginas|se[cç][oõ]es|telas)\b',
    r'html.{0,40}css',
]

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
    r'\bmelhor[ae]?(r|ia|ias)?\b',
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
            default='fatiar',
            description="'fatiar' instrui o modelo a entregar por partes; 'bloquear' recusa o pedido.",
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

        # Manutenção/dúvida nunca conta como geração de projeto.
        if any(re.search(p, t) for p in _MANUTENCAO):
            return False

        # Verbo de criação perto de um artefato (até ~60 chars entre eles) já basta:
        # "faz um site de barbearia" é exatamente o comportamento a ser fatiado.
        return bool(re.search(rf'{_VERBO}.{{0,60}}{_ARTEFATO}', t))

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

        # Modo fatiar: anexa a diretriz ao system prompt, preservando o que já existe
        # (o system do model entry é aplicado antes dos filtros, em openai.py).
        if messages and messages[0].get('role') == 'system':
            atual = _texto_da_mensagem(messages[0])
            messages[0]['content'] = f'{atual}{_DIRETRIZ_FATIAR}'
        else:
            messages.insert(0, {'role': 'system', 'content': _DIRETRIZ_FATIAR.strip()})

        body['messages'] = messages
        return body
