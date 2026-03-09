# Implementation Plan

## CRITICAL: File Tracking Instructions

**At the end of each task, you MUST:**

1. **IDENTIFY**: List ALL files created or modified during that task

2. **COMBINE**: Take the current task's "Files:" list + all files you actually created/modified

3. **UPDATE**: Add this COMBINED list to the next task's "Files:" section

4. **NEVER REPLACE**: Always ADD to existing files, never replace the list

5. **FORMAT**: `Task X - [Description] | Files: existing_file1.rb, existing_file2.vue, new_file1.js, new_file2.rb`

**EXAMPLE:**

- Current task has: `Files: file1.rb, file2.vue`

- You created: `file3.js, file4.rb`

- Next task should get: `Files: file1.rb, file2.vue, file3.js, file4.rb`

This ensures complete context flow throughout the entire project.

- [x] 1. Corrigir Processamento de Imagem para Manter Animação e Transparência

  - Detectar figurinhas animadas (GIF/WebP animado) usando MiniMagick frames
  - Preservar animação durante conversão para WebP mantendo todos os frames
  - Manter transparência configurando WebP para preservar canal alpha
  - Aplicar limites corretos: 500KB para animadas, 100KB para estáticas
  - Evitar adição de fundo branco em figurinhas transparentes
  - **AT TASK END: CRITICAL - Add ALL files from current task's "Files:" list + ALL files actually created/modified to the next task's "Files:" list. Do NOT replace, ADD to existing files.**
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7_

- [x] 2. Implementar Fluxo de Envio Otimista no Backend | Files: app/services/sticker_image_optimizer_service.rb, spec/services/sticker_image_optimizer_service_spec.rb, spec/fixtures/files/test_image.png

  - Modificar SendStickerService para criar mensagem imediatamente com MessageBuilder
  - Usar status nativo 'sent' na criação (mostra relógio na UI)
  - Atualizar para 'delivered' após sucesso na API WhatsApp (mostra check)
  - Atualizar para 'failed' em caso de erro (mostra ícone de erro)
  - Remover controles de status customizados, usar apenas enums nativos
  - **AT TASK END: CRITICAL - Add ALL files from current task's "Files:" list + ALL files actually created/modified to the next task's "Files:" list. Do NOT replace, ADD to existing files.**
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.7_

- [x] 3. Ajustar Frontend para Feedback Visual Imediato | Files: app/services/sticker_image_optimizer_service.rb, spec/services/sticker_image_optimizer_service_spec.rb, spec/fixtures/files/test_image.png, app/services/whatsapp/send_sticker_service.rb, spec/services/whatsapp/send_sticker_service_spec.rb, test_optimistic_sticker_flow_simple.rb

  - Fechar modal StickerPicker imediatamente após seleção
  - Mostrar figurinha na conversa instantaneamente (UI otimista)
  - Reagir a mudanças de status via websocket para atualizar ícones
  - Implementar tratamento de erro com mensagens específicas
  - Seguir padrão nativo Chatwoot de loading → check → erro
  - **TASK COMPLETED: Files created/modified in this task:**

    - app/javascript/dashboard/components/widgets/conversation/StickerPicker/StickerPicker.vue (modified)
    - app/javascript/dashboard/components/widgets/conversation/ReplyBox.vue (modified)
    - test_optimistic_sticker_frontend.rb (created)

    - test_frontend_sticker_integration.html (created)

  - _Requirements: 2.1, 2.5, 4.1, 4.2, 4.3, 4.4, 4.5, 4.6_
