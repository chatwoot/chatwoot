# Caça a Bugs/Issues — Plano de Ataque Técnico (2026-07-04)

> Investigação **causa-raiz, read-only**, em paralelo (5 agentes por cluster de domínio) + verificação em docs
> oficiais (AWS SES, Meta Cloud API) e AWS CLI real (profile `hub2you`, conta `354307071110`).
> Nada foi alterado ainda. Este doc é para **aprovar antes de implementar**.
>
> Convenção de esforço: **P** (≤2h) · **S** (≤½ dia) · **M** (1–2 dias) · **L** (3+ dias).
> Cada track vira **branch/worktree própria**; merges agrupados para evitar cascata de deploy blue-green.
>
> **Mockups das telas (para aprovação):** https://claude.ai/code/artifact/3aab7347-df40-44e9-9163-ceeb8d967bb7
> — onboarding e-mail MS/Google (P1b), fluxo base-primeiro (P9), etiqueta do funil (P4).
> **v2 (04/jul):** respostas do PO incorporadas (SES do zero + multi-conta/RD Station, corte de view P8, KB-first interno+externo com skip, Meta CTWA+tráfego, onboarding com guia).

---

## Sumário de diagnóstico (9 pontos)

| # | Tema | Diagnóstico curto | Tipo | Esforço | Risco |
|---|------|-------------------|------|---------|-------|
| 1 | E-mail conta 6 não chega em Conversas | Teste valida **SMTP de envio**, não recebimento. Inbound não montado (IMAP off ou SES-receiving inexistente) | Infra/Ops | S–L | Baixo |
| 1b | Onboarding MS/Google (guia na tela) | 1 componente compartilhado `OAuthChannel.vue`; input largo + espaço vazio à direita | Código FE | M | Baixo |
| 2 | Verificação de domínio SES pendente (3 e 6) | Pior que pendente: **zero identidades de domínio** no SES + conta **sandbox** + produção **DENIED** | Infra/Ops | M | Baixo–Médio |
| 3 | Botão "ativar agente" pede testar antes | **Não há trava real**; efeito de UX (botão "Testar antes" primário + toggle ativar some em `draft`) | Código FE | S | Baixo |
| 4 | Badge do funil corta a etapa com >1 funil | `max-w-[8rem] truncate` fixo no chip | Código FE | S | Baixo |
| 5 | Eventos CRM/Kanban em Automações e Macros | Eventos de card existem mas só no barramento **ActionCable**, não no dispatcher de automação. Macro não tem gatilho | Código FE+BE | M–L | Médio |
| 6 | Marcação de campanha Meta no Kanban | CTWA **já captura `referral`** (enterrado). LP→WhatsApp = token no texto (convenção). FB/IG descartado. Google sem entrada | Código FE+BE | S–M | Baixo–Médio |
| 7 | Atributos custom usados pelas IAs de CRM | IA recebe só o **schema** dos atributos, não os **valores** já preenchidos | Código BE | M | Médio |
| 8 | Gestão de IA mostra gasto do "período caro" | Corte de exibição (`CRM_AI_USAGE_BASELINE_AT`, #48) **existe e funciona** — só **não foi ligado/versionado** em prod | Ops + Código | P | Baixo |
| 9 | Fluxo KB-first na criação do agente | Viável, mas **1 bloqueador**: draft do agente nasce no 1º turno do chat; KB-first precisa do draft antes | Código FE+BE | M–L | Médio |

---

## Ponto 1 — E-mail conta 6 não chega em Conversas

**Causa-raiz.** No Chatwoot o "teste de e-mail" valida **conexão SMTP de envio**, não recebimento. Conversa só nasce quando uma mensagem **entra** por um de dois trilhos independentes:

- **A) IMAP pull** — Chatwoot busca ativamente na caixa do cliente. Gatilho `Channel::Email#imap_enabled = true` (`app/models/channel/email.rb:10-14`) ou provider `microsoft`/`google` com OAuth. Job: `app/jobs/inboxes/fetch_imap_emails_job.rb` → `app/mailboxes/imap/imap_mailbox.rb:8` cria contato/conversa/mensagem.
- **B) ActionMailbox push** — provedor externo entrega no Chatwoot. Ingress por ENV `RAILS_INBOUND_EMAIL_SERVICE` (`config/initializers/mailer.rb:47`, default `relay`); SES-receiving exige `ACTION_MAILBOX_SES_SNS_TOPIC` (`:51`). Roteamento `app/mailboxes/application_mailbox.rb:10-15` → `reply_mailbox.rb`.

Envio é SMTP puro (`config/initializers/mailer.rb:26-27`); **não há SDK AWS SES no envio**.

**Clarificação PO (04/jul):** a inbox conta 6 é **caixa MS / Google / provedor (Hostinger) via IMAP** — **não** depende de SES. **SES é só para disparo em massa de campanha** (Ponto 2), trilho separado. Logo o fix do e-mail não-chegando é **IMAP/OAuth**, não Amazon.

**Hipótese dominante:** inbox da conta 6 é **SMTP-only / IMAP não habilitado** → só envia, nada entra. Bate exato com o sintoma. Segunda hipótese: setup pretendia SES-receiving, que **fisicamente não existe** (ver Ponto 2: zero receipt rules/SNS).

**Ação (Ops, precisa do operador — read-only não alcançou o Postgres de prod):**
1. Console Rails prod: `Channel::Email.where(account_id: [3,6]).pluck(:id,:email,:imap_enabled,:provider,:imap_address)` + conferir `ENV['RAILS_INBOUND_EMAIL_SERVICE']` e `ENV['MAILER_INBOUND_EMAIL_DOMAIN']`.
2. Decidir o modelo de recebimento: **(a) IMAP/OAuth** (mais simples, sem DNS; recomendado se a conta 6 tem mailbox própria) · **(b) forward + ingress relay/Postmark** · **(c) SES-receiving** (mais pesado, hoje 100% ausente).
3. Enviar um e-mail **real de fora** (não o botão "testar") e olhar log de `FetchImapEmailsJob`/`ReplyMailbox`.

**Esforço:** S (habilitar IMAP) a L (montar SES-receiving). **Risco:** baixo (config de inbox, reversível). **Não vira PR de código** — é operação. Vira **Issue de Ops** com checklist.

### Ponto 1b — Onboarding MS/Google: guia passo-a-passo na tela (PO 04/jul)

**Pedido:** nas telas de nova caixa Microsoft/Google, estreitar os inputs (client_id, secret, tenant) e usar o **espaço vazio à direita** para um **guia humanizado** de como criar o app Azure / cliente Google Cloud, com os eventos/permissões e links.

**Achado-chave:** `Microsoft.vue:10`/`Google.vue:10` são **wrappers finos** que renderizam o mesmo componente compartilhado `app/javascript/dashboard/routes/dashboard/settings/inbox/channels/emailChannels/OAuthChannel.vue` (passando `provider` + labels). **O formulário de credenciais vive no `OAuthChannel.vue` — 1 mudança cobre as 2 telas.** Hoje: raiz `col-span-6` full-width + form `max-w-xl` encostado à esquerda (`:118-131`) → o vazio à direita.

**Escopos REAIS (do código, não inventados):**
- **Microsoft** (`app/controllers/concerns/microsoft_concern.rb:24-32`): `offline_access`, `https://outlook.office.com/IMAP.AccessAsUser.All`, Graph `Mail.Send` + `Mail.ReadWrite`, `openid profile email` (+ `Calendars.ReadWrite` só se reuniões ligadas). **Envio via Graph `sendMail`, não SMTP** (`microsoft/send_mail_service.rb`) — pedir `Mail.Send`/`Mail.ReadWrite` delegadas, **não** `SMTP.Send`.
- **Google** (`app/controllers/concerns/google_concern.rb:19,22,29`): `email profile https://mail.google.com/` (mailbox full via IMAP/SMTP XOAUTH2) + `https://www.googleapis.com/auth/calendar` **só** se reuniões ligadas. É o escopo restrito — **não** basta `gmail.readonly` (o código envia também).
- **Agenda p/ CRM Calendário (PO 04/jul):** o gating é o **mesmo consentimento** — `CRM_CALENDAR_MEETINGS_ENABLED=true` OU intent de calendário (`microsoft_concern.rb:35-48`, `google_concern.rb:28-30`). 1 login libera e-mail **+** agenda (sem 2º OAuth). **O guia da tela DEVE listar essa permissão** (MS `Calendars.ReadWrite` · Google `.../auth/calendar`) quando o CRM Calendário/reuniões estiver em uso — senão o consentimento não concede agenda e o CRM Calendário quebra. **Já incluído no mockup** (chip 📅 + nota nos 2 guias).
- **Google exige HABILITAR a Calendar API (verificado):** `Google::CalendarEventService` chama `https://www.googleapis.com/calendar/v3` (`calendar_event_service.rb:11`). Escopo liberado **não basta** — o projeto GCP precisa ativar a **Google Calendar API** (além da Gmail API) senão dá 403. **MS não precisa** (Graph sempre disponível). Guia Google passo 2 atualizado no mockup.
- Callback vem do backend (`OAuthChannel.vue:65` `data.callback_url`) — o guia diz "copie o URL mostrado ao lado", robusto a domínio/ambiente.

**Abordagem:** editar **só** `OAuthChannel.vue`: grid 2 colunas (`lg:grid-cols-[minmax(0,28rem)_minmax(0,1fr)]`), form à esquerda (`max-w-xl`→`max-w-md`), `<aside>` à direita com `<ol>` de passos (Tailwind-only), condicional por `isMicrosoft`, escondido quando `configured`. Passos pt-BR curtos (MS: Entra → Registro → Redirect Web → copiar client/tenant → API permissions delegadas → consentimento admin → secret; Google: projeto → ativar Gmail API → OAuth consent externo → escopo `mail.google.com/` → cliente Web → redirect URIs → copiar id/secret → test users). Links oficiais (learn.microsoft.com, console.cloud.google.com) inline.

**i18n:** `en/inboxMgmt.json` + `pt_BR/inboxMgmt.json` (bloco `OAUTH_CREDENTIALS`, ~:1248) — este fork escreve pt_BR direto, então popular os dois pra o texto aparecer. Branding via `replaceInstallationName` se citar marca. **Esforço:** M (1 componente + ~16 passos i18n × 2 locales). **Risco:** baixo (zero mudança na lógica OAuth/`saveCredentials`).

---

## Ponto 2 — Verificação de domínio SES pendente (conta 3 e 6)

**Evidência AWS CLI real (profile `hub2you`, conta `354307071110`):**
- `sesv2 list-email-identities` us-east-1 e sa-east-1: **vazio**. us-east-2: só 3 **endereços de e-mail** de outro projeto (Viotto), nenhum domínio dos tenants.
- `get-email-identity` p/ `hub2you.ai`, `chat.hub2you.ai`, `autonomia.solutions`: **NotFoundException** em todas as regiões.
- `sesv2 get-account`: **`ProductionAccessEnabled: false` (SANDBOX)** nas 3 regiões; us-east-2 com pedido de produção **DENIED**.
- `list-receipt-rule-sets` e `sns list-topics`: **vazios** (recebimento SES inexistente).

**Causa-raiz.** Não é "verificação pendente" — **nenhuma identidade de domínio dos tenants existe no SES**. O "pendente" que aparece é estado interno do Chatwoot (`channel_email.verified_for_sending`), não reflete SES real.

**Para verificar um domínio (docs oficiais AWS):**
1. **Easy DKIM — 3 CNAMEs** (obrigatório): `sesv2 create-email-identity --email-identity <domínio>` devolve 3 tokens → publicar `<token>._domainkey.<domínio> CNAME <token>.dkim.amazonses.com`. Detecção até 72h. (docs.aws.amazon.com/ses `verify-domain-dkim`)
2. **Custom MAIL FROM** (alinhamento DMARC): `mail.<domínio> MX 10 feedback-smtp.<região>.amazonses.com` + `TXT "v=spf1 include:amazonses.com ~all"`.
3. **DMARC**: `_dmarc.<domínio> TXT "v=DMARC1; p=none; rua=mailto:dmarc@<domínio>"`.
4. **Sair do sandbox:** novo pedido de produção com use-case Hub2You (o de us-east-2 foi DENIED com texto da Viotto). Sandbox = 200 msgs/24h, só p/ destinatários verificados.

**Ligação com Ponto 1 (sem rodeio):** verificação/sandbox afetam **envio**, não **recebimento**. Verificação de domínio **não é** a causa do e-mail não chegar. O único elo: se escolher SES-receiving no Ponto 1, verificar o domínio é o degrau 1.

**Atualização PO (04/jul): "criar a infra da hub2you na Amazon; só temos na autonomia; use como referência".**
- **Não dá pra clonar a Autonomia:** não há perfil AWS da Autonomia na máquina (só `default` — token morto — e `hub2you` = a própria conta-alvo 354307071110). Não existe um "SES-fora-do-sandbox comprovado" para espelhar via CLI. **Decisão sua:** (a) fornecer credencial da conta AWS da Autonomia (extraio o template real read-only) OU (b) autorizar montar **do zero em us-east-1** com boas práticas.
- **Detalhe que economiza tempo:** `hub2you.ai` **já tem `include:amazonses.com` no SPF raiz** (foi preparado pra SES) — a identidade de domínio e os CNAMEs DKIM é que nunca foram criados. DNS na **Hostinger**. Não tocar no MX raiz (recebimento fica na Hostinger).
- **Checklist do zero (us-east-1, cada 🔴 pede 🟢):** (1) 🟢 `create-email-identity hub2you.ai` → tokens DKIM saem no output; (2) 🟢 `put-email-identity-mail-from-attributes mail.hub2you.ai`; (3) 🟢 publicar na Hostinger 3 CNAMEs + MX `feedback-smtp.us-east-1.amazonses.com` + SPF em `mail.`; (4) `get-email-identity` até SUCCESS; (5) 🟢 `put-account-details --production-access-enabled` us-east-1, **sem** reaproveitar o caso negado `177974592100054`. Relatório com comandos em `scratchpad/ses_hub2you_replication.md`.

**Multi-conta + coexistência com RD Station (PO 04/jul — pesquisado, docs AWS/RD):**
- **Mesmo domínio verificado em +1 conta AWS ao mesmo tempo? SIM.** Verificação é por conta; cada conta emite **3 CNAMEs DKIM próprios** (tokens distintos) → 2 contas = **6 CNAMEs**, sem colisão, ambas enviam como o domínio. ([blog AWS "domain in multiple accounts"](https://aws.amazon.com/blogs/messaging-and-targeting/how-to-use-domain-with-amazon-ses-in-multiple-accounts-or-regions/))
- **SES + RD Station do cliente no mesmo domínio? SIM.** SPF é **1 TXT só, mesclado**: `v=spf1 include:amazonses.com include:_spf.rdstation.com.br ~all`. DKIM não colide (seletores próprios). DMARC é **1 registro só**. Os 3 CNAMEs DKIM da RD **saem do painel dela** (não são públicos — copiar do cliente).
- **Gotchas (quebram na prática):** (1) **limite de 10 lookups DNS do SPF** (RFC 7208) — RD + SES + eventual Google/M365 estoura fácil → PermError → DMARC fail; **validar contagem antes de publicar**. (2) SPF **mesclar, nunca duplicar** (2 TXT SPF = inválido). (3) MAIL FROM = **exatamente 1 MX**; **subdomínio único por conta SES** (`mail.hub2you.ai`, `mail2.` p/ a 2ª) — RD usa o return-path dela, não compete.

**Esforço:** M por domínio (criar identidade + DNS + esperar) + M pra reabrir produção. **Risco:** baixo–médio (DNS reversível; risco real é SPF 10-lookup + reputação/aprovação AWS). **Vira Issue de Ops** (padronizar **us-east-1**). **Decisão PO:** montar do zero (confirmado); SES = **só disparo em massa de campanha** (ponto 1 do PO), separado do recebimento IMAP da inbox.

---

## Ponto 3 — Botão "ativar agente" pede testar antes

**Causa-raiz: não existe trava real.** Backend `agents_controller#update` permite `status`/`enabled` livres; o model `Autonomia::Agents::Agent` valida só `name` + `agent_type` — **nenhuma regra ligando `active` a "foi testado"**. É efeito de UX:
- `BuilderReview.vue:251-289` põe "Testar antes" (`TEST_FIRST`) como ação primária/primeira; o usuário lê como passo obrigatório.
- "Testar" **navega** pra outra aba (`AgentBuilderPage.vue:309-315`); ao voltar, o toggle de ativar no header **só aparece p/ agente não-draft** (`AgentPanelPage.vue:201`). Draft testado fica sem controle óbvio de ativar → sensação de "me obriga a testar".

**Abordagem (UI/flow, sem mudar backend):**
1. Reordenar/reestilizar `BuilderReview.vue:254-289`: ativar (`ACTIVATE_INTERNAL`/`CONNECT_ACTIVATE`) vira **primário**; "Testar antes" secundário. Interno ativa em 1 clique (sem dependência de inbox).
2. (Opcional M) Mostrar o toggle ativar no header p/ `draft` também.
3. **Preservar** a única trava real: agente externo exige inbox elegível (`canConnect` + rollback-to-draft em falha de conexão).

**Arquivos:** `BuilderReview.vue`, `AgentPanelPage.vue`, i18n `en/agents.json` (`AGENTS.REVIEW.*`). **Esforço:** S. **Risco:** baixo.

---

## Ponto 4 — Badge do funil corta a etapa com >1 funil

**Causa-raiz.** `app/javascript/dashboard/components-next/Conversation/ConversationCard/CrmConversationStageChip.vue:36` usa `max-w-[8rem] truncate` fixo. Com >1 funil o rótulo vira `funil · etapa` (`:22-24`) e estoura os 128px → corta sem indicação. Pai `CardLabels` (`ConversationCard.vue:259-263`) não previne overflow.

**Abordagem:** aumentar `max-w` (ex. `12rem` ou responsivo), manter `title` (tooltip já existe `:32`) + indicador de truncagem opcional; considerar `flex-wrap` para 2ª linha em telas largas. **Arquivos:** `CrmConversationStageChip.vue` (+ possível ajuste no container). **Esforço:** S. **Risco:** baixo (testar mobile).

---

## Ponto 5 — Eventos CRM/Kanban em Automações e Macros

**Causa-raiz (corrigida pós-Codex).** Eventos de card **já existem** (`lib/events/types.rb:66-73`: `CRM_CARD_CREATED/UPDATED/MOVED/WON/LOST/...`), emitidos em `app/services/crm/cards/mover.rb` + `broadcaster.rb`. Eles vão ao browser via ActionCable **e** já chegam ao `Rails.configuration.dispatcher` pelo caminho de **webhooks** (`Crm::Activity after_commit → Crm::Webhooks::Emitter`, `crm.card.*`). O que falta **não** é o barramento: é que **`AutomationRuleListener` não implementa handlers `crm_card_*`** e a **UI/model de automação não expõem esses eventos** (`automation_rule.rb:38-51`, listener `:1-90`: só eventos de conversa/mensagem). **Macro não tem conceito de gatilho** — sempre roda manual sobre uma conversa (`macro.rb:33-35`). Já existe motor CRM-nativo limitado: `crm/stage_automation_step.rb` (3 ações: follow-up/owner/move).

**Abordagem (2 trilhos aditivos):**
- **(A) Eventos CRM → gatilhos de Automação:** o dispatch já existe (via `Crm::Webhooks::Emitter`). Adicionar handlers no `AutomationRuleListener` (`crm_card_moved` etc.) que resolvem `card.primary_conversation` e rodam filtro/ação; **guardar card sem conversa**. Registrar `event_name` + condições CRM (`pipeline_id`, `stage_id`, `from_stage_id`). FE: `settings/automation/constants.js` + i18n. **Reusar o emit existente — NÃO adicionar um segundo `dispatch` no Broadcaster/Mover (evitar disparo duplo com o caminho de webhook).**
- **(B) Ações CRM em Automação/Macro:** adicionar `move_card_to_stage`/`create_follow_up` aos allowlists (`AutomationRule#actions_attributes`, `Macro::ACTIONS_ATTRS`), reusando `Crm::Cards::Mover`. FE + i18n.

**"Eventos CRM como gatilho de macro" é mismatch** — macro não tem trigger. Reenquadrar como (A) trigger de automação ou (B) ação CRM.

**Risco:** (1) **loop de recursão** (move → evento → automação que move) — guard `performed_by_automation?` (padrão já existe `automation_rule_listener.rb:73`); (2) **disparo duplo** — o mesmo evento já alimenta webhooks CRM; diferenciar "webhook externo" de "gatilho interno" e reusar o emit, sem duplicar. Enterprise: `AsyncDispatcher.prepend_mod_with`; gatear atrás de `Crm::Config.enabled?`. **Esforço:** (A) M–L, (B) M. **Arquivos:** `broadcaster.rb`/`mover.rb`, `automation_rule_listener.rb`, `automation_rule.rb`, `conditions_filter_service`/`action_service`, `macro.rb`, FE constants + i18n.

---

## Ponto 6 — Marcação de campanha Meta/Google no Kanban/Conversas

**Causa-raiz.** WhatsApp Cloud API e Twilio **já capturam o objeto `referral` inteiro** (todos os campos Meta), mas enterrado na 1ª mensagem, sem virar atributo/label/tag:
- WhatsApp: `app/services/whatsapp/incoming_message_base_service.rb:213-216` → `content_attributes['referral']` (helper preserva o objeto cru).
- Twilio: `app/services/twilio/referral_params_helper.rb:2-31` mapeia `source_id/source_type/source_url/headline/body/ctwa_clid`.
- **FB/IG/Messenger: referral DESCARTADO** — builders (`app/builders/messages/messenger/message_builder.rb`, `facebook/message_builder.rb`) não leem `referral`/`ad_id`/`postback.referral`.
- **Google: não existe canal de entrada** no fork (`app/services/google/*` = só Calendar). Sem webhook, sem dado. Honesto: não implementável sem criar canal.

**Campos oficiais Meta** (WhatsApp `referral`): `source_url`, `source_type` (ad/post), `source_id`, `headline`, `body`, `media_type`, `ctwa_clid`. Messenger/IG (`messaging.referral`/`postback.referral`): `ref`, `source`, `type`, `ad_id`, `referer_uri`. (developers.facebook.com — CTWA webhooks + messaging_referrals; re-verificar por versão do Graph API na hora.)

**Abordagem:**
- **Ganho barato (S–M) — CTWA automático:** promover `referral` da 1ª mensagem para `conversation.additional_attributes['campaign']` (`{source:'meta', source_id, ctwa_clid, headline, source_type}`) + aplicar label `meta-ad`/`campaign:<id>` (mecanismo de label existente) → o `Crm::Card` espelha a conversa (via `card_conversations`), então a tag flui pro Kanban. Guardar "só na criação/1ª mensagem".
- **Paridade FB/IG (M, opcional):** ler `referral`/`ad_id` nos builders Messenger/FB.
- **Google (L, bloqueado):** só via parse de UTM/`gclid` do `referral.source_url` em funil landing→WhatsApp; sem webhook Google.

**Caminho LP→WhatsApp (PO 04/jul: tráfego normal → landing page → botão WhatsApp na LP):**
- **Honesto:** esse clique é **orgânico** (`wa.me`) — o Meta **NÃO manda `referral`** (referral existe só em anúncio CTWA; confirmado em docs Meta). Logo, atribuição **não é automática** nesse caminho.
- **Único mecanismo viável:** texto pré-preenchido `wa.me/<num>?text=…[camp:<id>]` — o token chega no **corpo da 1ª mensagem** (`incoming_message_service_helpers.rb:27-34`). Parser (regex `\[camp:([a-z0-9._-]{1,64})\]`) na 1ª mensagem (guard de conversa nova em `incoming_message_base_service.rb:151-162`) → `additional_attributes['campaign']` + label → espelho no card (`Crm::Conversations::CardSyncer#refresh_attributes`, `card_syncer.rb:127-141`). Greenfield, sem regressão.
- **Ressalva de produto:** depende do **marketing padronizar os links** na LP; cliente **pode apagar** o texto pré-preenchido → atribuição parcial. **É convenção, não dado do Meta.**
- **2 PRs irmãos** sob a mesma engine conversa→card: **CTWA** (automático, prioridade — cobertura alta) e **LP→WhatsApp** (convenção — só entrega valor após o time de tráfego padronizar os links).

**Schema unificado (PO 04/jul: "deixe preparado pra capturar os dois quando enviarem"):** um único formato em `conversation.additional_attributes['campaign']` que serve as duas origens, escrito na 1ª mensagem:
```
{ source: 'meta_ctwa' | 'lp_whatsapp',   # origem do dado
  campaign_id: <source_id | token da LP>,
  ctwa_clid: <string|null>,              # só CTWA
  headline: <string|null>,               # só CTWA
  raw: { ... } }                          # payload bruto p/ auditoria
```
O CardSyncer espelha `campaign_id`+`source` no card; o label `campanha:<id>` é o mesmo nos dois caminhos. Assim, quando o marketing ligar o token na LP, o parser já grava no **mesmo** campo — sem migração. **Google fica fora por ora** (PO).

**Arquivos:** `incoming_message_base_service.rb`, `incoming_message_service_helpers.rb`, `twilio/referral_params_helper.rb`, `crm/sync_conversation_card_job` (espelho), serviço aplicador de label, FE sidebar/card + i18n. **Risco:** baixo (WA, aditivo); médio (FB/IG toca OSS core).

---

## Ponto 7 — Atributos custom usados pelas IAs de CRM

**Causa-raiz.** O pipeline de IA de CRM recebe só o **schema** dos atributos (onde extrair), não os **valores já preenchidos**:
- `app/services/crm/ai/context_builder.rb:10-20,42-54` monta contexto (summary/recent_messages/current_stage/temporal) — **sem** `custom_attributes`.
- `app/services/crm/ai/stage_classifier.rb:117-136` inclui `attribute_schema` (definição), **não** os valores de contact/conversation.
- `app/services/crm/ai/classifier_prompt.rb:86-104` só instrui **extrair** novos valores; não **ler** os existentes.

Efeito: a IA decide estágio/handoff sem o contexto de negócio (Indústria, Orçamento, Prazo) que o humano vê.

**Abordagem:** `ContextBuilder` ganha `existing_attributes` (contact + conversation `custom_attributes`, filtrando vazios); `StageClassifier#user_input` passa `attributes`; `classifier_prompt` ganha seção EXISTING_ATTRS (prefixo estável p/ cache; valores vão no input dinâmico, não no prefixo). **Framing como DADO não-instrução** (anti-injeção). **Arquivos:** `context_builder.rb`, `stage_classifier.rb`, `classifier_prompt.rb`. **Esforço:** M. **Risco:** médio (bloat de token → filtrar vazios/truncar; injeção → framing). **Escopo aberto:** avaliar se o Copiloto/`autonomia/*` também deve receber (este ponto é CRM-classificação).

---

## Ponto 8 — Gestão de IA mostra o gasto do "período caro" (REENQUADRADO pelo PO)

**Reenquadramento (PO 04/jul):** o pedido **não** é reverter o corte de custo (o `xhigh→high` fica). O pedido é que a tela de **Gestão de IA (uso)** pare de **exibir** o gasto do período caro (antes de 30/jun). Isto é **corte de exibição por data**, não `reasoning_effort`.

**Achado: o corte de exibição JÁ EXISTE e está correto/testado — só não foi ligado em produção.**
- Mecanismo: `app/services/crm/reports/ai_usage.rb:46-48` — `since` efetivo = `max(janela pedida pela UI, ENV['CRM_AI_USAGE_BASELINE_AT'])`. O piso propaga para **todos** os agregados (totais, gráfico, ranking por recurso, histórico, cache-savings) via `usage_scope` (`:50-55`). Introduzido no commit **`1b06fbe87` (#48, 30/jun 15:27)** — *"baseline p/ zerar cronômetro da Gestão de IA… esconde telemetria pré-fix… nada é apagado"*. Spec cobre (`spec/services/crm/reports/ai_usage_spec.rb:104-124`).
- **Causa-raiz do que o PO vê:** `CRM_AI_USAGE_BASELINE_AT` **não está setada em produção** e **não está versionada** (não aparece em `.env.example`, Dockerfile, compose, deploy — só na definição + spec). Sem ela, o default é "sem piso" → a janela de 30 dias ainda alcança o fim de junho (caro). Pode nunca ter sido setada, ou ter sido apagada num `updateEnv` que omitiu o campo `env` (lição M11b).

**Fix (2 partes):**
- **(A) Operação — 🔴 Vermelha:** setar `CRM_AI_USAGE_BASELINE_AT=2026-06-30T00:00:00-03:00` nos **2 stacks** (autonomia + hub2you). Regras: backup do env ANTES · NUNCA omitir `env` no `updateEnv` · offset de timezone explícito (`parse_time` usa `Time.zone.parse`) · validar healthz + conferir que a página escondeu o pré-30/jun. Dado **não é apagado** (append-only) — remover a ENV restaura a janela cheia.
- **(B) Código — P (causa-raiz da fragilidade):** versionar a var em `.env.example` + doc de deploy dos stacks, pra não sumir num redeploy. Este é o único código (1 linha) e é o que impede a regressão de voltar.

**Nota lateral (não é o pedido):** os `*_REASONING_EFFORT` seguem hardcoded (`config.rb:24-28`); torná-los ajustáveis por ENV (default `high`) continua como pendência separada — ver [[pending-reasoning-effort-env]]. **Independente deste ponto.**

**Esforço:** A = P (operação nos 2 stacks) · B = P (1 linha + doc). **Risco:** código nulo (já testado em prod); operacional médio (write de env prod, backup obrigatório).

---

## Ponto 9 — Fluxo KB-first na criação do agente

**Causa-raiz do incômodo.** O builder é página única com passos internos (`AgentBuilderPage.vue`). No passo "conversa" há **grid de 2 colunas** (`:562-649`): esquerda `BuilderChat` (chat), direita `BuilderKnowledgePanel` (KB) — **os dois juntos** confundem. Os sinais `actuation` (internal/external) e `withKnowledge` já são capturados (`AgentTypePicker.vue:100-105`).

**Bloqueador de arquitetura:** hoje o **draft do agente nasce no 1º turno do chat** (`AgentBuilderPage.vue:104-112`). KB-first esconde o chat → **não há draft pra anexar fontes** (`BuilderKnowledgePanel.vue:104-105` exige `agentId`). Resolver "criar draft antes do chat" é a porta para (a)/(c)/(d)/(e).

**Viabilidade por requisito:**
- **(a)** só KB primeiro (esconder chat) p/ internal/+KB: M FE + S/M BE (garantir draft-id cedo). Risco médio (a lógica de limpeza de draft vazio depende do "draft no 1º turno").
- **(b)** msg "até 5 min": **P/S** (i18n + render). Sem risco.
- **(c)** limite 30 bases: precisa **guard server-side** em `sources_controller#create` (hoje sem limite) + FE desabilitar dropzone em 30. S+S. **Confirmar definição:** conta linhas `Source kind:knowledge`?
- **(d)** auto-abrir chat ao terminar: M. Sinal "pronto" já existe (`autonomiaSources.js:80-87 getAllReviewed` + `knowledge_confidence`). Tratar falha/skip (fallback "abrir chat agora").
- **(e)** builder já conhece a base: **retrieval já satisfaz** (Playground roda pipeline contra entries aceitos). Falta só semear a **entrevista** do construtor com `knowledge_summary` (L, reordena o "IA fala primeiro").

**Decisões PO (04/jul — resolvidas, ver mockup seção 2):**
1. **Gatilho = `withKnowledge===true`** (interno **E** externo). Se o usuário pediu "com base", pede a base primeiro. `actuation` não importa.
2. **Botão "Pular e ir para o agente"** sempre visível — resolve tanto "desistiu da base" quanto "fonte falhou / não subiu nada" (unblock manual, sem timeout).
3. **Limite 30** = 30 linhas `Source` (kind knowledge); dropzone desabilita em 30. (mídia fora.)
- Ainda vale o bloqueador técnico: **criar o draft do agente antes do chat** (hoje nasce no 1º turno) — pré-requisito de anexar fontes na tela KB-first.

**Arquivos-chave:** `AgentBuilderPage.vue`, `BuilderKnowledgePanel.vue`, `AgentTypePicker.vue`, `autonomiaSources.js`, `sources_controller.rb`, `playground_controller.rb`, i18n. **Esforço:** M–L. **Risco:** médio.

---

## Sequenciamento e worktrees

Cada track = **branch/worktree própria** (`git worktree`), merge agrupado por onda para 1 deploy limpo (evita cascata blue-green — ver [[deploy-stacked-prs-cascade]]).

**Onda 0 — Config imediata (sem código, alto valor):**
- **P8-A**: setar `CRM_AI_USAGE_BASELINE_AT=2026-06-30` nos 2 stacks (🔴 Vermelha, backup env antes). Esconde o período caro **hoje**, sem deploy.

**Onda A — Quick wins (código, baixo risco):**
- P4 badge funil (S) · P3 ativar agente (S) · P6 CTWA referral→label/Kanban (S–M) · P8-B versionar a ENV no `.env.example` (P).
- 1 PR cada ou 1 PR combinado FE; Codex review; merge agrupado → 1 deploy.

**Onda B — Projetos de código (médio):**
- P1b onboarding MS/Google (M) · P7 custom attrs → IA (M) · P5 eventos CRM→automação, trilho A+B (M–L) · P6 LP→WhatsApp parser (S, após marketing padronizar links) · P9 KB-first (M–L, **após responder 3 perguntas de PO**).

**Onda C — Ops/Infra (não são PRs de código):**
- P1 e-mail conta 6 (probe prod DB + decisão trilho) · P2 SES hub2you (decisão autonomia-clone vs from-scratch → criar identidades + DNS + reabrir produção). Issues de Ops com checklist e 🟢 por ação (DNS/infra).

**Fora de escopo agora (honesto):** P6-Google (sem canal de entrada) · P6-FB/IG paridade (M, opcional) · P8 reasoning_effort por ENV (pendência separada).

**Cross-project safety (VPS multi-tenant):** mudanças em dispatcher/automação (P5) e SES/DNS (P2) tocam base compartilhada — gatear atrás de `Crm::Config.enabled?`, feature flag, e nunca omitir `env` em updates de infra. Reviewer + tester antes de merge ≥30 linhas.
