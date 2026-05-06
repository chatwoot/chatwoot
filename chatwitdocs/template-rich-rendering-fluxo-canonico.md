# Fluxo Canônico — Template / Interactive WhatsApp Rich Rendering

> **Objetivo:** garantir que toda mensagem rica (template oficial WhatsApp ou interactive) chegue ao dashboard renderizada **igual ao padrão SocialWise** (header de imagem/documento/vídeo + body + footer + botões), evitando que ela caia na bolha-fallback genérica que mostra apenas `Mensagem Interativa do WhatsApp / Interactive message content`.
>
> Este documento é a **fonte de verdade do contrato visual**. Qualquer produtor de mensagem (Socialwise Flow, JusMonitorIA, Agent Bot async, qualquer integração futura) **deve** respeitar a forma exata aqui descrita, sob pena de cair no fallback.

---

## 1. Onde acontece a decisão de renderização

### 1.1. Roteador de bubble (frontend)

**Arquivo:** [`app/javascript/dashboard/components-next/message/Message.vue`](../app/javascript/dashboard/components-next/message/Message.vue#L288-L341)

Trecho decisivo (`componentToRender`, linhas 320-333):

```js
// SocialWise/Chatwit: WhatsApp Interactive messages (buttons, lists, templates)
if (props.contentType === CONTENT_TYPES.INTEGRATIONS) {
  if (
    props.contentAttributes?.whatsapp_interactive_payload ||
    props.contentAttributes?.interactive ||
    props.contentAttributes?.whatsapp_template_payload ||
    props.contentAttributes?.template
  ) {
    return WhatsAppInteractiveBubble;
  }
  return TextBubble; // <- queda silenciosa
}
```

**Regra obrigatória nº 1 — content_type:**
A Message **PRECISA** ter `content_type = 'integrations'`. Qualquer outro valor (`text`, `template` legacy, `cards`) **NÃO** dispara o `WhatsAppInteractiveBubble`.

**Regra obrigatória nº 2 — chave de payload:**
O `content_attributes` **PRECISA** conter pelo menos uma destas chaves:

| Chave                          | Quando usar                                   |
| ------------------------------ | --------------------------------------------- |
| `whatsapp_interactive_payload` | Mensagem interativa (button/list/cta_url)     |
| `interactive`                  | Alias aceito (fallback)                       |
| `whatsapp_template_payload`    | Template oficial aprovado pela Meta           |
| `template`                     | Alias aceito (fallback)                       |

A presença das duas (`template` + `whatsapp_template_payload` apontando para o **mesmo** payload) é o padrão que o SocialWise Flow grava — recomendado.

### 1.2. Renderizador da bolha rica

**Arquivo:** [`app/javascript/dashboard/components-next/message/bubbles/WhatsAppInteractive.vue`](../app/javascript/dashboard/components-next/message/bubbles/WhatsAppInteractive.vue)

A bolha só renderiza rica quando `shouldRenderInteractive === true` (linhas 169-176):

```js
const shouldRenderInteractive = computed(() => {
  return (
    interactivePayload.value &&
    Object.keys(interactivePayload.value).length > 0 &&
    (isButtonTemplate.value || isListTemplate.value || isCtaUrlTemplate.value)
  );
});
```

Se cair fora dessa condição, o template `v-else` (linhas 362-380) renderiza:

```
"WhatsApp Interactive Message"
"Interactive message content"
```

**Esse é exatamente o estado da foto 1.** Toda vez que aparecer essa bolha vazia, é porque uma das três condições falhou:

1. `interactivePayload` ficou `{}` → o normalizador não conseguiu extrair nada do `content_attributes`.
2. O `type` resultante não é `button`, `list` ou `cta_url`.
3. O `content_attributes` não foi entregue (ex.: foi salvo direto em `additional_attributes` por engano, ou o processor escreveu em `template_params` em vez de `whatsapp_template_payload`).

---

## 2. Backend — como o SocialWise Flow grava a Message (referência canônica)

**Arquivo:** [`lib/integrations/socialwise_flow/whatsapp_response_processor.rb`](../lib/integrations/socialwise_flow/whatsapp_response_processor.rb)

### 2.1. Template oficial (foto 2 = renderização correta)

Trecho `send_template_message` (linhas 304-319):

```ruby
outgoing_message = conversation.messages.create!(
  message_type: :outgoing,
  content: text_content,                         # texto plano para inbox lists
  content_type: 'integrations',                  # OBRIGATÓRIO
  content_attributes: {
    'template' => template_payload,              # alias
    'type' => 'template',
    'whatsapp_template_payload' => template_payload   # CHAVE QUE A BOLHA CONSOME
  },
  account_id: conversation.account_id,
  inbox_id: conversation.inbox_id,
  additional_attributes: { skip_send_reply: true }
)
```

### 2.2. Mensagem interactive (button/list/cta_url)

Trecho `send_interactive_message` (linhas 118-130):

```ruby
outgoing_message = conversation.messages.create!(
  message_type: :outgoing,
  content: text_content,
  content_type: 'integrations',
  content_attributes: {
    'interactive' => interactive_payload,
    'type' => whatsapp_data['type'],
    'whatsapp_interactive_payload' => interactive_payload
  },
  ...
)
```

> **Padrão a copiar:** qualquer integração nova (JusMonitorIA, Agent Bot async, cron de notificação) **deve replicar exatamente este shape** ao gravar a Message no Chatwit. Não inventar novas chaves.

---

## 3. Estrutura **exata** do `whatsapp_template_payload`

Esta é a forma canônica que o `WhatsAppInteractive.vue::normalizeTemplateToInteractive()` (linhas 13-84) sabe ler. Sair dessa forma = cair no fallback.

```json
{
  "name": "alerta_movimentacao_processual_v2",
  "language": { "code": "pt_BR" },
  "components": [
    {
      "type": "header",
      "parameters": [
        {
          "type": "image",
          "image": {
            "link": "https://cdn.exemplo.com/banner.jpg"
          }
        }
      ]
    },
    {
      "type": "body",
      "parameters": [
        { "type": "text", "text": "Sr(a) Witalo," },
        { "type": "text", "text": "processo 0001234-56" }
      ]
    },
    {
      "type": "footer",
      "parameters": [
        { "type": "text", "text": "Dra. Amanda Sousa Advocacia" }
      ]
    },
    {
      "type": "button",
      "parameters": [
        { "type": "text", "text": "Falar com a Dra" }
      ]
    },
    {
      "type": "button",
      "parameters": [
        { "type": "text", "text": "Tenho Direito?" }
      ]
    },
    {
      "type": "button",
      "parameters": [
        { "type": "text", "text": "Finalizar" }
      ]
    }
  ]
}
```

### 3.1. Variantes de header aceitas pelo normalizador

| `parameters[0].type` | Renderiza como                                               |
| -------------------- | ------------------------------------------------------------ |
| `image`              | `<img :src="parameters[0].image.link" />` — banner topo      |
| `text`               | `<div class="whatsapp-header">…</div>` — título em negrito   |
| `document` / `video` | **Hoje cai no fallback.** Não há suporte visual; preferir `image` para o dashboard, mesmo que o envio à Meta use document/video. |

> **Aviso:** o que vai para a Meta API e o que é gravado em `whatsapp_template_payload` para o dashboard **podem ser estruturas distintas**. Garanta que a versão do payload destinada ao dashboard sempre tenha `header.type=image` (com `link`) ou `header.type=text` para que o usuário veja a bolha igual à foto 2. Caso contrário, envia para a Meta normalmente, mas espelha um payload simplificado no `content_attributes`.

### 3.2. Body — duas formas aceitas

O normalizador (linhas 45-51) faz:

```js
case 'BODY':
  if (component.parameters?.length > 0) {
    const bodyParts = component.parameters.map(p => p.text || '');
    result.body.text = bodyParts.join(' ');
  }
```

- **Se** `parameters[]` tiver textos prontos (variáveis já resolvidas pelo backend), o body aparece concatenado.
- **Se não** houver `parameters`, cai em `result.body.text = "Template: ${name}"` — o que é **subótimo**: o usuário vê só o nome técnico do template.

Para a UX da foto 2 sair limpa, **o backend deve resolver as variáveis ANTES de gravar a Message** e mandar o texto final em `parameters[].text` ou diretamente como `body.text` no shape interactive.

### 3.3. Footer — sempre com `parameters[0].text`

```js
case 'FOOTER':
  if (component.parameters?.[0]?.text) {
    result.footer.text = component.parameters[0].text;
  }
```

O footer **só aparece** se vier dentro de `parameters[0].text`. Mandar como string solta no objeto não funciona.

### 3.4. Botões — `type: BUTTON` + `parameters[0].text`

O normalizador (linhas 59-71) só consegue ler:

```json
{ "type": "button", "parameters": [{ "type": "text", "text": "Rótulo do botão" }] }
```

Cada componente `button` vira **um botão** na bolha (o normalizador faz `result.action.buttons.push(...)` e o template marca `type: 'button'`). Isso ativa `isButtonTemplate.value === true` → renderiza a coluna vertical de botões da foto 2.

> **Não use** `type: "BUTTONS"` (plural) nem aninhe vários botões em `parameters[]` do mesmo componente — o normalizador trata cada componente como um botão único.

---

## 4. Estrutura **exata** do `whatsapp_interactive_payload`

Para mensagens **não-template** (interactive button/list/cta_url criadas dinamicamente):

```json
{
  "type": "button",
  "header": {
    "type": "image",
    "image": { "link": "https://cdn.exemplo.com/foto.jpg" }
  },
  "body":   { "text": "Escolha uma opção:" },
  "footer": { "text": "Atendimento Witdev" },
  "action": {
    "buttons": [
      { "type": "reply", "reply": { "id": "btn_1", "title": "Opção 1" } },
      { "type": "reply", "reply": { "id": "btn_2", "title": "Opção 2" } }
    ]
  }
}
```

Variantes:

- `type: "list"` → use `action.button` (texto do botão de abrir lista) + `action.sections[].rows[]`
- `type: "cta_url"` → use `action.parameters` com `display_text` + `url`

Qualquer outro valor de `type` cai no fallback (`shouldRenderInteractive === false`).

---

## 5. Contrato com a plataforma (Witdev Platform Core)

Fonte de verdade: [`witdev-platform-core/docs/contrato-plataforma-unificada.md`](/home/wital/witdev-platform-core/docs/contrato-plataforma-unificada.md)

A plataforma envia ao Chatwit (sync 30s ou async via Agent Bot) sob duas formas que o Chatwit aceita:

### 5.1. Forma A — `whatsapp` block (preferida pelo SocialWise Flow)

```json
{
  "whatsapp": {
    "type": "template",
    "template": {
      "name": "...",
      "language": { "code": "pt_BR" },
      "components": [ ... ]
    }
  }
}
```

Roteado por `WhatsappResponseProcessor.route_message()` linhas 63-89.

### 5.2. Forma B — `template_params` (compatibilidade upstream)

```json
{
  "content": "[Template: alerta_movimentacao_processual_v2]",
  "message_type": "outgoing",
  "template_params": {
    "name": "alerta_movimentacao_processual_v2",
    "language": "pt_BR",
    "processed_params": { "body": { "nome_lead": "Witalo" } }
  }
}
```

Roteado pelo `TemplateProcessorService` nativo do Chatwoot, que monta os components antes de chamar `channel.send_template()`.

> **Importante:** se o produtor (JusMonitorIA, automação async) optar pela **forma B**, ele depende do `TemplateProcessorService` montar o `whatsapp_template_payload` correto no `content_attributes` antes da Message ser gravada — caso contrário a bolha vai cair no fallback. **Para máxima previsibilidade visual, prefira a forma A** (envia o `components[]` já formatado) e replique-o em `content_attributes.whatsapp_template_payload`.

---

## 6. Checklist canônico (antes de fazer deploy de qualquer integração que envia template/rich)

Marque tudo antes de subir:

- [ ] A Message é criada com `content_type: 'integrations'` (não `text`, não `template`).
- [ ] `content_attributes` contém `whatsapp_template_payload` **OU** `whatsapp_interactive_payload` com a forma exata da seção 3 ou 4.
- [ ] Para template: existe **pelo menos** um component `body` com texto resolvido (variáveis já substituídas).
- [ ] Header é `image` com `link` HTTPS público acessível (CDN/storage do Chatwit, não localhost).
- [ ] Footer chega em `parameters[0].text` (não como string solta).
- [ ] Cada botão é um `component` separado com `type: "button"` e `parameters[0].text` no rótulo.
- [ ] `content` (texto plano) tem fallback amigável (ex.: `"[Template: nome]"` ou o body resolvido) — usado em listas de inbox e notificações nativas que não renderizam HTML.
- [ ] No log, ao receber a resposta, vejo no Rails: `[SOCIALWISE-FLOW-WHATSAPP] Template message created in dashboard: <id>` (ou equivalente para a integração nova).
- [ ] No browser, abrindo a conversa, a bolha mostra **header → body → botões → footer** como na foto 2 (referência: print 2026-05-03 do template `alerta_movimentacao_processual_v2`).

Se algum item falhar, a bolha cai no fallback de foto 1.

---

## 7. Diagnóstico — quando a bolha aparece "vazia" como na foto 1

Em ordem de probabilidade:

1. **`content_type` errado.** Inspecione no Rails console:
   ```ruby
   Message.find(<id>).content_type   # deve ser "integrations"
   ```
2. **Chave de payload faltando.** O `content_attributes` precisa ter `whatsapp_template_payload` ou `whatsapp_interactive_payload`. `template_params` sozinho **não** ativa a bolha rica — o `TemplateProcessorService` precisa ter rodado e populado a chave canônica.
3. **`type` desconhecido após normalização.** Em dev, abra o `<details>` "Debug Info" da bolha de fallback (linhas 381-400 do componente) — ele mostra o JSON com `interactiveType` resolvido. Se vier `unknown`, o `components[]` não tem nenhuma forma reconhecível, ou o interactive não tem `type` no topo.
4. **`components[].type` em case errado.** O normalizador faz `.toUpperCase()` (linha 28), então `header`/`HEADER`/`Header` funcionam — mas confira que o atributo se chama exatamente `type` e que `parameters` é um array.
5. **Imagem do header com URL inacessível.** O `<img @error="$event.target.style.display='none'">` esconde a imagem em silêncio (linha 251), deixando o body órfão. Verifique se o link do `header.image.link` está público e responde 200.

---

## 8. Referências cruzadas

- Doc da Etapa 2 (rich messages rendering): [`chatwitdocs/migration-etapa2.md`](./migration-etapa2.md)
- Doc da Etapa 1 (SocialWise Flow): [`chatwitdocs/migration-etapa1.md`](./migration-etapa1.md)
- Contrato unificado plataforma↔Chatwit: [`witdev-platform-core/docs/contrato-plataforma-unificada.md`](/home/wital/witdev-platform-core/docs/contrato-plataforma-unificada.md)
- Mapper backend: [`app/services/messages/whatsapp_renderer_mapper.rb`](../app/services/messages/whatsapp_renderer_mapper.rb)
- Processor: [`lib/integrations/socialwise_flow/whatsapp_response_processor.rb`](../lib/integrations/socialwise_flow/whatsapp_response_processor.rb)
- Bubble Vue: [`app/javascript/dashboard/components-next/message/bubbles/WhatsAppInteractive.vue`](../app/javascript/dashboard/components-next/message/bubbles/WhatsAppInteractive.vue)
- Roteador Vue: [`app/javascript/dashboard/components-next/message/Message.vue`](../app/javascript/dashboard/components-next/message/Message.vue)
