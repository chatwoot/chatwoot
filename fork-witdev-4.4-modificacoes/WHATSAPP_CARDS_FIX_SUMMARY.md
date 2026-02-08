# Correção das Mensagens Ricas do WhatsApp - SocialWise Flow

## Problema Identificado

Sua análise estava **100% correta**! O problema era que:

1. **Back-end funcionando**: O SocialWise Flow criava mensagens com `content_type: 'integrations'`
2. **Front-end com problema**: O Vue.js renderizava essas mensagens usando `WhatsAppInteractive.vue` ao invés de `RichCards.vue`
3. **Resultado**: As mensagens apareciam momentaneamente e depois "sumiam" porque não eram renderizadas como cards visuais

## Solução Implementada

### 1. Detecção Inteligente de Tipo de Renderização

Adicionado método `should_use_cards_rendering?()` que determina quando uma mensagem interativa do WhatsApp deve ser renderizada como cards:

**Critérios para usar cards:**
- ✅ Mensagem tem header com imagem
- ✅ É template de botão com múltiplos botões (mais visual)

### 2. Conversão de Formato

Adicionado método `convert_whatsapp_to_cards_format()` que converte o payload do WhatsApp Interactive para o formato esperado pelo `RichCards.vue`:

```ruby
# Antes (WhatsApp Interactive format)
{
  "type" => "interactive",
  "interactive" => {
    "header" => { "type" => "image", "image" => { "link" => "..." } },
    "body" => { "text" => "Título" },
    "footer" => { "text" => "Descrição" },
    "action" => { "buttons" => [...] }
  }
}

# Depois (Cards format)
{
  "items" => [{
    "title" => "Título",
    "description" => "Descrição", 
    "media_url" => "...",
    "actions" => [
      { "type" => "postback", "text" => "Botão 1", "payload" => "btn_1" }
    ]
  }]
}
```

### 3. Lógica de Content Type

Agora o processador decide dinamicamente o `content_type`:

- **`content_type: 'cards'`** → Renderiza `RichCards.vue` (visual, com imagem)
- **`content_type: 'integrations'`** → Renderiza `WhatsAppInteractive.vue` (simples)
- **`content_type: 'text'`** → Renderiza `TextBubble.vue` (texto puro)

## Arquivos Modificados

### `lib/integrations/socialwise_flow/processor_service.rb`

1. **Método `should_use_cards_rendering?()`**: Detecta quando usar cards
2. **Método `convert_whatsapp_to_cards_format()`**: Converte formato
3. **Lógica de criação de mensagem**: Decide content_type dinamicamente
4. **Logs aprimorados**: Rastreamento completo do processo

## Como Testar

### 1. Teste da Lógica
```bash
ruby test_cards_logic.rb
```

### 2. Validação em Produção
```bash
rails runner validate_whatsapp_cards_fix.rb
```

### 3. Monitoramento de Logs
```bash
tail -f log/development.log | grep "Should render as cards"
```

## Resultado Esperado

### Antes da Correção
- Mensagem aparece momentaneamente
- Renderizada como `WhatsAppInteractive.vue`
- "Some" porque não é visualmente atrativa
- `content_type: 'integrations'`

### Depois da Correção
- Mensagem permanece visível
- Renderizada como `RichCards.vue` (quando tem imagem/múltiplos botões)
- Visual atrativo com cards
- `content_type: 'cards'`

## Logs de Monitoramento

Procure por estes logs para confirmar que está funcionando:

```
[SOCIALWISE-FLOW][WHATSAPP] Should render as cards: true
[SOCIALWISE-FLOW][WHATSAPP] Cards rendering criteria: image_header=true, button_template=true, multiple_buttons=true, result=true
[SOCIALWISE-FLOW][WHATSAPP] Converted to cards format: {...}
[SOCIALWISE-FLOW][WHATSAPP] Message created successfully: 12345 (content_type: cards)
```

## Compatibilidade

- ✅ Mantém compatibilidade com mensagens existentes
- ✅ Não quebra mensagens simples (continuam como `integrations`)
- ✅ Preserva funcionalidade de envio para WhatsApp
- ✅ Logs detalhados para debugging

## Próximos Passos

1. **Teste**: Envie uma mensagem rica do SocialWise Flow
2. **Verifique**: Confirme que aparece como cards no dashboard
3. **Monitore**: Acompanhe os logs para validar o comportamento
4. **Ajuste**: Se necessário, modifique os critérios em `should_use_cards_rendering?()`