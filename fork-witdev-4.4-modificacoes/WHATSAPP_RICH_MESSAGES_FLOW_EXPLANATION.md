# Como Processamos Mensagens Ricas do WhatsApp e Exibimos no Dashboard

## Visão Geral do Fluxo

O processamento de mensagens ricas do WhatsApp no Chatwoot segue um fluxo específico desde o recebimento da resposta do SocialWise Flow até a exibição na interface do agente humano.

## 1. Processamento Backend (Ruby)

### 1.1 Recebimento da Resposta do SocialWise Flow

Quando o SocialWise Flow retorna uma resposta com mensagem interativa do WhatsApp:

```ruby
# lib/integrations/socialwise_flow/processor_service.rb
def process_whatsapp_response(message, whatsapp_payload)
  # Extrair texto principal para exibir no dashboard
  text_content = extract_whatsapp_text(whatsapp_payload)
  
  # Determinar se é mensagem interativa
  is_interactive = whatsapp_payload['type'] == 'interactive' && 
                   whatsapp_payload['interactive'].present?
  
  if is_interactive
    # Para mensagens interativas, usar content_type 'integrations'
    outgoing_message = conversation.messages.create!(
      message_type: :outgoing,
      content: text_content,                    # Texto para exibir no dashboard
      content_type: 'integrations',            # Tipo especial para integrações
      content_attributes: {
        'interactive' => whatsapp_payload['interactive'],
        'type' => whatsapp_payload['type'],
        'whatsapp_interactive_payload' => whatsapp_payload['interactive']
      },
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id
    )
  end
end
```

### 1.2 Estrutura do Payload WhatsApp Interativo

**Exemplo de Payload de Botões:**
```json
{
  "whatsapp": {
    "type": "interactive",
    "interactive": {
      "body": {
        "text": "> Sr(a) *Cliente*, \nSomos especializados em mandado de segurança..."
      },
      "header": {
        "type": "image",
        "image": {
          "link": "https://objstoreapi.witdev.com.br/chatwit-social/image.png"
        }
      },
      "footer": {
        "text": "Dra. Amanda Sousa Advocacia e Consultoria Jurídica™"
      },
      "type": "button",
      "action": {
        "buttons": [
          {
            "type": "reply",
            "reply": {
              "id": "btn_1756139209769_0_u8bq",
              "title": "Falar com a Dra"
            }
          }
        ]
      }
    }
  }
}
```

**Exemplo de Payload de Lista:**
```json
{
  "whatsapp": {
    "type": "interactive",
    "interactive": {
      "body": { "text": "Escolha uma opção:" },
      "type": "list",
      "action": {
        "button": "Ver opções",
        "sections": [
          {
            "title": "Serviços",
            "rows": [
              { "id": "opt1", "title": "Opção 1" },
              { "id": "opt2", "title": "Opção 2" }
            ]
          }
        ]
      }
    }
  }
}
```

### 1.3 Extração de Texto para Dashboard

```ruby
def extract_whatsapp_text(payload)
  # Tentar extrair texto de diferentes locais no payload
  payload.dig('interactive', 'body', 'text') ||
  payload.dig('text', 'body') ||
  payload['text'] ||
  'Mensagem interativa'
end
```

### 1.4 Criação da Mensagem no Banco

A mensagem é salva com:
- **content**: Texto extraído para exibição no dashboard
- **content_type**: `'integrations'` (indica que é uma mensagem de integração)
- **content_attributes**: Payload completo do WhatsApp para processamento

## 2. Envio para WhatsApp

### 2.1 Envio da Mensagem Interativa

```ruby
if is_interactive
  # Para mensagens interativas, usar o método send_interactive_payload
  contact_source_id = conversation.contact.get_source_id(conversation.inbox.id)
  channel = conversation.inbox.channel
  
  message_id = channel.provider_service.send_interactive_payload(
    contact_source_id, 
    outgoing_message, 
    whatsapp_payload['interactive']
  )
  
  outgoing_message.update!(source_id: message_id) if message_id.present?
else
  # Para mensagens de texto, usar o serviço padrão
  Whatsapp::SendOnWhatsappService.new(message: outgoing_message).perform
end
```

## 3. Exibição no Frontend (Vue.js)

### 3.1 Componente Principal de Mensagem

```vue
<!-- app/javascript/dashboard/components-next/message/Message.vue -->
<script setup>
const shouldRenderMessage = computed(() => {
  const isAnIntegrationMessage = props.contentType === CONTENT_TYPES.INTEGRATIONS;
  
  return (
    hasAttachments ||
    props.content ||
    isEmailContentType ||
    isUnsupported ||
    isAnIntegrationMessage  // Mensagens de integração são sempre renderizadas
  );
});

const componentToRender = computed(() => {
  // Para mensagens de integração WhatsApp, usa TextBubble como fallback
  // O TextBubble renderiza o texto extraído (content)
  return TextBubble;
});
</script>

<template>
  <Component :is="componentToRender" />
</template>
```

### 3.2 Renderização no TextBubble

```vue
<!-- app/javascript/dashboard/components-next/message/bubbles/Text/Index.vue -->
<script setup>
const { content, contentAttributes } = useMessageContext();

// O content contém o texto extraído do payload WhatsApp
// Os contentAttributes contêm o payload completo para referência
</script>

<template>
  <BaseBubble class="px-4 py-3">
    <FormattedContent :content="content" />
    <!-- Renderiza o texto extraído com formatação -->
  </BaseBubble>
</template>
```

### 3.3 Formatação do Conteúdo

```vue
<!-- app/javascript/dashboard/components-next/message/bubbles/Text/FormattedContent.vue -->
<script setup>
const formattedContent = computed(() => {
  return new MessageFormatter(props.content).formattedMessage;
});
</script>

<template>
  <span v-dompurify-html="formattedContent" class="prose prose-bubble" />
</template>
```

## 4. Fluxo Visual Completo

```
┌─────────────────────┐
│   SocialWise Flow   │
│   Retorna Payload   │
│   WhatsApp          │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ ProcessorService    │
│ - Extrai texto      │
│ - Identifica tipo   │
│ - Cria mensagem     │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Banco de Dados      │
│ content: "texto"    │
│ content_type:       │
│ "integrations"      │
│ content_attributes: │
│ {payload completo}  │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ WhatsApp API        │
│ Envia mensagem      │
│ interativa          │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Frontend Vue.js     │
│ - Message.vue       │
│ - TextBubble.vue    │
│ - FormattedContent  │
└─────────────────────┘
```

## 5. Exemplo Prático de Exibição

### 5.1 Payload Original
```json
{
  "whatsapp": {
    "type": "interactive",
    "interactive": {
      "body": {
        "text": "> Sr(a) *Cliente*, \nSomos especializados em mandado de segurança e podemos ajudá-lo."
      },
      "type": "button",
      "action": {
        "buttons": [
          {
            "type": "reply",
            "reply": {
              "id": "btn_123",
              "title": "Falar com Advogado"
            }
          }
        ]
      }
    }
  }
}
```

### 5.2 Mensagem Salva no Banco
```ruby
{
  id: 12345,
  content: "> Sr(a) *Cliente*, \nSomos especializados em mandado de segurança e podemos ajudá-lo.",
  content_type: "integrations",
  message_type: "outgoing",
  content_attributes: {
    "interactive" => {
      "body" => { "text" => "> Sr(a) *Cliente*..." },
      "type" => "button",
      "action" => { "buttons" => [...] }
    },
    "type" => "interactive",
    "whatsapp_interactive_payload" => {...}
  }
}
```

### 5.3 Exibição no Dashboard
O agente humano vê:
- **Bolha de mensagem** com o texto: "> Sr(a) *Cliente*, Somos especializados em mandado de segurança e podemos ajudá-lo."
- **Formatação** aplicada (negrito, quebras de linha)
- **Indicação visual** de que é uma mensagem de bot/integração

## 6. Vantagens desta Abordagem

### 6.1 Para o Agente Humano
- **Visibilidade**: Vê exatamente o que foi enviado ao cliente
- **Contexto**: Entende o conteúdo da mensagem interativa
- **Rastreamento**: Pode acompanhar o fluxo da conversa

### 6.2 Para o Sistema
- **Flexibilidade**: Suporta diferentes tipos de mensagens interativas
- **Compatibilidade**: Funciona com a estrutura existente do Chatwoot
- **Extensibilidade**: Pode ser expandido para outros tipos de conteúdo

### 6.3 Para Debugging
- **Payload Completo**: Armazenado em `content_attributes` para análise
- **Logs Detalhados**: Cada etapa é logada para troubleshooting
- **Fallback**: Se algo falha, ainda mostra o texto básico

## 7. Limitações Atuais

### 7.1 Renderização
- Atualmente usa `TextBubble` como fallback
- Não renderiza visualmente os botões/listas no dashboard
- Agente vê apenas o texto, não a estrutura interativa

### 7.2 Possíveis Melhorias Futuras
- Criar componente específico para WhatsApp interativo
- Renderizar botões/listas visualmente no dashboard
- Mostrar preview da mensagem interativa
- Indicar quando botões foram clicados pelo cliente

## 8. Considerações de Segurança

### 8.1 Sanitização
- Texto é processado pelo `MessageFormatter`
- HTML é sanitizado com `v-dompurify-html`
- Payload é validado antes do processamento

### 8.2 Validação
- Verifica estrutura do payload antes de processar
- Fallback para texto simples em caso de erro
- Logs detalhados para auditoria

Este fluxo garante que as mensagens ricas do WhatsApp sejam processadas corretamente, enviadas para o cliente e exibidas de forma compreensível para o agente humano no dashboard do Chatwoot.