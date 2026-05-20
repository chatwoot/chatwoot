# Socialwise Instagram quick replies fallback

Data: 2026-05-20

## Contexto

O Socialwise Flow pode responder ao Chatwit com mensagens ricas para Instagram/Facebook usando quick replies.
O formato canonico da plataforma e:

```json
{
  "instagram": {
    "message_format": "QUICK_REPLIES",
    "text": "Ola! Como posso ajudar?",
    "quick_replies": [
      { "content_type": "text", "title": "Opcao 1", "payload": "@opcao_1" }
    ]
  }
}
```

Para Facebook, a chave externa e `facebook` e o corpo e equivalente.

## Incidente corrigido

Em 2026-05-20, o router LLM da plataforma retornou um payload Instagram legado com `text` e `quick_replies`,
mas sem `message_format`. O Chatwit nao reconheceu a resposta como rich message, entrou no fallback e enviou
o placeholder interno `Mensagem rica do Instagram` para o lead.

## Comportamento atual

- `Integrations::SocialwiseFlow::ProcessorService` infere `QUICK_REPLIES` quando recebe `text` + `quick_replies`.
- O mesmo normalizador tambem infere `BUTTON_TEMPLATE` e `GENERIC_TEMPLATE` quando o payload possui `buttons`,
  `template_type` ou `elements`.
- O fallback de Instagram extrai texto de formatos diretos, `payload`, `instagram` wrapper e payloads nested
  do Messenger antes de usar uma mensagem generica.
- O placeholder interno `Mensagem rica do Instagram` nao deve ser enviado ao lead.

## Arquivos

- `lib/integrations/socialwise_flow/processor_service.rb`
- `lib/integrations/socialwise/instagram_response_processor.rb`
- `app/services/instagram/rich_message_service.rb`
- `app/services/messages/instagram_renderer_mapper.rb`

