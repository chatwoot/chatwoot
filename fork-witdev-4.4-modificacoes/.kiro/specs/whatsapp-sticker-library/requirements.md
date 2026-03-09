# Requirements Document

## Introduction

Esta funcionalidade implementa um sistema completo de envio de stickers via WhatsApp no Chatwoot, replicando exatamente a experiência do WhatsApp mobile. O sistema permitirá que agentes de atendimento enviem stickers através de uma biblioteca integrada, incluindo stickers do Giphy, stickers personalizados e stickers recentemente utilizados, tudo isso aproveitando ao máximo as estruturas nativas existentes do Chatwoot sem necessidade de migrações de banco de dados.

## Requirements

### Requirement 1: Interface de Seleção de Stickers

**User Story:** Como um agente de atendimento, eu quero clicar em um botão de sticker na interface de chat para abrir uma biblioteca de stickers, para que eu possa enviar stickers de forma rápida e intuitiva como no WhatsApp mobile.

#### Acceptance Criteria

1. WHEN o agente clica no botão de sticker na barra de ferramentas do chat THEN o sistema SHALL exibir um modal/popup com a biblioteca de stickers
2. WHEN a biblioteca de stickers é aberta THEN o sistema SHALL mostrar abas para "Populares", "Pesquisar", "Recentes" e pacotes personalizados
3. WHEN o agente clica em um sticker THEN o sistema SHALL enviar o sticker imediatamente e fechar a biblioteca
4. WHEN a biblioteca está carregando stickers THEN o sistema SHALL exibir um indicador de carregamento
5. IF não há stickers para exibir THEN o sistema SHALL mostrar uma mensagem "Nenhum sticker encontrado"

### Requirement 2: Integração com Giphy

**User Story:** Como um agente de atendimento, eu quero acessar stickers populares e pesquisar stickers do Giphy, para que eu tenha uma vasta biblioteca de stickers disponível.

#### Acceptance Criteria

1. WHEN o agente acessa a aba "Populares" THEN o sistema SHALL carregar e exibir stickers em alta do Giphy
2. WHEN o agente digita um termo na aba "Pesquisar" e pressiona Enter THEN o sistema SHALL buscar stickers relacionados no Giphy
3. WHEN a API do Giphy retorna resultados THEN o sistema SHALL exibir apenas stickers com classificação "g" (conteúdo seguro)
4. WHEN a API do Giphy está indisponível THEN o sistema SHALL exibir mensagem de erro amigável
5. WHEN os resultados do Giphy são carregados THEN o sistema SHALL armazenar em cache por 10 minutos para melhor performance

### Requirement 3: Stickers Personalizados

**User Story:** Como um administrador da conta, eu quero fazer upload de stickers personalizados organizados em pacotes, para que minha equipe possa usar stickers alinhados com a marca da empresa.

#### Acceptance Criteria

1. WHEN um administrador faz upload de uma imagem como sticker THEN o sistema SHALL converter automaticamente para formato WebP 512x512 pixels
2. WHEN um sticker personalizado é criado THEN o sistema SHALL armazenar usando o modelo Attachment existente com meta['sticker_type'] = 'custom'
3. WHEN stickers personalizados são organizados em pacotes THEN o sistema SHALL usar o campo meta['sticker_pack'] para agrupamento
4. WHEN um agente acessa stickers personalizados THEN o sistema SHALL exibir abas para cada pacote disponível
5. IF o arquivo enviado não atende às especificações do WhatsApp THEN o sistema SHALL rejeitar com mensagem de erro clara

### Requirement 4: Stickers Recentemente Utilizados

**User Story:** Como um agente de atendimento, eu quero ver os stickers que usei recentemente, para que eu possa reutilizar rapidamente meus stickers favoritos.

#### Acceptance Criteria

1. WHEN um agente envia um sticker com sucesso THEN o sistema SHALL adicionar o sticker à lista de "Recentes" do agente
2. WHEN o agente acessa a aba "Recentes" THEN o sistema SHALL exibir os últimos 20 stickers utilizados ordenados por data de uso
3. WHEN um sticker é usado novamente THEN o sistema SHALL mover o sticker para o topo da lista de recentes
4. WHEN os dados de stickers recentes são armazenados THEN o sistema SHALL usar um campo no modelo User (ex: ui_settings['recent_stickers']) para persistir individualmente para cada agente
5. IF não há stickers recentes THEN o sistema SHALL exibir mensagem "Nenhum sticker usado recentemente"

### Requirement 5: Envio Otimizado via WhatsApp Cloud API

**User Story:** Como um agente de atendimento, eu quero que os stickers sejam enviados rapidamente e de forma confiável, para que a experiência seja fluida como no WhatsApp nativo.

#### Acceptance Criteria

1. WHEN um sticker é enviado pela primeira vez THEN o sistema SHALL fazer upload do arquivo para o WhatsApp e armazenar o media_id em cache
2. WHEN o mesmo sticker é enviado novamente THEN o sistema SHALL reutilizar o media_id em cache para envio instantâneo
3. WHEN um sticker é enviado THEN o sistema SHALL criar uma mensagem com content_type: 'sticker' usando o enum existente
4. WHEN o envio é bem-sucedido THEN o sistema SHALL exibir o sticker na conversa como uma mensagem normal
5. IF o envio falha THEN o sistema SHALL exibir erro específico e não criar a mensagem no dashboard

### Requirement 6: Processamento e Validação de Imagens

**User Story:** Como desenvolvedor do sistema, eu quero que todas as imagens sejam automaticamente processadas para atender às especificações do WhatsApp, para que não haja falhas no envio.

#### Acceptance Criteria

1. WHEN uma imagem é processada para sticker THEN o sistema SHALL converter para formato WebP
2. WHEN uma imagem é redimensionada THEN o sistema SHALL garantir dimensões exatas de 512x512 pixels
3. WHEN o arquivo final é gerado THEN o sistema SHALL validar que o tamanho seja menor que 100KB para estáticos
4. WHEN uma imagem animada é processada THEN o sistema SHALL validar que o tamanho seja menor que 500KB
5. IF uma imagem não pode ser processada THEN o sistema SHALL retornar erro específico com orientações para o usuário

### Requirement 7: Cache e Performance

**User Story:** Como usuário do sistema, eu quero que a biblioteca de stickers carregue rapidamente e não sobrecarregue as APIs externas, para que a experiência seja responsiva.

#### Acceptance Criteria

1. WHEN stickers do Giphy são buscados THEN o sistema SHALL armazenar resultados em cache Redis por 10 minutos
2. WHEN um media_id do WhatsApp é obtido THEN o sistema SHALL armazenar em cache por 30 dias conforme especificação da Meta
3. WHEN stickers personalizados são listados THEN o sistema SHALL usar consultas otimizadas no modelo Attachment
4. WHEN múltiplas requisições simultâneas são feitas THEN o sistema SHALL evitar chamadas duplicadas às APIs externas
5. IF o cache está indisponível THEN o sistema SHALL funcionar normalmente fazendo chamadas diretas às APIs

### Requirement 8: Integração com Interface Existente

**User Story:** Como um agente de atendimento, eu quero que o botão de stickers esteja integrado naturalmente na interface de chat existente, para que não precise aprender uma nova forma de trabalhar.

#### Acceptance Criteria

1. WHEN o agente está em uma conversa do WhatsApp THEN o sistema SHALL exibir o botão de sticker na barra de ferramentas
2. WHEN o agente está em conversas de outros canais THEN o sistema SHALL ocultar o botão de sticker
3. WHEN um sticker é enviado THEN o sistema SHALL exibir na conversa usando os componentes de mensagem existentes
4. WHEN a biblioteca de stickers é aberta THEN o sistema SHALL manter a consistência visual com o design system do Chatwoot
5. IF a conversa não suporta stickers THEN o sistema SHALL desabilitar o botão com tooltip explicativo