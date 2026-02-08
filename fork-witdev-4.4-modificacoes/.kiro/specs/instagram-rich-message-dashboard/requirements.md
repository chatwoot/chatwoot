# Requirements Document

## Introduction

O sistema atualmente envia mensagens ricas para o Instagram (com botões, imagens e quick replies) através do `Instagram::RichMessageService`, mas no painel do Chatwoot essas mensagens aparecem apenas como texto simples. Esta funcionalidade visa espelhar a renderização rica no dashboard para que as mensagens apareçam visualmente iguais ao que é exibido no Instagram, mantendo a fidelidade visual e melhorando a experiência do agente.

## Requirements

### Requirement 1

**User Story:** Como agente de atendimento, quero visualizar mensagens ricas enviadas para o Instagram (cards, botões, quick replies) no painel do Chatwoot da mesma forma que aparecem no Instagram, para ter uma visão completa e fiel da conversa.

#### Acceptance Criteria

1. WHEN uma mensagem rica é enviada via `Instagram::RichMessageService` THEN o sistema SHALL espelhar o conteúdo rico na tabela `messages` com `content_type` e `content_attributes` apropriados
2. WHEN uma mensagem do tipo "generic template" é enviada THEN o sistema SHALL converter para `content_type: :cards` com estrutura normalizada de items
3. WHEN uma mensagem do tipo "button template" é enviada THEN o sistema SHALL converter para `content_type: :cards` com um único item contendo os botões
4. WHEN uma mensagem com "quick replies" é enviada THEN o sistema SHALL converter para `content_type: :input_select` com lista de opções

### Requirement 2

**User Story:** Como desenvolvedor, quero um normalizador único que converta payloads ricos do Instagram para estruturas nativas do Chatwoot, para manter consistência e facilitar manutenção.

#### Acceptance Criteria

1. WHEN o normalizador recebe um payload do tipo "generic" THEN o sistema SHALL converter para estrutura de cards com media_url, title, description e actions
2. WHEN o normalizador recebe um payload do tipo "button" THEN o sistema SHALL converter para um card único com título e botões
3. WHEN o normalizador recebe quick_replies THEN o sistema SHALL converter para input_select com items contendo title e value
4. WHEN o normalizador encontra URLs THEN o sistema SHALL validar e sanitizar as URLs antes de incluir na estrutura
5. WHEN o normalizador processa botões THEN o sistema SHALL limitar a MAX_BTNS (3) botões por mensagem
6. WHEN o normalizador processa cards THEN o sistema SHALL limitar a MAX_CARDS (10) cards por mensagem

### Requirement 3

**User Story:** Como agente, quero que o dashboard renderize cards com imagens, títulos, descrições e botões de forma visualmente atrativa, para ter uma experiência similar ao Instagram.

#### Acceptance Criteria

1. WHEN o dashboard recebe uma mensagem com `content_type: :cards` THEN o sistema SHALL renderizar um componente RichCards
2. WHEN um card contém media_url THEN o sistema SHALL exibir a imagem com fallback em caso de erro
3. WHEN um card contém botões do tipo "web_url" THEN o sistema SHALL renderizar links com target="_blank" e rel="noopener noreferrer"
4. WHEN um card contém botões do tipo "postback" THEN o sistema SHALL renderizar botões visuais (o META já envia texto e payload naturalmente)

### Requirement 4

**User Story:** Como administrador do sistema, quero controlar a funcionalidade de renderização rica através de feature flag, para poder ativar/desativar sem redeploy.

#### Acceptance Criteria

1. WHEN a feature flag `SOCIALWISE_RICH_DASHBOARD` está habilitada THEN o sistema SHALL renderizar mensagens ricas no dashboard
2. WHEN a feature flag `SOCIALWISE_RICH_DASHBOARD` está desabilitada THEN o sistema SHALL usar renderização de texto simples como fallback
3. WHEN ocorre erro na renderização rica THEN o sistema SHALL usar o texto de fallback sem quebrar a interface

### Requirement 5

**User Story:** Como desenvolvedor, quero que o sistema mantenha compatibilidade com o fluxo atual de envio, para não quebrar funcionalidades existentes.

#### Acceptance Criteria

1. WHEN uma mensagem é criada para envio via `Instagram::RichMessageService` THEN o sistema SHALL marcar `skip_send_reply: true` para evitar duplicação
2. WHEN o espelhamento de payload falha THEN o sistema SHALL logar o erro e continuar com o envio normal
3. WHEN a mensagem é atualizada com conteúdo rico THEN o sistema SHALL enviar evento de atualização via ActionCable
4. WHEN não há payload rico THEN o sistema SHALL manter o comportamento atual de texto simples

### Requirement 6

**User Story:** Como usuário do sistema, quero que todas as URLs e conteúdos sejam sanitizados, para garantir segurança contra XSS e outros ataques.

#### Acceptance Criteria

1. WHEN o sistema processa URLs THEN o sistema SHALL validar que são HTTP/HTTPS válidas
2. WHEN o componente renderiza conteúdo THEN o sistema SHALL usar apenas text nodes, nunca v-html
3. WHEN o sistema processa títulos e descrições THEN o sistema SHALL sanitizar o conteúdo removendo tags HTML
4. WHEN há conteúdo malicioso THEN o sistema SHALL rejeitar e usar fallback de texto simples