# Fluxo end-to-end de login/conexao Instagram

Este documento lista os caminhos absolutos reais dos arquivos envolvidos no fluxo de conexao OAuth do Instagram no Chatwit, desde a tela de novo inbox ate callback, persistencia do canal, webhook, mensagens e reautorizacao.

## Rotas do fluxo

| Etapa | Rota |
| --- | --- |
| Tela de conexao | `/app/accounts/:accountId/settings/inboxes/new/instagram` |
| Gerar URL OAuth | `POST /api/v1/accounts/:account_id/instagram/authorization` |
| Callback OAuth | `GET /instagram/callback` |
| Verificacao webhook Meta | `GET /webhooks/instagram` |
| Eventos webhook Meta | `POST /webhooks/instagram` |

## Endpoints externos usados

| Uso | Endpoint |
| --- | --- |
| Autorizacao OAuth | `https://api.instagram.com/oauth/authorize` |
| Token curto OAuth | `https://api.instagram.com/oauth/access_token` |
| Token long-lived | `https://graph.instagram.com/access_token` |
| Dados do usuario Instagram | `https://graph.instagram.com/v22.0/me` |
| Assinatura de webhook | `https://graph.instagram.com/v22.0/:instagram_id/subscribed_apps` |
| Refresh de token | `https://graph.instagram.com/refresh_access_token` |
| Envio de mensagem | `https://graph.instagram.com/v22.0/:instagram_id/messages` |

## Habilitacao e configuracao do canal

| Arquivo absoluto | Papel |
| --- | --- |
| `/home/wital/chatwit/config/installation_config.yml` | Define `INSTAGRAM_APP_ID`, `INSTAGRAM_APP_SECRET`, `INSTAGRAM_VERIFY_TOKEN`, `INSTAGRAM_API_VERSION` e `ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT`. |
| `/home/wital/chatwit/config/features.yml` | Define feature flag `channel_instagram`. |
| `/home/wital/chatwit/app/javascript/dashboard/featureFlags.js` | Expoe constante frontend `CHANNEL_INSTAGRAM`. |
| `/home/wital/chatwit/app/controllers/dashboard_controller.rb` | Carrega `INSTAGRAM_APP_ID` para `window.chatwootConfig`. |
| `/home/wital/chatwit/app/views/layouts/vueapp.html.erb` | Injeta `instagramAppId` no config global do frontend. |
| `/home/wital/chatwit/app/javascript/dashboard/components/widgets/ChannelItem.vue` | Habilita/desabilita item Instagram pela feature flag e `instagramAppId`. |

## Entrada frontend do login/conexao

| Arquivo absoluto | Papel |
| --- | --- |
| `/home/wital/chatwit/app/javascript/dashboard/routes/dashboard/settings/inbox/ChannelList.vue` | Lista o canal Instagram na tela de novos inboxes. |
| `/home/wital/chatwit/app/javascript/dashboard/routes/dashboard/settings/inbox/inbox.routes.js` | Define rotas de inbox, incluindo `new/:sub_page`, `:inbox_id/agents` e `:inbox_id/finish`. |
| `/home/wital/chatwit/app/javascript/dashboard/routes/dashboard/settings/inbox/ChannelFactory.vue` | Resolve `sub_page=instagram` para o componente `channels/Instagram.vue`. |
| `/home/wital/chatwit/app/javascript/dashboard/routes/dashboard/settings/inbox/channels/Instagram.vue` | Tela do botao "Continue with Instagram"; chama API de autorizacao e trata erros do callback. |
| `/home/wital/chatwit/app/javascript/dashboard/api/ApiClient.js` | Monta base URL account-scoped para chamadas `/api/v1/accounts/:account_id`. |
| `/home/wital/chatwit/app/javascript/dashboard/api/channel/instagramClient.js` | Chama `POST /instagram/authorization`. |
| `/home/wital/chatwit/app/javascript/dashboard/i18n/locale/en/inboxMgmt.json` | Strings base usadas na tela de conexao/reautorizacao Instagram. |

## Backend OAuth e callback

| Arquivo absoluto | Papel |
| --- | --- |
| `/home/wital/chatwit/config/routes.rb` | Define `POST /api/v1/accounts/:account_id/instagram/authorization` e `GET /instagram/callback`. |
| `/home/wital/chatwit/app/controllers/api/v1/accounts/base_controller.rb` | Base account-scoped das APIs autenticadas. |
| `/home/wital/chatwit/app/controllers/api/v1/accounts/oauth_authorization_controller.rb` | Exige usuario administrador e fornece `base_url`. |
| `/home/wital/chatwit/app/controllers/api/v1/accounts/instagram/authorizations_controller.rb` | Gera URL OAuth com scopes Instagram e JWT `state`. |
| `/home/wital/chatwit/app/controllers/concerns/instagram_concern.rb` | Configura client OAuth, troca token curto por long-lived e busca dados do usuario Instagram. |
| `/home/wital/chatwit/app/helpers/instagram/integration_helper.rb` | Define scopes `instagram_business_basic` e `instagram_business_manage_messages`; gera/verifica JWT `state`. |
| `/home/wital/chatwit/app/controllers/instagram/callbacks_controller.rb` | Processa callback, cria ou atualiza `Channel::Instagram` e redireciona para agents/settings. |

## Persistencia, inbox e reautorizacao

| Arquivo absoluto | Papel |
| --- | --- |
| `/home/wital/chatwit/app/models/channel/instagram.rb` | Modelo `Channel::Instagram`; assina/desassina webhook; expõe token com refresh automatico. |
| `/home/wital/chatwit/app/models/concerns/channelable.rb` | Relacao comum de canais com `Account` e `Inbox`. |
| `/home/wital/chatwit/app/models/concerns/reauthorizable.rb` | Controla flags Redis de reautorizacao e emails de desconexao. |
| `/home/wital/chatwit/app/models/inbox.rb` | Detecta inbox Instagram direto ou Instagram via Facebook Page. |
| `/home/wital/chatwit/app/views/api/v1/models/_inbox.json.jbuilder` | Serializa `reauthorization_required` e `instagram_id` para o frontend. |
| `/home/wital/chatwit/db/migrate/20250326034635_add_instagram_channel.rb` | Migracao que cria tabela `channel_instagram`. |
| `/home/wital/chatwit/db/schema.rb` | Schema atual da tabela `channel_instagram`. |
| `/home/wital/chatwit/app/services/instagram/refresh_oauth_token_service.rb` | Renova token long-lived quando esta elegivel para refresh. |

## UI de reautorizacao e inbox duplicado

| Arquivo absoluto | Papel |
| --- | --- |
| `/home/wital/chatwit/app/javascript/dashboard/routes/dashboard/settings/inbox/Settings.vue` | Mostra banner de reautorizacao Instagram e aviso de inbox duplicado. |
| `/home/wital/chatwit/app/javascript/dashboard/routes/dashboard/settings/inbox/channels/instagram/Reauthorize.vue` | Reusa `instagramClient.generateAuthorization()` para reconectar o canal. |
| `/home/wital/chatwit/app/javascript/dashboard/routes/dashboard/settings/inbox/channels/instagram/DuplicateInboxBanner.vue` | Banner quando existe inbox Instagram novo para um Instagram que tambem existia via Facebook. |
| `/home/wital/chatwit/app/javascript/dashboard/routes/dashboard/settings/inbox/FinishSetup.vue` | Tela final apos criacao de inbox; mostra sugestao sobre inbox Instagram migrado/duplicado. |
| `/home/wital/chatwit/app/javascript/dashboard/store/modules/inboxes.js` | Getters `getFacebookInboxByInstagramId` e `getInstagramInboxByInstagramId`. |
| `/home/wital/chatwit/app/javascript/dashboard/helper/inbox.js` | Constante `INBOX_TYPES.INSTAGRAM = Channel::Instagram`. |

## Webhook, recebimento e criacao de mensagem

| Arquivo absoluto | Papel |
| --- | --- |
| `/home/wital/chatwit/app/controllers/concerns/meta_token_verify_concern.rb` | Verificacao comum de token Meta. |
| `/home/wital/chatwit/app/controllers/webhooks/instagram_controller.rb` | Recebe verificacao/eventos Instagram e enfileira job. |
| `/home/wital/chatwit/app/jobs/webhooks/instagram_events_job.rb` | Processa entradas Meta, prioriza `Channel::Instagram` e roteia eventos `message`/`read`. |
| `/home/wital/chatwit/app/services/instagram/webhooks_base_service.rb` | Base para localizar inbox, contato e `ContactInbox`. |
| `/home/wital/chatwit/app/services/instagram/base_message_text.rb` | Fluxo comum de mensagem recebida, deleted message, bloqueio e criacao de mensagem. |
| `/home/wital/chatwit/app/services/instagram/message_text.rb` | Busca perfil Instagram via Graph API para canal direto `Channel::Instagram`. |
| `/home/wital/chatwit/app/services/instagram/messenger/message_text.rb` | Variante para Instagram via `Channel::FacebookPage`. |
| `/home/wital/chatwit/app/builders/messages/instagram/base_message_builder.rb` | Cria/reusa conversa e cria `Message` com conteudo, quick replies e postbacks. |
| `/home/wital/chatwit/app/builders/messages/instagram/message_builder.rb` | Variante do builder para canal direto Instagram. |
| `/home/wital/chatwit/app/builders/messages/instagram/messenger/message_builder.rb` | Variante do builder para Instagram via Facebook Page. |
| `/home/wital/chatwit/lib/integrations/instagram/message_parser.rb` | Parser Chatwit para texto, postback e quick reply do Instagram. |
| `/home/wital/chatwit/app/builders/contact_inbox_with_contact_builder.rb` | Cria contato e contact inbox usado pelo canal Instagram. |
| `/home/wital/chatwit/app/services/instagram/read_status_service.rb` | Processa eventos `read`/seen. |
| `/home/wital/chatwit/app/services/instagram/test_event_service.rb` | Processa payloads de teste do painel Meta. |

## Envio de respostas

| Arquivo absoluto | Papel |
| --- | --- |
| `/home/wital/chatwit/app/jobs/send_reply_job.rb` | Roteia `Channel::Instagram` para `Instagram::SendOnInstagramService`. |
| `/home/wital/chatwit/app/services/instagram/base_send_service.rb` | Base de envio de texto/anexo para Instagram. |
| `/home/wital/chatwit/app/services/instagram/send_on_instagram_service.rb` | Envia mensagens pelo endpoint direto `graph.instagram.com/v22.0/:instagram_id/messages`. |
| `/home/wital/chatwit/app/services/instagram/messenger/send_on_instagram_service.rb` | Envio para Instagram via Facebook Page legado. |
| `/home/wital/chatwit/app/services/instagram/rich_message_service.rb` | Envio de mensagens ricas/quick replies Instagram usadas por integracoes Chatwit/SocialWise. |
| `/home/wital/chatwit/app/services/conversations/message_window_service.rb` | Janela de resposta Instagram 24h/7d conforme `ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT`. |

## Pontos Chatwit/SocialWise relacionados ao Instagram

| Arquivo absoluto | Papel |
| --- | --- |
| `/home/wital/chatwit/lib/integrations/socialwise/instagram_response_processor.rb` | Processamento de respostas ricas SocialWise para Instagram. |
| `/home/wital/chatwit/lib/integrations/socialwise_flow/processor_service.rb` | Fluxo SocialWise que consome/entrega mensagens Instagram/FacebookPage. |
| `/home/wital/chatwit/app/validators/instagram_channel_validator.rb` | Validador Chatwit para canal Instagram em fluxos SocialWise. |

## Specs e factories relevantes

| Arquivo absoluto | Cobre |
| --- | --- |
| `/home/wital/chatwit/spec/controllers/api/v1/accounts/instagram/authorizations_controller_spec.rb` | API que gera URL OAuth. |
| `/home/wital/chatwit/spec/controllers/instagram/callbacks_controller_spec.rb` | Callback OAuth, criacao/atualizacao de canal e erros. |
| `/home/wital/chatwit/spec/controllers/concerns/instagram_concern_spec.rb` | Concern de token/dados Instagram. |
| `/home/wital/chatwit/spec/controllers/webhooks/instagram_controller_spec.rb` | Controller de webhook Instagram. |
| `/home/wital/chatwit/spec/jobs/webhooks/instagram_events_job_spec.rb` | Job de eventos webhook Instagram. |
| `/home/wital/chatwit/spec/services/instagram/refresh_oauth_token_service_spec.rb` | Refresh de token long-lived. |
| `/home/wital/chatwit/spec/services/instagram/send_on_instagram_service_spec.rb` | Envio direto pelo canal Instagram. |
| `/home/wital/chatwit/spec/services/instagram/messenger/send_on_instagram_service_spec.rb` | Envio Instagram via Facebook Page. |
| `/home/wital/chatwit/spec/services/instagram/read_status_service_spec.rb` | Status de leitura. |
| `/home/wital/chatwit/spec/services/instagram/test_event_service_spec.rb` | Eventos de teste Meta. |
| `/home/wital/chatwit/spec/builders/messages/instagram/message_builder_spec.rb` | Criacao de mensagens Instagram direto. |
| `/home/wital/chatwit/spec/builders/messages/instagram/messenger/message_builder_spec.rb` | Criacao de mensagens Instagram via Facebook Page. |
| `/home/wital/chatwit/spec/factories/channel/channel_instagram.rb` | Factory `Channel::Instagram`. |
| `/home/wital/chatwit/spec/factories/channel/instagram_channel.rb` | Factory de canal Instagram via Facebook Page. |
| `/home/wital/chatwit/spec/factories/instagram_message/incoming_messages.rb` | Payloads de mensagens Instagram. |
| `/home/wital/chatwit/spec/factories/instagram/instagram_message_create_event.rb` | Payload de evento create Instagram. |
| `/home/wital/chatwit/spec/support/instagram_spec_helpers.rb` | Helpers de specs Instagram. |

## Observacoes de arquitetura

- O fluxo novo de conexao direta cria `Channel::Instagram`.
- O fluxo antigo/legado de Instagram via Facebook Page ainda existe e usa `Channel::FacebookPage` com `instagram_id`.
- O job de webhook prioriza `Channel::Instagram` quando encontra o mesmo `instagram_id`, e so cai para `Channel::FacebookPage` se o canal direto nao existir.
- A criacao do canal assina webhook no `after_create_commit`; erro na assinatura e registrado em log debug e nao bloqueia a criacao do inbox.
- Reautorizacao usa a mesma API de autorizacao do login inicial.
