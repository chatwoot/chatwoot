# Requirements Document

## Introduction

Esta funcionalidade implementa o processamento de payloads do Dialogflow no Chatwoot para enviar mensagens ricas e interativas (carrosséis, botões, respostas rápidas) no Instagram. A inteligência para decidir qual mensagem enviar reside no serviço Socialwise, enquanto o Chatwoot atua como o motor de execução final, responsável por se comunicar com a API da Meta.

O fluxo completo é: Usuário → Instagram → Chatwoot → Dialogflow → Socialwise (Webhook) → Socialwise → Dialogflow → Chatwoot → Instagram → Usuário.

## Requirements

### Requirement 1

**User Story:** Como desenvolvedor do sistema, quero processar payloads do Dialogflow que contenham socialwiseResponse, para que o Chatwoot possa enviar mensagens ricas no Instagram baseadas nas instruções do Socialwise.

#### Acceptance Criteria

1. WHEN o Dialogflow retorna um payload com socialwiseResponse THEN o sistema SHALL identificar e extrair o objeto socialwiseResponse
2. WHEN o socialwiseResponse é identificado THEN o sistema SHALL converter o objeto Protobuf para Hash Ruby limpo
3. WHEN o Hash limpo é obtido THEN o sistema SHALL processar as instruções contidas no socialwiseResponse
4. WHEN o processamento falha THEN o sistema SHALL fazer fallback para o comportamento padrão do Chatwoot

### Requirement 2

**User Story:** Como usuário do Instagram, quero receber mensagens com carrosséis de cards, para que eu possa visualizar múltiplas opções de forma organizada.

#### Acceptance Criteria

1. WHEN socialwiseResponse contém message_format "GENERIC_TEMPLATE" THEN o sistema SHALL enviar um Generic Template para a API do Instagram
2. WHEN o payload contém elementos com título, subtítulo e imagem THEN o sistema SHALL incluir todos esses dados na mensagem
3. WHEN o payload contém botões THEN o sistema SHALL incluir os botões com seus tipos (postback, web_url) e payloads
4. WHEN o Generic Template é enviado THEN o sistema SHALL usar as credenciais do inbox atual

### Requirement 3

**User Story:** Como usuário do Instagram, quero receber mensagens com botões de ação, para que eu possa interagir facilmente com o sistema.

#### Acceptance Criteria

1. WHEN socialwiseResponse contém message_format "BUTTON_TEMPLATE" THEN o sistema SHALL enviar um Button Template para a API do Instagram
2. WHEN o payload contém texto e botões THEN o sistema SHALL incluir o texto da mensagem e até 3 botões
3. WHEN os botões são do tipo postback THEN o sistema SHALL incluir o payload correto para processamento posterior
4. WHEN os botões são do tipo web_url THEN o sistema SHALL incluir a URL correta para redirecionamento

### Requirement 4

**User Story:** Como usuário do Instagram, quero receber mensagens com respostas rápidas, para que eu possa responder rapidamente com opções predefinidas.

#### Acceptance Criteria

1. WHEN socialwiseResponse contém message_format "QUICK_REPLIES" THEN o sistema SHALL enviar Quick Replies para a API do Instagram
2. WHEN o payload contém texto e quick_replies THEN o sistema SHALL incluir o texto da mensagem e as opções de resposta rápida
3. WHEN as quick_replies são enviadas THEN elas SHALL desaparecer após o uso pelo usuário
4. WHEN o usuário seleciona uma quick_reply THEN o sistema SHALL receber o payload correspondente

### Requirement 5

**User Story:** Como desenvolvedor do sistema, quero que o processamento de mensagens ricas seja isolado do fluxo padrão, para que não comprometa a funcionalidade existente do Chatwoot.

#### Acceptance Criteria

1. WHEN socialwiseResponse não está presente THEN o sistema SHALL seguir o fluxo padrão do Chatwoot
2. WHEN o processamento de mensagens ricas falha THEN o sistema SHALL fazer fallback para mensagem de texto padrão
3. WHEN a resposta do Dialogflow contém uma mensagem com socialwiseResponse THEN o sistema SHALL processar APENAS a mensagem socialwiseResponse e IGNORAR quaisquer outras mensagens de texto padrão (fulfillmentText ou text messages) contidas na mesma resposta
4. WHEN o processamento é executado THEN o sistema SHALL manter a compatibilidade com a lógica existente

### Requirement 6

**User Story:** Como administrador do sistema, quero logs detalhados do processamento de mensagens ricas, para que eu possa monitorar e debugar a funcionalidade.

#### Acceptance Criteria

1. WHEN socialwiseResponse é processado THEN o sistema SHALL gerar logs com prefixo [SOCIALWISE-INSTAGRAM]
2. WHEN erros ocorrem durante o processamento THEN o sistema SHALL logar detalhes do erro e contexto
3. WHEN mensagens são enviadas com sucesso THEN o sistema SHALL logar confirmação com detalhes da mensagem
4. WHEN formatos desconhecidos são recebidos THEN o sistema SHALL logar aviso sobre formato não suportado

### Requirement 7

**User Story:** Como desenvolvedor do sistema, quero reutilizar a infraestrutura existente do Instagram, para que a implementação seja consistente com os padrões do Chatwoot.

#### Acceptance Criteria

1. WHEN mensagens ricas são enviadas THEN o sistema SHALL usar as mesmas URLs e credenciais da Graph API do Instagram
2. WHEN a API do Instagram é chamada THEN o sistema SHALL seguir o mesmo padrão de autenticação existente
3. WHEN erros da API ocorrem THEN o sistema SHALL usar o mesmo tratamento de erro existente
4. WHEN mensagens são enviadas THEN o sistema SHALL seguir o mesmo padrão de rate limiting existente