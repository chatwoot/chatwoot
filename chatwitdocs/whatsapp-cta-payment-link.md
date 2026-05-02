# WhatsApp CTA para Link de Pagamento

## Objetivo

Substituir o envio de URL bruta do InfinitePay por uma mensagem interativa WhatsApp do tipo `cta_url`, reaproveitando o pipeline de mensagens ricas já existente no Chatwit.

## Escopo implementado

- Catálogo reutilizável por conta de mensagens interativas WhatsApp.
- Builder inicial com suporte apenas a `cta_url`.
- Header com `text` ou `image`.
- Publicação de imagem do header no bucket público do Socialwise.
- Seleção do CTA salvo dentro do modal de link de pagamento.
- Fallback automático para texto puro quando não houver CTA selecionado ou quando a conversa não for WhatsApp.

## Fluxo

1. O agente abre o modal de templates WhatsApp.
2. O agente clica em `Criar mensagem interativa`.
3. O builder salva um payload normalizado de `cta_url` em `whatsapp_interactive_templates`.
4. Se o header for imagem, o arquivo é enviado primeiro para o upload nativo do Chatwit e depois republicado no bucket público do Socialwise.
5. No modal de link de pagamento, o agente escolhe uma CTA salva.
6. O backend gera o checkout URL da InfinitePay.
7. O serviço injeta esse URL no placeholder da CTA e também prefixa o body com o valor dinâmico do pagamento e a linha `Ref: ...` com a descrição digitada no modal.
8. O provider WhatsApp Cloud reaproveita `send_interactive_payload` para entregar o payload final.

## Persistência

Tabela nova: `whatsapp_interactive_templates`

Campos principais:

- `name`
- `template_type`
- `header_type`
- `header_text`
- `header_image_url`
- `body_text`
- `footer_text`
- `button_text`
- `url_placeholder`
- `payload`

O payload salvo permanece reutilizável porque a URL final do checkout só é injetada no momento do envio.

## Bucket público do Socialwise

O bucket privado do Chatwit não serve para header de mídia no WhatsApp Cloud API, porque a Meta precisa acessar uma URL pública.

Por isso o fluxo usa:

- `STORAGE_ACCESS_KEY_ID`
- `STORAGE_SECRET_ACCESS_KEY`
- `STORAGE_REGION`
- `STORAGE_ENDPOINT`
- `STORAGE_FORCE_PATH_STYLE`

e publica no bucket/config pública do Socialwise:

- `SOCIALWISE_PUBLIC_BUCKET_NAME` com default `socialwise`
- `SOCIALWISE_PUBLIC_BUCKET_URL` com default `https://objstoreapi.witdev.com.br/socialwise`
- `SOCIALWISE_PUBLIC_BUCKET_FOLDER` com default `whatsapp-cta`

## Fallbacks

- Sem template CTA selecionado: envia texto puro como antes.
- Conversa fora de `Channel::Whatsapp`: envia texto puro como antes.
- Falha ao montar payload CTA: loga warning e envia texto puro.

## Composição dinâmica da mensagem

- O modal não escolhe mais PIX ou cartão. Essa escolha acontece no checkout da InfinitePay.
- A CTA enviada no WhatsApp passa a começar com `Valor a pagar: R$ ...`.
- Logo abaixo, a CTA adiciona `Ref: ...` com a descrição informada pelo agente.
- Na requisição da InfinitePay, a descrição interna do item inclui a descrição digitada e, quando disponíveis, nome e telefone do contato para facilitar conciliação.

## Arquivos novos

- `app/controllers/api/v1/accounts/whatsapp_interactive_templates_controller.rb`
- `app/models/whatsapp_interactive_template.rb`
- `app/policies/whatsapp_interactive_template_policy.rb`
- `app/services/whatsapp/interactive_template_payload_builder.rb`
- `app/services/whatsapp/interactive_header_publisher_service.rb`
- `app/javascript/dashboard/api/whatsappInteractiveTemplates.js`
- `app/javascript/dashboard/store/modules/whatsappInteractiveTemplates.js`
- `app/javascript/dashboard/components/widgets/conversation/WhatsappTemplates/InteractiveMessageCreator.vue`
- `db/migrate/20260314000100_create_whatsapp_interactive_templates.rb`
- `chatwitdocs/whatsapp-cta-payment-link.md`

## Arquivos alterados

- `app/models/account.rb`
- `config/routes.rb`
- `app/controllers/api/v1/accounts/payment_links_controller.rb`
- `lib/integrations/infinitepay/create_link_service.rb`
- `app/services/messages/whatsapp_renderer_mapper.rb`
- `app/javascript/dashboard/store/index.js`
- `app/javascript/dashboard/store/mutation-types.js`
- `app/javascript/dashboard/components/widgets/conversation/WhatsappTemplates/Modal.vue`
- `app/javascript/dashboard/components/widgets/conversation/PaymentLink/Modal.vue`
- `app/javascript/dashboard/components-next/message/bubbles/WhatsAppInteractive.vue`
- `app/javascript/dashboard/i18n/locale/en/paymentLink.json`
- `app/javascript/dashboard/i18n/locale/en/whatsappTemplates.json`
- `db/schema.rb`

## Observações para upstream

- O envio interativo foi encaixado sem alterar o pipeline nativo de templates oficiais.
- O fluxo de InfinitePay continua funcionando sem CTA selecionada.
- A renderização do dashboard foi estendida para `cta_url` sem mexer no suporte existente a `button` e `list`.

## Correção 2026-05-02 — envio direto e picker

- O endpoint `dispatch_to_conversation` agora tem permissão explícita em `WhatsappInteractiveTemplatePolicy`; antes o Pundit levantava `NoMethodError` e a API respondia 500 ao clicar para enviar uma mensagem interativa salva.
- O modal principal de templates agora lista mensagens interativas salvas junto da busca, separadas dos templates oficiais da Meta, permitindo clicar nelas para enviar diretamente à conversa.
- O builder de mensagem interativa usa modal mais largo e grid responsivo para evitar campos cortados e rolagem horizontal.
