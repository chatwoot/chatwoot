# Implementação de Captura de Button ID e List ID do WhatsApp

## Problema Resolvido
O sistema agora captura e disponibiliza os IDs dos botões e listas das mensagens interativas do WhatsApp para automações no Dialogflow/Flowise.

## Fluxo Implementado

### 1. Captura no Webhook do WhatsApp
**Arquivo:** `app/services/whatsapp/incoming_message_base_service.rb`

Quando uma mensagem interativa é recebida do WhatsApp, o sistema agora:
- Detecta se é uma mensagem do tipo `interactive`
- Extrai dados de `button_reply` ou `list_reply`
- Armazena no `content_attributes` da mensagem

```ruby
def extract_interactive_data(message)
  return {} unless message[:type] == 'interactive'

  interactive_data = {}
  
  # Extract button reply data
  if message.dig(:interactive, :button_reply)
    button_reply = message[:interactive][:button_reply]
    interactive_data[:button_reply] = {
      id: button_reply[:id],
      title: button_reply[:title]
    }
    interactive_data[:interaction_type] = 'button_reply'
  end
  
  # Extract list reply data
  if message.dig(:interactive, :list_reply)
    list_reply = message[:interactive][:list_reply]
    interactive_data[:list_reply] = {
      id: list_reply[:id],
      title: list_reply[:title],
      description: list_reply[:description]
    }
    interactive_data[:interaction_type] = 'list_reply'
  end
  
  interactive_data
end
```

### 2. Processamento no Socialwise
**Arquivo:** `lib/integrations/socialwise/webhook_enhancer_service.rb`

O serviço Socialwise agora:
- Extrai dados interativos do `content_attributes` da mensagem
- Inclui no payload estruturado do webhook

```ruby
def extract_interactive_data_from_message(message)
  return {} unless message&.content_attributes.is_a?(Hash)
  
  interactive_data = {}
  content_attrs = message.content_attributes.with_indifferent_access
  
  # Extract button reply data
  if content_attrs[:button_reply]
    interactive_data['button_id'] = content_attrs[:button_reply][:id]
    interactive_data['button_title'] = content_attrs[:button_reply][:title]
    interactive_data['interaction_type'] = 'button_reply'
  end
  
  # Extract list reply data
  if content_attrs[:list_reply]
    interactive_data['list_id'] = content_attrs[:list_reply][:id]
    interactive_data['list_title'] = content_attrs[:list_reply][:title]
    interactive_data['list_description'] = content_attrs[:list_reply][:description]
    interactive_data['interaction_type'] = 'list_reply'
  end
  
  interactive_data
end
```

### 3. Disponibilização no Dialogflow
**Arquivo:** `lib/integrations/dialogflow/processor_service.rb`

O payload do Dialogflow agora inclui:
- `button_id`: ID do botão clicado
- `button_title`: Título do botão clicado
- `list_id`: ID da opção de lista selecionada
- `list_title`: Título da opção de lista
- `list_description`: Descrição da opção de lista
- `interaction_type`: Tipo de interação (`button_reply` ou `list_reply`)

## Estrutura do Payload Final

### Para Mensagem de Botão:
```json
{
  "wamid": "wamid.HBgNNTUyMTk5NjMyMjE5NRUCABIYIEJBOTVGQjE5NTYwNkI5NDYzNDA1MzQ2RDM4ODVGRTk4AA==",
  "whatsapp_api_key": "EAAGIBII4GXQBO2qgvJ2jdcUmgkdqBo5bUKEanJWmCLpcZAsq0Ovpm4JNlrNLeZAv3OYNrdCqqQBAHfEfPFD0FPnZAOQJURB9GKcbjXeDpa83XdAsa3i6fTr23lBFM2LwUZC23xXrZAnB8QjCCFZBxrxlBvzPj8LsejvUjz0C04Q8Jsl8nTGHUd4ZBRPc4NiHFnc",
  "phone_number_id": "123456789",
  "business_id": "987654321",
  "button_id": "btn_confirm_order",
  "button_title": "Confirmar Pedido",
  "interaction_type": "button_reply",
  "list_id": null,
  "list_title": null,
  "list_description": null,
  "contact_name": "- LM",
  "message_content": "Confirmar Pedido",
  // ... outros campos existentes
}
```

### Para Mensagem de Lista:
```json
{
  "wamid": "wamid.HBgNNTUyMTk5NjMyMjE5NRUCABIYIEJBOTVGQjE5NTYwNkI5NDYzNDA1MzQ2RDM4ODVGRTk4AA==",
  "whatsapp_api_key": "EAAGIBII4GXQBO2qgvJ2jdcUmgkdqBo5bUKEanJWmCLpcZAsq0Ovpm4JNlrNLeZAv3OYNrdCqqQBAHfEfPFD0FPnZAOQJURB9GKcbjXeDpa83XdAsa3i6fTr23lBFM2LwUZC23xXrZAnB8QjCCFZBxrxlBvzPj8LsejvUjz0C04Q8Jsl8nTGHUd4ZBRPc4NiHFnc",
  "phone_number_id": "123456789",
  "business_id": "987654321",
  "button_id": null,
  "button_title": null,
  "list_id": "pizza_margherita",
  "list_title": "Pizza Margherita",
  "list_description": "Pizza clássica com tomate e mussarela",
  "interaction_type": "list_reply",
  "contact_name": "- LM",
  "message_content": "Pizza Margherita",
  // ... outros campos existentes
}
```

## Exemplos de Uso no Flowise/Dialogflow

### 1. Detectar Clique em Botão Específico:
```javascript
// No Flowise, você pode acessar:
if (payload.button_id === 'btn_confirm_order') {
  // Processar confirmação do pedido
  return "Pedido confirmado! Obrigado.";
}
```

### 2. Processar Seleção de Lista:
```javascript
// No Flowise, você pode acessar:
if (payload.interaction_type === 'list_reply') {
  const selectedOption = payload.list_id;
  const selectedTitle = payload.list_title;
  
  switch(selectedOption) {
    case 'pizza_margherita':
      return `Você escolheu ${selectedTitle}. Adicionando ao carrinho...`;
    case 'pizza_pepperoni':
      return `Você escolheu ${selectedTitle}. Adicionando ao carrinho...`;
  }
}
```

### 3. Automação Baseada no Tipo de Interação:
```javascript
// Diferentes fluxos para diferentes tipos de interação
if (payload.interaction_type === 'button_reply') {
  // Fluxo para botões
  handleButtonInteraction(payload.button_id, payload.button_title);
} else if (payload.interaction_type === 'list_reply') {
  // Fluxo para listas
  handleListInteraction(payload.list_id, payload.list_title, payload.list_description);
}
```

## Compatibilidade

- ✅ Funciona com mensagens de texto normais (campos ficam `null`)
- ✅ Funciona com botões de resposta rápida
- ✅ Funciona com listas interativas
- ✅ Mantém compatibilidade com integrações existentes
- ✅ Logs detalhados para debugging
- ✅ Tratamento de erros gracioso

## Testes Implementados

- Captura correta de dados de botões
- Captura correta de dados de listas
- Validação de estrutura de dados
- Compatibilidade com mensagens não-interativas
- Integração com Socialwise e Dialogflow

## Resultado

Agora você pode criar automações sofisticadas no Flowise que respondem especificamente aos botões e opções de lista que os usuários clicam, permitindo fluxos de conversação muito mais dinâmicos e personalizados! 🚀