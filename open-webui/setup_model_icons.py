#!/usr/bin/env python3
"""
Script para configurar ícones dos modelos no Open WebUI
"""

import sqlite3
import json
import time

DB_PATH = "backend/data/webui.db"

# URLs dos ícones dos provedores (usando logos oficiais públicos)
PROVIDER_ICONS = {
    "openai": "https://cdn.worldvectorlogo.com/logos/openai-2.svg",
    "anthropic": "https://cdn.worldvectorlogo.com/logos/anthropic-1.svg",
    "google": "https://cdn.worldvectorlogo.com/logos/google-icon.svg",
    "xai": "https://upload.wikimedia.org/wikipedia/commons/5/5e/X_logo_2023.svg",
    "deepseek": "https://avatars.githubusercontent.com/u/148330874?s=200&v=4",
    "perplexity": "https://pbs.twimg.com/profile_images/1798110641414443008/XP8gyBaY_400x400.jpg",
}

# Modelos para configurar
MODELS = [
    # OpenAI
    {"id": "openai/gpt-4o", "name": "GPT-4o", "provider": "openai"},
    {"id": "openai/gpt-4o-mini", "name": "GPT-4o Mini", "provider": "openai"},
    {"id": "openai/gpt-4-turbo", "name": "GPT-4 Turbo", "provider": "openai"},
    {"id": "openai/gpt-4", "name": "GPT-4", "provider": "openai"},
    {"id": "openai/gpt-3.5-turbo", "name": "GPT-3.5 Turbo", "provider": "openai"},
    {"id": "openai/o1-preview", "name": "O1 Preview", "provider": "openai"},
    {"id": "openai/o1-mini", "name": "O1 Mini", "provider": "openai"},

    # Anthropic
    {"id": "anthropic/claude-3.5-sonnet", "name": "Claude 3.5 Sonnet", "provider": "anthropic"},
    {"id": "anthropic/claude-3.5-haiku", "name": "Claude 3.5 Haiku", "provider": "anthropic"},
    {"id": "anthropic/claude-3-opus", "name": "Claude 3 Opus", "provider": "anthropic"},
    {"id": "anthropic/claude-3-sonnet", "name": "Claude 3 Sonnet", "provider": "anthropic"},
    {"id": "anthropic/claude-3-haiku", "name": "Claude 3 Haiku", "provider": "anthropic"},

    # Google
    {"id": "google/gemini-1.5-pro", "name": "Gemini 1.5 Pro", "provider": "google"},
    {"id": "google/gemini-1.5-flash", "name": "Gemini 1.5 Flash", "provider": "google"},
    {"id": "google/gemini-1.5-flash-8b", "name": "Gemini 1.5 Flash 8B", "provider": "google"},
    {"id": "google/gemini-2.0-flash-exp", "name": "Gemini 2.0 Flash", "provider": "google"},

    # xAI
    {"id": "xai/grok-beta", "name": "Grok Beta", "provider": "xai"},
    {"id": "xai/grok-2", "name": "Grok 2", "provider": "xai"},
    {"id": "xai/grok-2-vision", "name": "Grok 2 Vision", "provider": "xai"},

    # DeepSeek
    {"id": "deepseek/deepseek-chat", "name": "DeepSeek Chat", "provider": "deepseek"},
    {"id": "deepseek/deepseek-coder", "name": "DeepSeek Coder", "provider": "deepseek"},

    # Perplexity
    {"id": "perplexity/sonar-small", "name": "Perplexity Sonar Small", "provider": "perplexity"},
    {"id": "perplexity/sonar-large", "name": "Perplexity Sonar Large", "provider": "perplexity"},
    {"id": "perplexity/sonar-huge", "name": "Perplexity Sonar Huge", "provider": "perplexity"},
]

def setup_models():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    # Pegar o user_id do admin
    cursor.execute("SELECT id FROM user LIMIT 1")
    result = cursor.fetchone()
    if not result:
        print("Nenhum usuário encontrado. Crie um usuário primeiro no Open WebUI.")
        return

    user_id = result[0]
    current_time = int(time.time())

    for model in MODELS:
        model_id = model["id"]
        model_name = model["name"]
        provider = model["provider"]
        icon_url = PROVIDER_ICONS.get(provider, "")

        meta = json.dumps({
            "profile_image_url": icon_url,
            "description": f"{model_name} via LiteLLM",
            "capabilities": {
                "vision": "vision" in model_id.lower()
            }
        })

        params = json.dumps({})

        # Verificar se o modelo já existe
        cursor.execute("SELECT id FROM model WHERE id = ?", (model_id,))
        exists = cursor.fetchone()

        if exists:
            # Atualizar
            cursor.execute("""
                UPDATE model
                SET name = ?, meta = ?, updated_at = ?
                WHERE id = ?
            """, (model_name, meta, current_time, model_id))
            print(f"Atualizado: {model_id}")
        else:
            # Inserir
            cursor.execute("""
                INSERT INTO model (id, user_id, base_model_id, name, meta, params, created_at, updated_at, is_active)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1)
            """, (model_id, user_id, model_id, model_name, meta, params, current_time, current_time))
            print(f"Inserido: {model_id}")

    conn.commit()
    conn.close()
    print("\nConfiguração concluída! Recarregue o Open WebUI (F5).")

if __name__ == "__main__":
    setup_models()
