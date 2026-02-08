#!/bin/bash

# Nome da pasta de destino
DEST_DIR="fork-witdev-4.4-modificacoes"

# Cria a pasta se não existir
mkdir -p "$DEST_DIR"

echo "============================================"
echo "🚀 Iniciando Backup Inteligente das Modificações"
echo "📂 Destino: ./$DEST_DIR"
echo "============================================"

# Lista de arquivos e pastas CRÍTICOS (Adicione mais aqui se lembrar de algo)
# Nota: O script vai entrar nessas pastas e copiar os arquivos, ignorando testes.
FILES_TO_COPY=(
    # --- CORE & ENTERPRISE UNLOCK ---
    "app/models/account.rb"
    "app/models/feature.rb"
    "app/models/custom_role.rb"
    "enterprise/app/models/custom_role.rb"
    "config/routes.rb"
    "config/initializers/socialwise_cache.rb"
    "app/controllers/super_admin/accounts_controller.rb"
    "enterprise/app/views/fields/manually_managed_features_field"

    # --- SOCIALWISE & STICKERS (BACKEND) ---
    "app/controllers/api/v1/accounts/integrations/socialwise_chatwit_controller.rb"
    "app/controllers/api/v1/accounts/sticker_packs_controller.rb"
    "app/controllers/api/v1/accounts/sticker_performance_controller.rb"
    "app/controllers/api/v1/accounts/stickers_controller.rb"
    "app/services/sticker_cache_monitor_service.rb"
    "app/services/sticker_error_logger_service.rb"
    "app/services/sticker_image_optimizer_service.rb"
    "app/services/sticker_performance_metrics_service.rb"
    "app/services/sticker_service.rb"
    "app/models/sticker.rb"
    "app/models/concerns/socialwise_cache_invalidation.rb"
    "app/jobs/socialwise_debounce_job.rb"
    "lib/integrations/socialwise"
    "lib/integrations/socialwise_flow"

    # --- RICH MESSAGES (INSTAGRAM/WHATSAPP) - SOLICITADO ---
    # Incluindo mesmo que vá usar o nativo depois, para consulta.
    "app/services/instagram"
    "app/services/whatsapp"
    "app/builders/messages"

    # --- FRONTEND (VUE.JS) ---
    # SocialWise & Stickers
    "app/javascript/dashboard/routes/dashboard/settings/stickers"
    "app/javascript/dashboard/components/widgets/conversation/StickerPicker"
    "app/javascript/dashboard/components-next/message/bubbles/Sticker.vue"
    
    # Rich Messages (Conversas, Balões de msg)
    "app/javascript/dashboard/components/widgets/conversation"
    "app/javascript/dashboard/components-next/message"

    # --- MIGRATIONS (Apenas as novas de 2025/2026) ---
    "db/migrate/2025*"
    "db/migrate/2026*"

    # --- ASSETS ---
    "public/brand-assets"
)

# Loop principal
for ITEM in "${FILES_TO_COPY[@]}"; do
    # Verifica se é um padrão com * (globbing)
    if [[ "$ITEM" == *"*"* ]]; then
        # Expande o globbing
        for EXPANDED_ITEM in $ITEM; do
             if [ -e "$EXPANDED_ITEM" ]; then
                cp --parents "$EXPANDED_ITEM" "$DEST_DIR" 2>/dev/null
                echo "✅ Copiado: $EXPANDED_ITEM"
             fi
        done
        continue
    fi

    # Se o item existe
    if [ -e "$ITEM" ]; then
        if [ -d "$ITEM" ]; then
            # É UMA PASTA: Usar find para copiar ignorando lixo
            echo "📂 Processando pasta: $ITEM"
            
            # Encontra arquivos dentro da pasta, EXCLUINDO testes, docs, specs, logs
            find "$ITEM" -type f \
                | grep -vE "spec|test|Test|stories|md$|txt$|log$|.DS_Store" \
                | while read -r FILE; do
                    cp --parents "$FILE" "$DEST_DIR"
                    # echo "  -> $FILE" # Descomente se quiser ver arquivo por arquivo
                done
        else
            # É UM ARQUIVO ÚNICO
            cp --parents "$ITEM" "$DEST_DIR"
            echo "✅ Arquivo: $ITEM"
        fi
    else
        echo "⚠️  Não encontrado (pulando): $ITEM"
    fi
done

echo "============================================"
echo "🏁 Concluído!"
echo "Seus arquivos limpos estão em: $DEST_DIR"
echo "============================================"