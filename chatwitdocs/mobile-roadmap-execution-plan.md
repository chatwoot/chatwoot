# Chatwit Mobile PWA — Plano de Execução do Roadmap

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. **Toda task DEVE rodar com a skill `mobile-mod-agent-chatwit` carregada** (isolamento desktop, conectar-não-recriar).

**Goal:** Executar 100% do roadmap `chatwitdocs/mobile-roadmap.md` — paridade com o app nativo (Fases 1–2) e superpoderes PWA (Fase 3) — sem nenhuma regressão desktop.

**Architecture:** Cada item é uma camada visual mobile em `components-next/mobile/` que CONECTA stores/composables/APIs já existentes do desktop (mapeados abaixo por item, com action/getter exatos). Nada de lógica nova de negócio; push é VAPID-only.

**Tech Stack:** Vue 3 `<script setup>` + Tailwind only + Vuex stores existentes + Web Platform APIs (Badging, Notification actions, SW cache, Background Sync, View Transitions).

**Spec de origem:** `chatwitdocs/mobile-roadmap.md` (tabelas Fase 1/2/3, fora-de-escopo e critérios de aceitação).

---

## Regras transversais (valem para TODAS as tasks)

1. **Isolamento:** código novo só em `app/javascript/dashboard/components-next/mobile/` (+ `public/sw.js`/`public/manifest.json` nas tasks de PWA, que são plataforma-neutras e não afetam desktop). Nunca editar componentes desktop; se precisar de guard em componente compartilhado, guard mínimo sem mudança de comportamento desktop.
2. **Conectar:** usar exatamente os stores/actions/getters listados na task. Se algo não bater com o código real, PARAR e procurar a fonte de verdade desktop antes de inventar.
3. **Haptics:** toda superfície tocável nova recebe `v-haptic-tap` (de `components-next/mobile/hapticTap.js`) no elemento nativo + chamada `useHaptics()` síncrona no handler (nunca após `await`). Fundamento: iOS 26.5 patcheou o haptic programático; ver seção técnica no roadmap.
4. **i18n:** toda string nova em `locale/en/mobile.json`, `locale/pt/mobile.json` e `locale/pt_BR/mobile.json` (mesmas chaves nos 3).
5. **Validação por task:** `npx eslint <arquivos tocados>` limpo; teste manual mobile (<768px) E desktop (≥768px) sem regressão; depois changelog em `chatwitdocs/Chatwoot-Chatwit-mobile.md`.
6. **Branch/commit:** uma branch por lote (`claude/mobile-<lote>`), Conventional Commits `feat(mobile): ...`, sem referência a Claude.
7. **Ordem dentro de cada task:** (a) ler os arquivos desktop listados; (b) criar componente mobile; (c) conectar store; (d) i18n; (e) eslint; (f) teste manual; (g) changelog; (h) commit.

## Ordem de execução (lotes = branches/PRs)

| Lote | Itens (nº do roadmap) | Racional |
|------|----------------------|----------|
| A — quick wins | 12 badge, 6 filtro inbox, 19 câmera, 16 shortcuts | Esforço P, impacto imediato de "app de verdade" |
| B — imersão | 4 lightbox, 5 snooze custom | Mata os dois maiores "isso é um site" |
| C — dados do contato | 3 detalhes do contato, 9 labels do contato | Mesmo domínio (stores `contacts`/`contactLabels`), uma tela serve os dois |
| D — produtividade | 2 busca, 1 @menções | Os dois M/G de Fase 1 |
| E — complementos | 7 macros, 8 prefs de notificação, 10 transcript, 11 read receipts | Fase 2 restante |
| F — push & navegação | 13 ações no push, 18 view transitions | SW + transições, riscos isolados |
| G — offline | 14 shell offline, 15 fila de envio | Os mais arriscados por último, base já estável |
| H — Android extras | 17 share target | Depende de manifest já mexido em A/16 |

---

# LOTE A — Quick wins

### Task 12: Badge de não lidas no ícone do app

**Files:**
- Create: `app/javascript/dashboard/components-next/mobile/useAppBadge.js`
- Modify: `app/javascript/dashboard/components-next/mobile/MobileLayout.vue` (montar o composable)
- Modify: `public/sw.js` (badge no push e no notificationclick)

**Fonte desktop:** getter `notifications/getUnreadCount` (o mesmo já usado em `MobileBottomTabBar.vue:18`).

- [ ] **Step 1: composable que espelha o unread count no ícone**

```js
// components-next/mobile/useAppBadge.js
import { watch } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';

// iOS 16.4+ (PWA instalado) e Chrome/Android expõem a Badging API.
const canBadge = () =>
  typeof navigator !== 'undefined' && 'setAppBadge' in navigator;

export const useAppBadge = () => {
  if (!canBadge()) return;
  const unreadCount = useMapGetter('notifications/getUnreadCount');
  watch(
    unreadCount,
    count => {
      if (count > 0) navigator.setAppBadge(count).catch(() => {});
      else navigator.clearAppBadge().catch(() => {});
    },
    { immediate: true }
  );
};
```

- [ ] **Step 2: montar em `MobileLayout.vue`** — no `<script setup>`, `import { useAppBadge } from './useAppBadge';` e chamar `useAppBadge();` no topo (roda só quando o layout mobile existe → zero efeito desktop).
- [ ] **Step 3: badge no SW** — em `public/sw.js`, dentro do handler `push` (após montar a notificação), incrementar via `self.navigator.setAppBadge?.()` sem contagem precisa não é possível; usar o campo `unread_count` se presente no payload, senão `navigator.setAppBadge()` (badge "dot"). No `notificationclick`, `self.navigator.clearAppBadge?.()` não deve ser chamado (quem limpa é o app ao carregar via Step 1). Manter mudanças no SW puramente aditivas.
- [ ] **Step 4: validar** — eslint nos arquivos; instalar PWA no iPhone, receber push com app fechado → badge aparece; abrir app e ler → badge some. Desktop inalterado.
- [ ] **Step 5: changelog + commit** `feat(mobile): app icon unread badge via Badging API`

### Task 6: Filtro por inbox na lista de conversas

**Files:**
- Modify: `app/javascript/dashboard/components-next/mobile/MobileFilterSheet.vue` (nova seção "Inbox")
- Modify: `app/javascript/dashboard/components-next/mobile/MobileConversationList.vue` (estado + param da busca)

**Fonte desktop:** getter `inboxes/getInboxes`; a action de fetch da lista mobile já aceita `inboxId` (mesmo contrato de `conversations/fetchAllConversations`, que lê `inboxId` dos `conversationFilters`).

- [ ] **Step 1:** em `MobileConversationList.vue`, adicionar `const selectedInboxId = ref(0);` e incluir `inboxId: selectedInboxId.value || undefined` no payload do fetch existente (mesmo lugar onde já vão `status`/`assigneeType`); resetar paginação ao mudar.
- [ ] **Step 2:** em `MobileFilterSheet.vue`, nova seção com lista de inboxes (`useMapGetter('inboxes/getInboxes')`), opção "Todas" (id 0) + uma linha por inbox (nome + ícone do canal), `v-haptic-tap` + `selection()` no tap, emit `update:inboxId`.
- [ ] **Step 3:** i18n `MOBILE.FILTERS.INBOX.TITLE`, `MOBILE.FILTERS.INBOX.ALL` nos 3 idiomas.
- [ ] **Step 4:** validar (eslint, mobile: filtrar por inbox atualiza lista; desktop intocado), changelog, commit `feat(mobile): inbox filter in conversation list`.

### Task 19: Captura direta de câmera no composer

**Files:**
- Modify: `app/javascript/dashboard/components-next/mobile/MobileReplyBox.vue`

**Fonte desktop:** o mesmo fluxo de upload do `fileInput` existente (`onFileChange` → `DirectUpload`/`FileReader`, linha ~253).

- [ ] **Step 1:** segundo input oculto `<input ref="cameraInput" type="file" accept="image/*" capture="environment" class="hidden" @change="onFileChange" />` (reusa `onFileChange` literal).
- [ ] **Step 2:** botão câmera ao lado do clipe (ícone `i-lucide-camera`, mesmo estilo do botão attach), `v-haptic-tap`, `@click="cameraInput?.click()"` com `light()` no handler. i18n do `aria-label`: `MOBILE.REPLY.CAMERA`.
- [ ] **Step 3:** validar (iPhone: abre câmera direto; arquivo cai no mesmo preview de anexo), changelog, commit `feat(mobile): direct camera capture in composer`.

### Task 16: Atalhos do ícone (manifest shortcuts)

**Files:**
- Modify: `public/manifest.json`

- [ ] **Step 1:** adicionar ao manifest:

```json
"shortcuts": [
  { "name": "Conversas", "url": "/?mobile_tab=conversations", "icons": [{ "src": "/favicon-96x96.png", "sizes": "96x96" }] },
  { "name": "Inbox", "url": "/?mobile_tab=inbox", "icons": [{ "src": "/favicon-96x96.png", "sizes": "96x96" }] }
]
```

(usar ícones que já existam em `public/`; conferir nomes reais antes).
- [ ] **Step 2:** em `MobileLayout.vue`, ler `mobile_tab` da query string no mount e ativar a tab correspondente (mapa `{ inbox: 0, conversations: 1, settings: 2 }`), removendo o param da URL via `history.replaceState`. Android only por plataforma; iOS ignora silenciosamente.
- [ ] **Step 3:** validar (Android: long-press no ícone mostra atalhos; desktop e iOS sem efeito), changelog, commit `feat(mobile): manifest shortcuts for icon long-press`.

---

# LOTE B — Imersão

### Task 4: Lightbox de imagens (fullscreen + zoom)

**Files:**
- Create: `app/javascript/dashboard/components-next/mobile/MobileImageLightbox.vue`
- Modify: o componente mobile que renderiza bolhas de imagem (localizar em `components-next/mobile/` quem renderiza attachments na conversa — hoje a imagem abre em nova aba)

**Fonte desktop:** `components/widgets/conversation/components/GalleryView.vue` — props `attachment`, `allAttachments`, `show` (v-model), emite `close`; já tem zoom/rotação/navegação.

- [ ] **Step 1:** PREFERIR reutilizar `GalleryView.vue` direto dentro de um wrapper mobile (`MobileImageLightbox.vue` só controla `show`/lista e adapta safe-areas/gestos de fechar por swipe-down). Só criar viewer próprio se o GalleryView depender de layout desktop que quebre <768px — nesse caso o wrapper replica a UX (pinch-zoom via `touch-action: pinch-zoom` + double-tap) mas continua usando os mesmos objetos `attachment` do payload da mensagem.
- [ ] **Step 2:** interceptar o tap na imagem da bolha mobile: em vez de `window.open`, abrir o lightbox com `allAttachments` = todas as imagens da conversa atual (filtrar `message.attachments` por `file_type === 'image'` nas mensagens carregadas).
- [ ] **Step 3:** haptics `light()` ao abrir/fechar + `v-haptic-tap` no botão fechar; i18n `MOBILE.LIGHTBOX.CLOSE`.
- [ ] **Step 4:** validar (zoom com 2 dedos, swipe entre imagens, fechar por swipe-down; desktop GalleryView intocado), changelog, commit `feat(mobile): fullscreen image lightbox with zoom`.

### Task 5: Snooze com horário customizado

**Files:**
- Create: `app/javascript/dashboard/components-next/mobile/MobileSnoozeSheet.vue`
- Modify: `app/javascript/dashboard/components-next/mobile/MobileConversationActionsView.vue` (status card Snooze abre o sheet) e `MobileConversationList.vue` (opção snoozed do `MobileConversationStatusSheet` abre o sheet)

**Fonte desktop:** `helper/snoozeHelpers.js` — `findSnoozeTime`, `generateSnoozeSuggestions`, `snoozedReopenTime`; modal desktop de referência `components/CustomSnoozeModal.vue`; action `toggleStatus` com `snoozedUntil` (já usada no mobile).

- [ ] **Step 1:** `MobileSnoozeSheet.vue` sobre `MobileBottomSheet`: opções `UNTIL_NEXT_REPLY`, `AN_HOUR_FROM_NOW`, `UNTIL_TOMORROW`, `UNTIL_NEXT_WEEK` (labels via i18n, horário calculado exibido ao lado via `snoozedReopenTime(findSnoozeTime(key))`) + opção "Escolher data e hora" com `<input type="datetime-local">` nativo (UI nativa iOS). Emite `select` com timestamp.
- [ ] **Step 2:** nos dois pontos de uso, trocar o snooze fixo atual por abrir o sheet; no select, despachar o `toggleStatus` existente com `snoozedUntil` do sheet (haptic `medium()` no tap da opção, `v-haptic-tap` nas linhas).
- [ ] **Step 3:** i18n `MOBILE.SNOOZE.*` (TITLE, NEXT_REPLY, AN_HOUR, TOMORROW, NEXT_WEEK, CUSTOM, CONFIRM) nos 3 idiomas.
- [ ] **Step 4:** validar + changelog + commit `feat(mobile): custom snooze time sheet`.

---

# LOTE C — Contato

### Task 3 + 9: Tela de detalhes do contato + labels do contato

**Files:**
- Create: `app/javascript/dashboard/components-next/mobile/MobileContactDetailsView.vue`
- Modify: `app/javascript/dashboard/components-next/mobile/MobileConversationActionsView.vue` (header do contato vira botão → abre a tela) e `MobileChatView.vue` (registrar a nova página/overlay)

**Fonte desktop:** `routes/dashboard/conversation/ContactPanel.vue`; actions `contacts/show`, `contacts/update`; `contactLabels/get`, `contactLabels/update`; referência RN `ContactDetailsScreen.tsx` (layout apenas).

- [ ] **Step 1:** view com: avatar+nome+canal, telefone/e-mail (tap = `tel:`/`mailto:`), atributos do contato, labels do contato (reusar `MobileMultiPickerSheet` com store `labels/getLabels` para opções e `contactLabels/update` no apply), conversas anteriores do contato (getter já usado pelo ContactPanel).
- [ ] **Step 2:** carregar via `store.dispatch('contacts/show', { id: contactId })` no mount; edição mínima (nome/e-mail/telefone) via `contacts/update` — happy path, sem formulário completo.
- [ ] **Step 3:** navegação: empurrada como página sobre a tela de ações (mesmo padrão de transição do pager existente), back físico/edge-swipe volta.
- [ ] **Step 4:** `v-haptic-tap` em todas as linhas tocáveis; i18n `MOBILE.CONTACT.*`; validar; changelog; commit `feat(mobile): contact details screen with contact labels`.

---

# LOTE D — Produtividade

### Task 2: Busca de conversas/mensagens

**Files:**
- Create: `app/javascript/dashboard/components-next/mobile/MobileSearchView.vue`
- Modify: `app/javascript/dashboard/components-next/mobile/MobileConversationHeader.vue` (ícone lupa abre busca)

**Fonte desktop:** store `conversationSearch` — actions `fullSearch`, `clearSearchResults`; getters `getConversationRecords`, `getMessageRecords`, `getContactRecords`, `getUIFlags`; UI de referência `modules/search/components/SearchView.vue`.

- [ ] **Step 1:** view fullscreen com input no topo (autofocus, debounce 300ms via `useDebounceFn` do `@vueuse/core` já usado no projeto), dispatch `conversationSearch/fullSearch` com `{ q }`; `clearSearchResults` ao fechar.
- [ ] **Step 2:** resultados em 3 grupos (Conversas / Mensagens / Contatos) usando os getters acima; tap em resultado navega para a conversa (mesma navegação por URL já usada na lista) — `v-haptic-tap` + `selection()`.
- [ ] **Step 3:** estados: vazio ("digite para buscar"), carregando (reusar `MobilePetalLoader`), sem resultados. i18n `MOBILE.SEARCH.*`.
- [ ] **Step 4:** validar + changelog + commit `feat(mobile): conversation and message search`.

### Task 1: @Menções em notas privadas

**Files:**
- Modify: `app/javascript/dashboard/components-next/mobile/MobileReplyBox.vue`
- Create: `app/javascript/dashboard/components-next/mobile/MobileMentionSheet.vue` (lista de agentes ancorada acima do teclado)

**Fonte desktop:** `components/widgets/conversation/TagAgents.vue` (getter `agents/getVerifiedAgents`, emite `selectAgent`); formato de menção que o backend espera: o mesmo que o ReplyBox desktop produz — **ler o ReplyBox desktop antes para copiar o formato exato do markdown de menção** (`[@Nome](mention://user/<id>/<nome>)`).

- [ ] **Step 1:** no textarea do modo nota privada, detectar `@` no cursor (regex no `input` event sobre o trecho até o cursor: `/@([\w]*)$/`), abrir `MobileMentionSheet` filtrando `agents/getVerifiedAgents` pelo termo.
- [ ] **Step 2:** ao selecionar (tap com `v-haptic-tap` + `selection()`), substituir o trecho `@termo` pelo markdown de menção do desktop e devolver foco ao textarea com cursor após a menção.
- [ ] **Step 3:** só ativo quando `effectivePrivate === true` (menção não existe em resposta pública). i18n `MOBILE.MENTIONS.TITLE`/`EMPTY`.
- [ ] **Step 4:** validar (a menção notifica o agente como no desktop — conferir no sino/notificação), changelog, commit `feat(mobile): agent mentions in private notes`.

---

# LOTE E — Complementos (Fase 2)

### Task 7: Execução de macros

**Files:**
- Create: `app/javascript/dashboard/components-next/mobile/MobileMacrosSheet.vue`
- Modify: `MobileConversationActionsView.vue` (linha "Macros" na seção MORE)

**Fonte desktop:** store `macros` — `macros/get` (lista), `macros/execute` (rodar na conversa); getter `macros/getMacros`; UI de referência: `MacrosList` dentro do `ContactPanel.vue`.

- [ ] **Step 1:** sheet listando `getMacros` (dispatch `macros/get` no open); tap (`v-haptic-tap` + `medium()`) → `store.dispatch('macros/execute', { macroId, conversationIds: [conversationId] })` (conferir assinatura real na store antes) → toast de sucesso.
- [ ] **Step 2:** i18n `MOBILE.MACROS.*`; validar; changelog; commit `feat(mobile): run macros from conversation actions`.

### Task 8: Preferências de notificação

**Files:**
- Create: `app/javascript/dashboard/components-next/mobile/MobileNotificationPrefsView.vue`
- Modify: `MobileSettingsView.vue` (nova linha "Notificações")

**Fonte desktop:** store `userNotificationSettings` — `get`, `update`; getters `getSelectedEmailFlags`, `getSelectedPushFlags`; UI de referência `routes/dashboard/settings/profile/NotificationPreferences.vue`.

- [ ] **Step 1:** view com toggles agrupados (E-mail / Push) espelhando as flags do desktop; cada toggle dispara `userNotificationSettings/update` com o set completo de flags (mesmo contrato do desktop); `v-haptic-tap` + `selection()` nos toggles.
- [ ] **Step 2:** i18n `MOBILE.NOTIF_PREFS.*` (títulos de grupo; labels de flag podem reusar chaves desktop existentes se já houver); validar; changelog; commit `feat(mobile): notification preferences screen`.

### Task 10: Transcript por e-mail

**Files:**
- Modify: `MobileConversationActionsView.vue` (linha "Enviar transcript" na seção MORE + mini-sheet com input de e-mail)

**Fonte desktop:** action `conversations/sendEmailTranscript` (store `conversations/actions.js:462`; API `sendEmailTranscript({ conversationId, email })`); modal de referência `EmailTranscriptModal.vue`.

- [ ] **Step 1:** linha com `v-haptic-tap` → sheet simples (input e-mail pré-preenchido com o e-mail do agente atual + botão enviar) → `store.dispatch('sendEmailTranscript', { conversationId, email })` → toast. i18n `MOBILE.ACTIONS.MORE.TRANSCRIPT*`.
- [ ] **Step 2:** validar; changelog; commit `feat(mobile): email transcript action`.

### Task 11: Read receipts completos (✓✓ azul)

**Files:**
- Modify: o componente mobile de bolha que mostra status de entrega (localizar onde o mobile renderiza o tick atual)

**Fonte desktop:** `components-next/message/MessageStatus.vue`; constantes `shared/constants/messages.js` (`MESSAGE_STATUS.SENT/DELIVERED/READ`).

- [ ] **Step 1:** PREFERIR importar `MessageStatus.vue` direto na bolha mobile (é components-next, mobile-safe). Se o mobile já desenha ticks próprios, alinhar o mapeamento: sent = ✓ cinza, delivered = ✓✓ cinza, read = ✓✓ azul (`message.status` do payload — sem chamadas novas).
- [ ] **Step 2:** validar nos canais que reportam read (WhatsApp); changelog; commit `feat(mobile): full read receipts with blue double check`.

---

# LOTE F — Push & navegação

### Task 13: Ações nos push notifications (Android)

**Files:**
- Modify: `public/sw.js`

**Estado atual:** o SW **já monta** actions (REPLY, MARK_READ, OPEN — linhas ~73-80) e recebe `reply_enabled`/`notification_id` no payload.

- [ ] **Step 1:** auditar o handler `notificationclick`: garantir que `action === 'reply'` (com `event.reply` do inline reply Android) poste a resposta via fetch à API com o token disponível ao SW, e `mark_read` marque a notificação lida; o que faltar, completar usando os endpoints que o app já usa (conferir `pushHelper.js` e os endpoints de notifications). iOS ignora actions — sem fallback necessário.
- [ ] **Step 2:** testar em Android real/emulado (push com botões; Resolver/Responder funcionam com app fechado); changelog; commit `feat(mobile): actionable push notifications on Android`.

### Task 18: View Transitions lista↔chat

**Files:**
- Modify: `MobileLayout.vue` / `MobileChatView.vue` (pontos onde a navegação por URL acontece)

- [ ] **Step 1:** wrapper utilitário local (função no próprio componente ou `components-next/mobile/useViewTransition.js`): `const navigate = fn => (document.startViewTransition ? document.startViewTransition(fn) : fn());` aplicado às trocas lista→chat e chat→lista. Progressive enhancement puro — sem `document.startViewTransition`, comportamento idêntico ao atual.
- [ ] **Step 2:** `view-transition-name` via classes utilitárias apenas em elementos mobile (ex.: avatar da conversa) se o efeito ficar bom; caso contrário, transição de root já basta. NUNCA tocar transição desktop.
- [ ] **Step 3:** validar (Safari 18+/Chrome: transição suave; browsers antigos: sem mudança); changelog; commit `feat(mobile): view transitions between list and chat`.

---

# LOTE G — Offline

### Task 14: Shell offline + cache

**Files:**
- Modify: `public/sw.js`

- [ ] **Step 1:** estratégia mínima sem Workbox: no `install`, `cache.addAll` do shell (`/`, manifest, ícones); no `fetch`, network-first com fallback a cache para navegação (`request.mode === 'navigate'`) e stale-while-revalidate para assets do Vite (`/vite/assets/`). **Nunca** cachear chamadas de API (`/api/`).
- [ ] **Step 2:** snapshot leve das últimas conversas: ao renderizar a lista, `MobileConversationList.vue` salva um JSON enxuto (id, nome, último texto, timestamp) em `localStorage` (`chatwit_mobile_last_conversations`); offline, a lista renderiza o snapshot com banner "sem conexão" (i18n `MOBILE.OFFLINE.BANNER`).
- [ ] **Step 3:** versionar o cache (`chatwit-shell-v1`) e limpar versões antigas no `activate`. Validar: modo avião → app abre, mostra shell + snapshot; rede volta → dados frescos. Desktop não usa o SW para nada novo além do que já usava. Changelog; commit `feat(mobile): offline shell and conversation snapshot`.

### Task 15: Fila offline de envio

**Files:**
- Create: `app/javascript/dashboard/components-next/mobile/useOfflineQueue.js`
- Modify: `MobileReplyBox.vue`

- [ ] **Step 1:** composable com fila em `localStorage` (`chatwit_mobile_outbox`): `enqueue(payload)`, `flush()` (tenta despachar cada item via o MESMO `store.dispatch('createPendingMessageAndSend', payload)` do envio normal), listener de `online` + flush no mount.
- [ ] **Step 2:** em `onSend`, se `!navigator.onLine`, `enqueue` + bolha local com estado "aguardando conexão" (i18n `MOBILE.OFFLINE.QUEUED`); quando `flush` enviar, o fluxo normal do store substitui a pendente.
- [ ] **Step 3:** somente texto no MVP (anexos exigem blob persistente — fora do happy path; documentar a limitação no changelog). Validar (modo avião → enviar → volta rede → mensagem sai sozinha); commit `feat(mobile): offline send queue for text messages`.

---

# LOTE H — Android extras

### Task 17: Compartilhar PARA o Chatwit (share target)

**Files:**
- Modify: `public/manifest.json` (share_target), `MobileLayout.vue` (rota de recepção)

- [ ] **Step 1:** manifest: `"share_target": { "action": "/?mobile_share=1", "method": "GET", "params": { "title": "title", "text": "text", "url": "url" } }` (GET/texto no MVP; arquivos exigem method POST + SW — fase posterior se houver demanda).
- [ ] **Step 2:** `MobileLayout.vue`: ao montar com `mobile_share=1`, abrir a tab Conversas com um sheet "Compartilhar em..." que lista conversas recentes; ao escolher, prefill do composer com o texto/URL compartilhado (sem envio automático). `v-haptic-tap` nas linhas; i18n `MOBILE.SHARE_TARGET.*`.
- [ ] **Step 3:** validar em Android (share de outro app lista o Chatwit); iOS/desktop sem efeito; changelog; commit `feat(mobile): Android share target into conversations`.

---

## Critérios de aceitação globais (gate de cada PR)

1. Zero regressão desktop (smoke manual ≥768px: sidebar, lista, chat, composer).
2. PR aponta explicitamente qual store/action/composable desktop foi reutilizado por item.
3. `v-haptic-tap` + `useHaptics()` no handler em toda superfície nova; nunca haptic após `await`.
4. i18n nos 3 bundles; Tailwind only; eslint limpo nos arquivos tocados.
5. Entrada no changelog de `Chatwoot-Chatwit-mobile.md`; atualizar a tabela do `mobile-roadmap.md` marcando o item como entregue.

## Fora de escopo (reafirmado do roadmap)

Widget "Chat with us"/branding Chatwoot, localização, edição de mensagem enviada, CSAT do agente — **não implementar** mesmo que pareça fácil.
