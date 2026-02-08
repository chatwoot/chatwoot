# Requirements Document

## Introduction

Este documento define os requisitos para melhorar o sistema de figurinhas do Chatwoot, corrigindo dois problemas críticos: (1) figurinhas animadas que perdem animação e ganham fundo branco durante o processamento, e (2) fluxo de envio incorreto onde a figurinha só aparece no chat após resposta da API, quando deveria aparecer imediatamente com loading.

## Requirements

### Requirement 1: Preservar Animação e Transparência de Figurinhas

**User Story:** Como um usuário do WhatsApp, eu quero que figurinhas animadas e com fundo transparente mantenham suas características originais quando enviadas, para que a experiência seja natural e visualmente correta.

#### Acceptance Criteria

1. WHEN uma figurinha animada (GIF/WebP animado) é detectada THEN o sistema SHALL preservar a animação usando WebP animado
2. WHEN uma figurinha com fundo transparente é processada THEN o sistema SHALL manter a transparência sem adicionar fundo branco
3. WHEN o StickerImageOptimizerService processa uma figurinha animada THEN o sistema SHALL usar parâmetros específicos para animação
4. WHEN uma figurinha animada é otimizada THEN o sistema SHALL respeitar o limite de 500KB do WhatsApp
5. WHEN uma figurinha estática é otimizada THEN o sistema SHALL respeitar o limite de 100KB do WhatsApp
6. IF uma figurinha animada excede 500KB THEN o sistema SHALL reduzir qualidade mantendo animação
7. WHEN transparência é detectada THEN o sistema SHALL usar configurações WebP que preservam canal alpha

### Requirement 2: Implementar Fluxo de Envio Imediato

**User Story:** Como um usuário do chat, eu quero que ao clicar em uma figurinha ela apareça imediatamente no chat com indicador de loading, para que eu tenha feedback visual instantâneo seguindo o padrão do Chatwoot.

#### Acceptance Criteria

1. WHEN um usuário clica em uma figurinha THEN o sistema SHALL criar a mensagem imediatamente no chat com status "sending"
2. WHEN a mensagem é criada THEN o sistema SHALL mostrar indicador de loading (relógio) na bolha da mensagem
3. WHEN a API do WhatsApp responde com sucesso THEN o sistema SHALL atualizar o status para "sent" com check mark
4. WHEN a API do WhatsApp falha THEN o sistema SHALL mostrar status de erro na mensagem
5. WHEN o modal de figurinhas está aberto THEN o sistema SHALL fechar automaticamente após seleção
6. IF o envio falha THEN o usuário SHALL poder tentar reenviar a mensagem
7. WHEN uma mensagem de figurinha é criada THEN o sistema SHALL usar o MessageBuilder com skip_send_reply: true

### Requirement 3: Otimizar Performance do Sistema de Figurinhas

**User Story:** Como um administrador do sistema, eu quero que o sistema de figurinhas seja performático e confiável, para que os usuários tenham uma experiência fluida.

#### Acceptance Criteria

1. WHEN figurinhas são processadas THEN o sistema SHALL usar cache Redis::Alfred para media_ids do WhatsApp por 30 dias
2. WHEN uma figurinha é otimizada THEN o sistema SHALL usar o StickerImageOptimizerService existente com melhorias
3. WHEN erros ocorrem THEN o sistema SHALL logar detalhes usando StickerErrorLoggerService
4. WHEN figurinhas são enviadas THEN o sistema SHALL rastrear métricas usando StickerPerformanceMetricsService
5. IF uma figurinha já foi processada THEN o sistema SHALL reutilizar o media_id do cache WhatsApp
6. WHEN o cache expira THEN o sistema SHALL reprocessar automaticamente mantendo características originais

### Requirement 4: Melhorar Feedback Visual no Frontend

**User Story:** Como um usuário do chat, eu quero feedback visual claro sobre o status das minhas figurinhas, para que eu saiba quando foram enviadas com sucesso ou falharam.

#### Acceptance Criteria

1. WHEN uma figurinha é selecionada THEN o modal SHALL fechar imediatamente
2. WHEN uma mensagem de figurinha é criada THEN o sistema SHALL mostrar a figurinha na bolha com loading
3. WHEN o envio é bem-sucedido THEN o sistema SHALL mostrar check mark verde
4. WHEN o envio falha THEN o sistema SHALL mostrar ícone de erro vermelho
5. WHEN há erro de rede THEN o sistema SHALL mostrar mensagem específica de conectividade
6. IF o usuário clica em mensagem com erro THEN o sistema SHALL oferecer opção de reenvio