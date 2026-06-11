# Chatwit Mobile PWA — Roadmap

> **Status:** Vivo (atualizar a cada entrega)
> **Última revisão:** 2026-06-11
> **Doc principal:** `chatwitdocs/Chatwoot-Chatwit-mobile.md` (regras de isolamento, arquitetura, changelog)

Este documento consolida a auditoria de paridade entre o app nativo oficial (React Native, referência em `chatwitdocs/chatwoot-mobile-app/`) e o PWA do Chatwit, e define o roadmap para deixar o PWA **igual ou melhor** que o app nativo.

**Regras inegociáveis (resumo — detalhes no doc principal):**
1. Isolamento total do desktop — tudo vive em `components-next/mobile/` atrás de `isSmallScreen`.
2. CONECTAR, não recriar — toda feature mobile usa stores/composables/APIs que o desktop já tem.
3. Nada de branding/serviços do produto Chatwoot (ex.: "Chat with us") — o RN é referência de layout/ergonomia, nunca de lógica.
4. i18n sempre em `en`, `pt` e `pt_BR` (`locale/*/mobile.json`); Tailwind only.

---

## Estado atual (2026-06-11)

Coberto e em produção:

- **Listas:** conversas + inbox com scroll infinito, pull-to-refresh (petal loader), swipe actions (status/resolver/reabrir, lido/não lido), filtros (status, assignee Me/Unassigned/All, ordenação), badge de não lidas na tab, animação de montagem "lego" (TransitionGroup stagger + FLIP spring, paridade com `LinearTransition.springify()` do FlashList).
- **Chat:** pager de 2 páginas (mensagens + ações), reply box com nota privada/resposta pública, canned responses (`/`), gravação de áudio, anexos (arquivo/imagem/documento), templates WhatsApp, indicador de digitação, context menu por long-press (copiar/traduzir/deletar/responder), status de entrega, mensagens de atividade/sistema/bot, e-mail com citações.
- **Ações da conversa:** status cards (Open/Pending/Snooze/Resolve) com modal de atributos obrigatórios, assignee/team/priority via sheets, labels e participantes multi-select, atributos custom, **mute/unmute**, **compartilhar link** (share sheet nativa via `navigator.share`).
- **Settings:** perfil, disponibilidade (Online/Busy/Offline), idioma, toggle de push (Web Push VAPID), toggle InfinitePay push-only, logout.
- **Plataforma:** haptics estilo UIKit disparados no gesto (impact/selection/notification via switch-control WebKit no iOS + Vibration API no Android), edge-swipe back, teclado virtual com resize, safe areas, dark mode, RTL.

### Fundamento técnico — haptics no iOS (base Apple/WebKit)

- O iOS **não implementa** a Vibration API (`navigator.vibrate`). O único caminho web para o Taptic Engine é o **switch control** do Safari/iOS 17.4+ (`<input type="checkbox" switch>`): alternar o checkbox dispara o haptic do sistema.
- O toggle precisa ocorrer **dentro de transient user activation** (modelo de ativação do HTML spec implementado pelo WebKit). A ativação **expira após um `await`** — por isso todo haptic do módulo dispara no momento do toque, nunca após a resposta da API.
- Implementação central em `dashboard/composables/useHaptics.js` (switch persistente no `document.body`, bursts curtos emulando `UINotificationFeedbackGenerator`). Requisito do aparelho: iOS 17.4+, Ajustes → Sons e Tato → Resposta Háptica ativa.

---

## Fase 1 — Paridade restante de alto impacto

| # | Feature | Referência RN | Lógica desktop a conectar | Esforço | Impacto |
|---|---------|---------------|---------------------------|---------|---------|
| 1 | **@Menções em notas privadas** | `MentionUser.tsx` + mentions-input | `ReplyBox.vue` (fluxo de mention existente), store `agents` | M | Alto — colaboração entre agentes |
| 2 | **Busca de mensagens/conversas** | header de busca do ConversationScreen | store `conversationSearch` | M/G | Alto — achar conversa antiga no celular |
| 3 | **Detalhes do contato (tela/modal)** | `ContactDetailsScreen.tsx` | `ContactPanel.vue`, stores `contacts`, `contactLabels` | M | Alto — hoje o PWA mostra só o mínimo do remetente |
| 4 | **Lightbox de imagens (fullscreen + zoom)** | `ImageBubble.ios.tsx` | galeria/preview existente do desktop (components-next message) | M | Alto — hoje imagem abre fora do app, quebra a imersão |
| 5 | **Snooze com horário customizado** | `ConversationBasicActions.tsx` | `snoozeHelpers.js` (`findSnoozeTime` já aceita opções) | P/M | Médio — hoje só "até próxima resposta" |
| 6 | **Filtro por inbox na lista** | `InboxFilters.tsx` | store `inboxes` (getter já usado na lista) | P | Médio — multi-inbox sofre sem isso |

## Fase 2 — Paridade complementar

| # | Feature | Referência RN | Lógica desktop a conectar | Esforço | Impacto |
|---|---------|---------------|---------------------------|---------|---------|
| 7 | Execução de macros | `MacrosList.tsx` | store `macros` (`macros/get`, run) | P/M | Médio — power users |
| 8 | Preferências de notificação | `NotificationPreferences.tsx` | `NotificationPreferences.vue` + API existente | M | Médio |
| 9 | Labels do contato (além da conversa) | `ContactLabelActions.tsx` | store `contactLabels` | P | Baixo/Médio |
| 10 | Transcript por e-mail | — (desktop only) | `sendEmailTranscript` action | P | Baixo |
| 11 | Read receipts completos (READ p/ WhatsApp) | `DeliveryStatus.tsx` | status já presente no payload da mensagem | P | Baixo/Médio |

## Fase 3 — Superpoderes PWA (além do app nativo)

Capacidades da plataforma web que o PWA pode ter e que aproximam — ou superam — o app nativo. Estado atual do shell: `manifest.json` com `display: standalone`, SW com `push`/`notificationclick`; **sem** badge, shortcuts, share target ou offline.

| # | Capability | API / Suporte | O que entrega | Esforço |
|---|-----------|---------------|----------------|---------|
| 12 | **Badge no ícone do app** | `navigator.setAppBadge()` — iOS 16.4+ (PWA instalado) e Android/Chrome | Contador de não lidas no ícone da home screen, igual app nativo. Atualizar no push (SW) e ao ler conversas | P |
| 13 | **Ações nos push notifications** | `Notification.actions` — Android/Chrome (iOS ignora) | Botões "Resolver"/"Responder" direto na notificação | M |
| 14 | **Shell offline + cache** | SW precache (Workbox ou manual) | App abre instantâneo e mostra últimas conversas sem rede; elimina tela branca em rede ruim | M/G |
| 15 | **Fila offline de envio** | Background Sync API (Android); fallback retry em memória no iOS | Mensagem enviada sem rede sai quando a conexão volta | M |
| 16 | **Atalhos do ícone** | `manifest.shortcuts` — Android (iOS ignora) | Long-press no ícone → "Não atribuídas", "Inbox", "Nova conversa" | P |
| 17 | **Compartilhar PARA o Chatwit** | `manifest.share_target` — Android (iOS não suporta) | Compartilhar foto/arquivo de outro app direto para uma conversa | M |
| 18 | **Transições de página nativas** | View Transitions API — Safari 18+/Chrome | Transição suave lista↔chat↔ações, sensação de navegação nativa | M |
| 19 | **Captura direta de câmera** | `<input capture="environment">` | Botão "tirar foto" no composer abrindo a câmera direto | P |

> Itens 12–19 não existem no app RN da mesma forma (badge/push existem lá via APNs/FCM; aqui entregamos via web platform sem Firebase, mantendo a regra VAPID-only).

## Fora de escopo (decidido)

- **Widget/branding "Chat with us"** e qualquer fluxo de suporte do produto Chatwoot — proibido pela identidade do fork.
- **Compartilhamento de localização** (`LocationBubble.tsx`) — sem contraparte desktop; violaria "conectar, não recriar".
- **Edição de mensagem enviada** — o Chatwoot web não possui; sem fonte de verdade desktop.
- **CSAT no mobile do agente** — não existe no RN nem no fluxo do agente desktop.

## Critérios de aceitação (todo item do roadmap)

1. Zero regressão desktop (testar em ≥ 768px); código novo só em `components-next/mobile/` + composables de consumo mobile.
2. Store/action/composable desktop identificado e reutilizado (apontar no PR qual).
3. Haptics no gesto (nunca após `await`); i18n em `en`/`pt`/`pt_BR`; Tailwind only.
4. Entrada no changelog de `Chatwoot-Chatwit-mobile.md` ao concluir.
