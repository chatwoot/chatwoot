# Migration Etapa 2 - Rich Messages Rendering (WhatsApp & Instagram)

**Data:** 2026-02-01
**Versão Base:** Chatwoot 4.10.1
**Objetivo:** Renderização visual de mensagens ricas (templates, botões, imagens) no dashboard

---

## Resumo da Etapa 2

Esta etapa implementa a **renderização visual de mensagens ricas** no dashboard do Chatwoot, permitindo que templates de WhatsApp (com imagem de cabeçalho, botões) e mensagens interativas do Instagram/Facebook sejam exibidos corretamente na interface.

### Problema Resolvido

Antes desta etapa, mensagens ricas (templates com imagem, botões interativos) eram exibidas apenas como texto plano, perdendo toda a formatação visual.

**Antes:**
```
Olá! 😊
Clique no botão abaixo 👇 para copiar automaticamente a chave PIX...
```

**Depois:**
- Imagem de cabeçalho visível
- Texto do corpo formatado
- Botões clicáveis renderizados
- Footer com informações adicionais

---

## Escopo Realizado

- [x] Componente Vue para mensagens interativas WhatsApp (`WhatsAppInteractive.vue`)
- [x] Componente Vue para Rich Cards Instagram/Facebook (`RichCards.vue`)
- [x] Service mapper para WhatsApp (`WhatsappRendererMapper.rb`)
- [x] Roteamento de content_type `integrations` e `cards` no `Message.vue`
- [x] Suporte a templates com imagem de cabeçalho
- [x] Suporte a botões (reply, postback, URL, copy_code)
- [x] Suporte a listas interativas
- [x] Traduções pt_BR e en

---

## Arquivos Criados

### Componentes Vue (Frontend)

| Arquivo | Descrição |
|---------|-----------|
| `app/javascript/dashboard/components-next/message/bubbles/WhatsAppInteractive.vue` | Renderiza mensagens interativas do WhatsApp (botões, listas, templates) |
| `app/javascript/dashboard/components-next/message/bubbles/RichCards.vue` | Renderiza cards ricos para Instagram/Facebook (carrosséis, quick replies) |

### Services Ruby (Backend)

| Arquivo | Descrição |
|---------|-----------|
| `app/services/messages/whatsapp_renderer_mapper.rb` | Mapeia payloads WhatsApp para estrutura do Chatwoot |

---

## Arquivos Modificados

### 1. Message.vue
**Caminho:** `app/javascript/dashboard/components-next/message/Message.vue`

**Alterações:**
- Importação dos novos componentes bubble
- Roteamento de `content_type: 'integrations'` para `WhatsAppInteractiveBubble`
- Roteamento de `content_type: 'cards'` para `RichCardsBubble`

```javascript
// Imports adicionados
import WhatsAppInteractiveBubble from './bubbles/WhatsAppInteractive.vue';
import RichCardsBubble from './bubbles/RichCards.vue';

// Roteamento no componentToRender
if (props.contentType === CONTENT_TYPES.INTEGRATIONS) {
  if (
    props.contentAttributes?.whatsapp_interactive_payload ||
    props.contentAttributes?.interactive ||
    props.contentAttributes?.whatsapp_template_payload ||
    props.contentAttributes?.template
  ) {
    return WhatsAppInteractiveBubble;
  }
  return TextBubble;
}

if (props.contentType === CONTENT_TYPES.CARDS) {
  if (props.contentAttributes?.items?.length > 0) {
    return RichCardsBubble;
  }
  return TextBubble;
}
```

### 2. busEvents.js
**Caminho:** `app/javascript/shared/constants/busEvents.js`

**Alterações:** Adicionados eventos para rich messages

```javascript
// Rich message events (SocialWise/Chatwit)
RICH_POSTBACK: 'RICH_POSTBACK',
RICH_CARDS_FALLBACK: 'RICH_CARDS_FALLBACK',
```

### 3. conversation.json (en)
**Caminho:** `app/javascript/dashboard/i18n/locale/en/conversation.json`

**Alterações:** Traduções para componentes de mensagens ricas

```json
"WHATSAPP_INTERACTIVE_MESSAGE": "WhatsApp Interactive Message",
"WHATSAPP_INTERACTIVE_IMAGE": "WhatsApp Header Image",
"WHATSAPP_INTERACTIVE_FALLBACK_TITLE": "WhatsApp Interactive Message",
"RICH_MESSAGE": {
  "RICH_MESSAGE_FALLBACK_TITLE": "Rich Message",
  "DEBUG_INFO": "Debug Info"
}
```

### 4. conversation.json (pt_BR)
**Caminho:** `app/javascript/dashboard/i18n/locale/pt_BR/conversation.json`

**Alterações:** Traduções em português

```json
"WHATSAPP_INTERACTIVE_MESSAGE": "Mensagem Interativa do WhatsApp",
"WHATSAPP_INTERACTIVE_IMAGE": "Imagem de Cabeçalho do WhatsApp",
"WHATSAPP_INTERACTIVE_FALLBACK_TITLE": "Mensagem Interativa do WhatsApp",
"RICH_MESSAGE": {
  "RICH_MESSAGE_FALLBACK_TITLE": "Mensagem Rica",
  "DEBUG_INFO": "Informações de Debug"
}
```

---

## Estrutura de Dados

### WhatsApp Interactive Payload

O componente `WhatsAppInteractive.vue` espera o seguinte formato em `content_attributes`:

```javascript
{
  "whatsapp_interactive_payload": {
    "type": "button",  // ou "list"
    "header": {
      "type": "image",
      "image": { "link": "https://..." }
    },
    "body": {
      "text": "Texto do corpo da mensagem"
    },
    "footer": {
      "text": "Texto do rodapé"
    },
    "action": {
      "buttons": [
        {
          "type": "reply",
          "reply": { "title": "Texto do Botão" }
        }
      ]
    }
  }
}
```

### WhatsApp Template Payload

Para templates (enviados via SocialWise Flow), o componente normaliza automaticamente:

```javascript
{
  "whatsapp_template_payload": {
    "name": "template_name",
    "language": { "code": "pt_BR" },
    "components": [
      {
        "type": "HEADER",
        "parameters": [
          { "type": "image", "image": { "link": "https://..." } }
        ]
      },
      {
        "type": "BODY",
        "parameters": [
          { "type": "text", "text": "Valor 1" }
        ]
      },
      {
        "type": "BUTTON",
        "parameters": [
          { "type": "coupon_code", "coupon_code": "PIX123" }
        ]
      }
    ]
  }
}
```

### Instagram/Facebook Cards Payload

O componente `RichCards.vue` espera:

```javascript
{
  "items": [
    {
      "title": "Título do Card",
      "description": "Descrição opcional",
      "media_url": "https://...",
      "actions": [
        {
          "type": "link",
          "text": "Abrir Link",
          "uri": "https://..."
        },
        {
          "type": "postback",
          "text": "Selecionar",
          "payload": "PAYLOAD_VALUE"
        }
      ]
    }
  ]
}
```

---

## Fluxo de Renderização

```
┌─────────────────────────────────────────────────────────────────┐
│                    MENSAGEM RECEBIDA/ENVIADA                    │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Message.vue                              │
│                   (componentToRender computed)                  │
└─────────────────────────────────────────────────────────────────┘
                                │
            ┌───────────────────┼───────────────────┐
            ▼                   ▼                   ▼
┌───────────────────┐ ┌───────────────────┐ ┌───────────────────┐
│  content_type:    │ │  content_type:    │ │  content_type:    │
│  'integrations'   │ │    'cards'        │ │     'text'        │
└───────────────────┘ └───────────────────┘ └───────────────────┘
            │                   │                   │
            ▼                   ▼                   ▼
┌───────────────────┐ ┌───────────────────┐ ┌───────────────────┐
│ WhatsAppInterac-  │ │   RichCards       │ │    TextBubble     │
│ tive.vue          │ │   Bubble.vue      │ │                   │
└───────────────────┘ └───────────────────┘ └───────────────────┘
            │                   │
            ▼                   ▼
┌───────────────────┐ ┌───────────────────┐
│ - Header Image    │ │ - Card Images     │
│ - Body Text       │ │ - Titles          │
│ - Buttons         │ │ - Descriptions    │
│ - Lists           │ │ - Action Buttons  │
│ - Footer          │ │ - Quick Replies   │
└───────────────────┘ └───────────────────┘
```

---

## Tipos de Mensagens Suportadas

### WhatsApp

| Tipo | Descrição | Componente |
|------|-----------|------------|
| `button` | Mensagem com até 3 botões de resposta | WhatsAppInteractive |
| `list` | Mensagem com lista de opções (seções) | WhatsAppInteractive |
| `template` | Template aprovado pela Meta (com imagem/botões) | WhatsAppInteractive |

### Instagram/Facebook

| Tipo | Descrição | Componente |
|------|-----------|------------|
| `generic` | Carrossel de cards com imagem e botões | RichCards |
| `button` | Mensagem com botões | RichCards |
| `quick_replies` | Respostas rápidas horizontais | RichCards |

---

## Estrutura de Diretórios

```
app/javascript/dashboard/
├── components-next/
│   └── message/
│       ├── Message.vue                          # Roteamento principal
│       ├── bubbles/
│       │   ├── WhatsAppInteractive.vue          # [NOVO] Mensagens WhatsApp
│       │   ├── RichCards.vue                    # [NOVO] Cards Instagram/FB
│       │   ├── Text/
│       │   │   └── Index.vue                    # Fallback para texto
│       │   └── ...
│       └── constants.js                         # CONTENT_TYPES
├── i18n/
│   └── locale/
│       ├── en/
│       │   └── conversation.json                # [MODIFICADO] Traduções EN
│       └── pt_BR/
│           └── conversation.json                # [MODIFICADO] Traduções PT

app/services/
└── messages/
    ├── whatsapp_renderer_mapper.rb              # [NOVO] Mapper WhatsApp
    └── instagram_renderer_mapper.rb             # [EXISTENTE] Mapper Instagram

shared/
└── constants/
    └── busEvents.js                             # [MODIFICADO] Eventos
```

---

## Como Funciona a Integração com SocialWise Flow

1. **SocialWise Flow** envia resposta com payload rico (template/interativo)
2. **whatsapp_response_processor.rb** cria mensagem com:
   - `content_type: 'integrations'`
   - `content_attributes.whatsapp_interactive_payload` ou `whatsapp_template_payload`
3. **Message.vue** detecta o content_type e roteia para componente correto
4. **WhatsAppInteractive.vue** renderiza a mensagem visualmente

---

## Problemas Conhecidos e Soluções

### 1. Template não renderiza botões
**Causa:** Payload do template em formato diferente do esperado
**Solução:** O componente normaliza automaticamente o payload via `normalizeTemplateToInteractive()`

### 2. Imagem do header não aparece
**Causa:** URL da imagem inválida ou CORS bloqueando
**Solução:** Verificar se a URL é acessível publicamente

### 3. Mensagem cai no fallback (texto)
**Causa:** content_type não é 'integrations' ou falta payload
**Solução:** Verificar se o processor está criando a mensagem com content_type correto

### 4. Quick replies não aparecem horizontalmente
**Causa:** CSS não aplicado corretamente
**Solução:** Verificar se a classe `quick-replies-scroll` está sendo aplicada

---

## Testes Manuais

### Testar WhatsApp Interactive

1. Configure uma integração SocialWise Flow
2. Envie uma mensagem que acione um template com:
   - Imagem de cabeçalho
   - Texto no body
   - Botão de copiar código (PIX)
3. Verifique no dashboard se:
   - A imagem aparece
   - O texto está formatado
   - Os botões estão visíveis

### Testar Instagram Cards

1. Configure uma integração SocialWise Flow para Instagram
2. Envie uma mensagem que acione um template genérico
3. Verifique se os cards aparecem com:
   - Imagem
   - Título e descrição
   - Botões de ação

---

## Comandos Pós-Instalação

```bash
# 1. Instalar dependências
pnpm install

# 2. Rebuild assets
pnpm build

# 3. Rebuild Docker (se usando Docker)
./build-producao.sh

# 4. Reiniciar serviços
overmind restart
```

---

## Histórico de Alterações

### 2026-02-01 - Implementação Inicial
- Criado `WhatsAppInteractive.vue` para mensagens interativas
- Criado `RichCards.vue` para cards Instagram/Facebook
- Criado `WhatsappRendererMapper.rb` para mapeamento de payloads
- Atualizado `Message.vue` com roteamento para novos componentes
- Adicionadas traduções en e pt_BR
- Adicionados eventos `RICH_POSTBACK` e `RICH_CARDS_FALLBACK`

---

## Próximos Passos (Etapa 3)

1. **Stickers**
   - Rotas de stickers
   - Upload e envio
   - Renderização no dashboard

2. **UI/UX**
   - Melhorar estilos dos botões
   - Animações de hover
   - Dark mode para rich messages

3. **Métricas**
   - Tracking de cliques em botões
   - Analytics de engajamento

---

## Referência de Arquivos

| Arquivo | Tipo | Status |
|---------|------|--------|
| `bubbles/WhatsAppInteractive.vue` | Vue Component | CRIADO |
| `bubbles/RichCards.vue` | Vue Component | CRIADO |
| `messages/whatsapp_renderer_mapper.rb` | Ruby Service | CRIADO |
| `Message.vue` | Vue Component | MODIFICADO |
| `busEvents.js` | JS Constants | MODIFICADO |
| `en/conversation.json` | i18n | MODIFICADO |
| `pt_BR/conversation.json` | i18n | MODIFICADO |

---

## Contato

Para dúvidas ou problemas, abra uma issue no repositório ou entre em contato com a equipe de desenvolvimento.
