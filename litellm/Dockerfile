# LiteLLM proxy do ClubHub para o Railway (builda a partir de litellm/).
FROM ghcr.io/berriai/litellm:main-stable

COPY config.yaml /app/config.yaml

# O Railway injeta $PORT — o litellm precisa escutar nele. Sobrescreve o entrypoint
# pra rodar com shell (expande $PORT).
ENTRYPOINT []
CMD ["sh", "-c", "litellm --config /app/config.yaml --host 0.0.0.0 --port ${PORT:-4000}"]
