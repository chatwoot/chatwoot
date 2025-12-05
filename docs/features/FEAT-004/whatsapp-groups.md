# PRD-001: WhatsApp Group Message Support for Chatwoot

## Overview

Adicionar suporte básico para recebimento e envio de mensagens em grupos do WhatsApp na integração WhatsApp Web do Chatwoot, permitindo que agentes visualizem e respondam a mensagens em conversas de grupo.

## Estado Atual

O atual `incoming_message_whatsapp_web_service.rb` explicitamente ignora eventos de grupo:
- Linha 115-118: Ignora eventos `group.message` e `group.participants`
- Linha 134: Identifica mensagens de grupo pelo identificador `@g.us` mas não as processa
- Linha 203-207: `normalize_group_payload` retorna estrutura vazia

## Funcionalidades da API go-whatsapp-web-multidevice (Escopo Reduzido)

### Operações Relevantes para Mensagens de Grupo

1. **Recebimento de Mensagens**:
   - Webhook eventos `group.message` para mensagens recebidas em grupos
   - Webhook eventos `group.participants` para mudanças básicas de participantes

2. **Envio de Mensagens**:
   - `POST /send-message` - Enviar mensagem para grupo (usando chat_id do grupo)
   - Suporte aos mesmos tipos de mensagem que conversas individuais (texto, mídia, etc.)

## Requisitos de Negócio

### Funcionalidades Principais (Escopo Reduzido)
1. **Processamento de Mensagens de Grupo**: Processar mensagens enviadas e recebidas em grupos WhatsApp
2. **Atribuição Individual de Mensagens**: Cada mensagem deve estar atribuída ao contato específico que a enviou
3. **Conversa Multi-Contato**: Um grupo = uma conversa com múltiplos contatos participantes
4. **Identificação de Remetente**: Mostrar claramente quem enviou cada mensagem no grupo
5. **Contact Inbox por Participante**: Criar/usar contact_inbox para cada participante do grupo
6. **Envio de Mensagens**: Permitir que agentes respondam em grupos

### Histórias de Usuário (Escopo Reduzido)
1. **Como agente**, quero ver conversas de grupo na minha caixa de entrada para responder a consultas de clientes em grupos
2. **Como agente**, quero ver claramente quem enviou cada mensagem no grupo (nome do contato específico)
3. **Como agente**, quero clicar no perfil de um participante do grupo para ver seu histórico individual
4. **Como agente**, quero enviar mensagens de resposta em grupos direcionadas a todos os participantes
5. **Como agente**, quero identificar facilmente se uma conversa é de grupo ou individual
6. **Como sistema**, cada mensagem de grupo deve manter a atribuição ao contato correto que a enviou

## Requisitos Técnicos

### Abordagem Simplificada - Sem Mudanças no Banco

#### Zero Modificações no Esquema
- **Não adicionar novas colunas** ou tabelas
- **Usar campos JSON existentes** (`additional_attributes` na tabela conversations)
- **Detectar grupos dinamicamente** pelo identificador `@g.us` no payload

#### Estratégia de Identificação e Atribuição de Grupos
1. **Identificação de Grupo**: `chat_id` contendo `@g.us` indica mensagem de grupo
2. **Atribuição de Mensagem**: `from` contém o JID do participante que enviou a mensagem
3. **Arquitetura de Conversa**:
   - **Uma conversa por grupo** (identificada pelo `group_jid`)
   - **Múltiplos contact_inbox** na mesma conversa (um por participante)
   - **Cada mensagem** atribuída ao `sender` correto (o contato específico)

4. **Metadados do Grupo** em `additional_attributes`:
   ```json
   {
     "group_jid": "120363025246125486@g.us",
     "group_name": "Nome do Grupo",
     "is_group": true,
     "participants_count": 5,
     "last_message_from": "João Silva"
   }
   ```

5. **Fluxo de Processamento**:
   - Detectar que é mensagem de grupo (`@g.us`)
   - Extrair `group_jid` do `chat_id`
   - Extrair `participant_jid` do `from`
   - Buscar/criar conversa do grupo
   - Buscar/criar contact_inbox do participante
   - Criar mensagem com `sender` = participante específico

### Mudanças na Camada de Serviços (Escopo Reduzido)

#### Atualizações Mínimas do Serviço WhatsApp Web

1. **Remover skip de grupos**: Permitir processamento de `group.message` (linhas 115-118)
2. **Implementar `normalize_group_payload`**: Extrair `group_jid`, `participant_jid` e dados da mensagem
3. **Modificar `set_contact`**: Buscar/criar contato do participante (não do grupo)
4. **Modificar `set_conversation`**: Buscar/criar conversa baseada no `group_jid`
5. **Atribuir mensagem corretamente**: `sender` deve ser o contato participante específico

#### Métodos Simples a Adicionar
```ruby
def is_group_message?(payload)
  payload[:chat_id]&.include?('@g.us')
end

def extract_group_jid(payload)
  payload[:chat_id] # Para grupos, chat_id é o group_jid
end

def extract_participant_jid(payload)
  payload[:from] # Para grupos, from é o participante que enviou
end

def find_or_create_group_conversation(group_jid, payload)
  # Buscar conversa existente pelo group_jid em additional_attributes
  # Ou criar nova conversa com metadados do grupo
  existing = inbox.conversations.joins(:contact_inboxes)
    .where("additional_attributes->>'group_jid' = ?", group_jid).first
    
  existing || create_group_conversation(group_jid, payload)
end

def find_or_create_participant_contact(participant_jid)
  # Buscar/criar contato do participante específico
  # Usar mesmo fluxo que conversas individuais
end
```

### Processamento de Payload

Com base na documentação webhook, lidar com estes tipos de evento:

#### Mensagens de Grupo (`group.message`)
```json
{
  "event": "group.message",
  "chat_id": "120363025246125486@g.us",    // ← group_jid (identifica o grupo)
  "from": "5511999887766@s.whatsapp.net", // ← participant_jid (quem enviou)
  "message": {
    "id": "message_id",
    "text": "Hello group!"
  },
  "timestamp": "2024-01-01T12:00:00Z"
}
```

**Processamento:**
- `chat_id` = group_jid → identifica/cria a conversa do grupo
- `from` = participant_jid → identifica/cria o contato do participante
- Mensagem fica atribuída ao participante específico como `sender`

#### Eventos de Participantes do Grupo (`group.participants`)
```json
{
  "event": "group.participants",
  "chat_id": "120363025246125486@g.us", 
  "type": "join", // join, leave, promote, demote
  "jids": ["5511999887766@s.whatsapp.net"],
  "timestamp": "2024-01-01T12:00:00Z"
}
```

**Processamento (básico):**
- Atualizar lista de participantes em `additional_attributes`
- Opcional: criar mensagem do sistema informando entrada/saída

### Mudanças na API (Escopo Reduzido)

#### Sem Novos Endpoints Necessários
- **Usar APIs existentes** de conversas e mensagens
- **Conversas de grupo** aparecerão naturalmente na lista de conversas existente
- **Envio de mensagens** usa o mesmo endpoint existente `POST /api/v1/accounts/:account_id/conversations/:id/messages`
- **Group_jid é automaticamente detectado** a partir da conversa

### Requisitos de UI/UX (Escopo Reduzido)

#### Lista de Conversas
- **Indicador visual** de grupo (ícone diferente) para conversas de grupo
- **Mostrar nome do grupo** em vez do nome do contato individual
- **Identificação clara** de que é uma conversa de grupo

#### Visualização de Conversa
- **Nome do remetente** visível em cada mensagem (contato específico que enviou)
- **Avatar do participante** para cada mensagem (não avatar do grupo)
- **Título da conversa** mostra o nome do grupo
- **Histórico individual** - clicar no participante mostra suas mensagens anteriores
- **Lista de participantes** visível na sidebar (opcional)
- **Funcionamento normal** de envio de mensagens (vai para todos do grupo)

## Plano de Implementação (Abordagem Simplificada)

### Fase 1: Backend - Processamento Básico (3-4 dias)
1. **Remover skip** de grupos: Modificar linhas 115-118 em `incoming_message_whatsapp_web_service.rb`
2. **Implementar detecção** de grupos: Adicionar métodos `is_group_message?`, `extract_group_jid`, `extract_participant_jid`
3. **Implementar `normalize_group_payload`**: Processar payloads separando grupo e participante
4. **Modificar `set_contact`**: Buscar/criar contato do participante individual (não do grupo)
5. **Modificar `set_conversation`**: Buscar/criar conversa por `group_jid`, com múltiplos contact_inboxes
6. **Garantir atribuição**: Cada mensagem com `sender` = participante específico
7. **Testes básicos** de recebimento e atribuição correta

### Fase 2: Backend - Refinamentos (2-3 dias)
1. **Verificar envio** para grupos (provavelmente já funciona)
2. **Salvar metadados** do grupo em `additional_attributes`
3. **Gerenciar participantes** básicos (lista em `additional_attributes`)
4. **Testes de envio** para grupos

### Fase 3: Frontend - UI Mínima (2-3 dias)
1. **Detectar grupos** no frontend via `additional_attributes.is_group`
2. **Mostrar indicador** visual de grupo na lista de conversas
3. **Exibir nome do grupo** no cabeçalho (via `additional_attributes.group_name`)
4. **Mostrar nome do participante** em cada mensagem (usar `message.sender.name`)
5. **Exibir avatar** do participante individual (não do grupo)
6. **Opcional**: Lista de participantes na sidebar

### Fase 4: Testes Finais (1-2 dias)
1. **Testes end-to-end** com grupos reais
2. **Validar atribuição** correta de mensagens aos participantes
3. **Testar envio** de mensagens para grupos
4. **Verificar interface** mostra participantes corretos
5. **Ajustes** de bugs encontrados

## Métricas de Sucesso (Escopo Reduzido)

1. **Funcional**: Mensagens de grupo são recebidas e exibidas corretamente
2. **Atribuição Correta**: Cada mensagem está atribuída ao participante correto que a enviou
3. **Identificação**: Conversas de grupo são claramente diferenciadas de conversas individuais
4. **Contexto Individual**: Nome e avatar do participante específico é mostrado em cada mensagem
5. **Múltiplos Contatos**: Uma conversa de grupo contém múltiplos contact_inboxes (um por participante)
6. **Envio**: Agentes conseguem responder normalmente em grupos
7. **Performance**: Processamento de mensagens de grupo não impacta performance significativamente

## Considerações de Risco (Escopo Reduzido)

1. **Volume de Mensagens**: Grupos podem ter alto volume de mensagens
2. **Atribuição de Mensagens**: Garantir que sempre conseguimos identificar corretamente quem enviou cada mensagem
3. **Múltiplos Contact_Inboxes**: Gerenciar corretamente uma conversa com vários contatos
4. **Performance**: Evitar impacto na performance das conversas existentes
5. **Compatibilidade**: Manter compatibilidade com funcionalidades existentes
6. **Sincronização**: Manter participantes sincronizados quando entram/saem do grupo

## Dependências (Abordagem Simplificada)

1. **Webhook configurado**: Integração webhook do WhatsApp Web deve estar enviando eventos de grupo
2. **API funcionando**: go-whatsapp-web-multidevice deve suportar envio para grupos  
3. **Zero migrações**: Sem mudanças no esquema do banco
4. **Frontend mínimo**: Pequenas mudanças na interface existente

## Documentos Relacionados

- [Documentação de Webhook](https://github.com/chatwoot-br/go-whatsapp-web-multidevice/blob/main/docs/webhook-payload.md)
- [Especificação OpenAPI](https://github.com/chatwoot-br/go-whatsapp-web-multidevice/blob/main/docs/openapi.yaml)
- Diretrizes de desenvolvimento Chatwoot (`/workspace/CLAUDE.md`)

---

**Autor**: Claude AI  
**Data de Criação**: 2025-01-14  
**Última Atualização**: 2025-01-14  
**Status**: Draft - Abordagem Simplificada  
**Versão**: 1.2