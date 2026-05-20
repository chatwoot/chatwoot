# Socialwise Meta rich message contract

Data: 2026-05-20

## Contexto

O Socialwise Flow pode responder ao Chatwit com mensagens ricas para Instagram/Facebook usando quick replies,
button templates e generic templates. O contrato atual e structure-first: `message_format` pode existir, mas e
apenas uma dica legada. O Chatwit deve decidir o tipo real pela estrutura do payload.

Exemplo recomendado de quick replies:

```json
{
  "instagram": {
    "text": "Ola! Como posso ajudar?",
    "quick_replies": [
      { "content_type": "text", "title": "Opcao 1", "payload": "@opcao_1" }
    ]
  }
}
```

Para Facebook, a chave externa e `facebook` e o corpo e equivalente.

## Regra structure-first

O Chatwit deve inferir o tipo efetivo nesta ordem:

| Estrutura presente | Tipo efetivo |
|--------------------|--------------|
| `template_type: "generic"` ou `elements` | `GENERIC_TEMPLATE` |
| `template_type: "button"` ou `buttons` | `BUTTON_TEMPLATE` |
| `quick_replies` | `QUICK_REPLIES` |

`message_format` so entra como fallback quando a estrutura nao permite inferir o tipo. Se `message_format` disser
`QUICK_REPLIES`, mas o payload tiver `template_type: "button"` ou `buttons`, o Chatwit deve tratar como
`BUTTON_TEMPLATE`.

## Incidente corrigido

Em 2026-05-20, o router LLM da plataforma retornou um payload Instagram legado com `text` e `quick_replies`,
mas sem `message_format`. O Chatwit nao reconheceu a resposta como rich message, entrou no fallback e enviou
o placeholder interno `Mensagem rica do Instagram` para o lead.

## Comportamento atual

- `Integrations::SocialwiseFlow::ProcessorService` infere `QUICK_REPLIES` quando recebe `text` + `quick_replies`.
- O mesmo normalizador tambem infere `BUTTON_TEMPLATE` e `GENERIC_TEMPLATE` quando o payload possui `buttons`,
  `template_type` ou `elements`.
- Quando `message_format` diverge da estrutura, a estrutura vence para Instagram e Facebook.
- O fallback de Instagram extrai texto de formatos diretos, `payload`, `instagram` wrapper e payloads nested
  do Messenger antes de usar uma mensagem generica.
- O placeholder interno `Mensagem rica do Instagram` nao deve ser enviado ao lead.

## Arquivos

- `lib/integrations/socialwise_flow/processor_service.rb`
- `lib/integrations/socialwise/instagram_response_processor.rb`
- `app/services/instagram/rich_message_service.rb`
- `app/services/messages/instagram_renderer_mapper.rb`
