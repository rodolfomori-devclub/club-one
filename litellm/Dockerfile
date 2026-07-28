# LiteLLM proxy do ClubHub para o Railway (builda a partir de litellm/).
# Pinado por digest (= litellm 1.91.0, a mesma imagem validada localmente).
# A tag main-stable é móvel e o cache de build do Railway deixava prod numa
# versão antiga que quebrava tools + reasoning_effort nos GPT 5.6.
FROM ghcr.io/berriai/litellm@sha256:078f96272f0c84da383e6a1f197478390b5204a86dcf00a181bcfe02a00e5dfa

COPY config.yaml /app/config.yaml

# O Railway injeta $PORT — o litellm precisa escutar nele. Sobrescreve o entrypoint
# pra rodar com shell (expande $PORT).
ENTRYPOINT []
CMD ["sh", "-c", "litellm --config /app/config.yaml --host 0.0.0.0 --port ${PORT:-4000}"]
