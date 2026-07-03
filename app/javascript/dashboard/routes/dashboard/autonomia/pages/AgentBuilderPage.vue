<script setup>
import {
  ref,
  computed,
  watch,
  onMounted,
  onBeforeUnmount,
  nextTick,
} from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import AutonomiaBuilderImagesAPI from 'dashboard/api/autonomia/builderImages';

import NextButton from 'dashboard/components-next/button/Button.vue';
import BuilderStepBar from '../components/builder/BuilderStepBar.vue';
import BuilderChat from '../components/builder/BuilderChat.vue';
import BuilderKnowledgePanel from '../components/builder/BuilderKnowledgePanel.vue';
import BuilderReview from '../components/builder/BuilderReview.vue';
import AgentTypePicker from '../components/AgentTypePicker.vue';

// CONSTRUTOR — the conversational wizard, run as a SINGLE page with internal
// steps (`conversa | revisao`) rather than separate routes, because the
// thread/draft lives in the store and a route change would drop the session.
//
// STEP 1 ("Conversa + materiais", the approved mock) is a TWO-COLUMN view: the
// interview on the LEFT, a live knowledge panel on the RIGHT (drop files, see
// the Revisor's verdict inline). There is NO separate "materiais" step and no
// "tenho/não tenho materiais" buttons anymore — the Construtor confirms the
// knowledge state in the conversation and closes the instruction itself. When
// the build closes (phase `reviewing`) we move to STEP 2 (Revisão + Conectar).
//
// IP OCULTO: only human_card / greeting / starter_questions are ever read.
const route = useRoute();
const router = useRouter();
const { t } = useI18n();
const store = useStore();

// The chosen agent type. Seeded from the route query (when the user arrives with
// a type already picked) but held as a ref so the in-builder type picker can set
// it. While it is null we show the type picker as STEP 0 — this is the single
// entry point, reached both from the Hub's "create" button and the sidebar
// "Agent builder" link (which routes straight here without a type).
const agentType = ref(route.query.type || null);
// V2.1 — screen-level choices from the type picker; defaults reproduce today's behavior.
const actuation = ref('external');
const withKnowledge = ref(true);
const showPicker = computed(() => !agentType.value);

const thread = useMapGetter('autonomiaBuildThreads/getThread');
const messages = useMapGetter('autonomiaBuildThreads/getMessages');
const status = useMapGetter('autonomiaBuildThreads/getStatus');
const phase = useMapGetter('autonomiaBuildThreads/getPhase');
const buildError = useMapGetter('autonomiaBuildThreads/getError');
const generatedAgent = useMapGetter('autonomiaBuildThreads/getAgent');
const uiFlags = useMapGetter('autonomiaBuildThreads/getUIFlags');

const eligibleInboxes = useMapGetter('autonomiaChannels/getEligible');
const channelFlags = useMapGetter('autonomiaChannels/getUIFlags');
const sources = useMapGetter('autonomiaSources/getSources');
const sourceFlags = useMapGetter('autonomiaSources/getUIFlags');

// conversa <-> revisao. `phase` drives the transition; the materials panel rides
// alongside the conversation in the conversa step.
const wizardStep = ref('conversa');
const isSavingGreeting = ref(false);

// Step headings, focused on each transition for keyboard/screen-reader users.
const conversaHeadingRef = ref(null);
const revisaoStepRef = ref(null);

const threadId = computed(() => thread.value?.id);
const agentId = computed(
  () => thread.value?.agent_id || generatedAgent.value?.id || null
);

const isReviewing = computed(() => phase.value === 'reviewing');
const isProcessing = computed(() => status.value === 'processing');

// The chat is "busy" while creating the thread, sending, or while the backend
// build is still processing (the AI is thinking).
const isSending = computed(
  () => uiFlags.value?.sending || uiFlags.value?.creating || isProcessing.value
);

const errorMessage = computed(() => {
  if (buildError.value === 'timeout') return t('AGENTS.BUILDER.TIMEOUT');
  if (buildError.value === 'send') return t('AGENTS.BUILDER.SEND_ERROR');
  if (buildError.value || status.value === 'failed') {
    return t('AGENTS.BUILDER.FAILED');
  }
  return null;
});

// The composer clip stays available for the whole conversation (like any
// messenger). Uploads land as the agent's knowledge sources once a draft agent
// exists; before that, the attach handler nudges the user to start the chat.
const canAttachInChat = computed(
  () => wizardStep.value === 'conversa' && !isReviewing.value
);
const isAttachingInChat = computed(() => !!sourceFlags.value?.creatingItem);

// #3 INSTRUÇÃO VIVA (A): the draft agent exists after the first user turn but has
// NO instruction until the build closes. To guarantee "instruction always
// present", let the user force-close from step 1 — but only once they've engaged
// (>=1 user turn), mirroring the backend guard that creates the draft. This
// reuses the existing close path (completeMaterials -> force_close?); no new
// backend.
const hasUserEngaged = computed(() =>
  messages.value.some(message => message.role === 'user')
);
const finalizing = ref(false);
// Guard so the force-close finalize fires AT MOST once per session, no matter how
// the user leaves: the X button (`goToHub`), the explicit advance (`finalizeBuild`)
// and the route-change/unmount fallback (`onBeforeUnmount`) all share this flag.
const finalizeFired = ref(false);
const canAdvance = computed(
  () =>
    wizardStep.value === 'conversa' &&
    !isReviewing.value &&
    !isSending.value &&
    !finalizing.value &&
    hasUserEngaged.value &&
    !!agentId.value
);

const currentStep = computed(() => wizardStep.value);

const approvedCount = computed(
  () =>
    sources.value.filter(source => source.review?.status === 'accepted').length
);
const confidencePct = computed(() =>
  Math.round((generatedAgent.value?.config?.knowledge_confidence || 0) * 100)
);

// IA-FALA-PRIMEIRO: the thread is opened on mount WITHOUT a user message (only
// the chosen type), so the Construtor emits the opening turn (short greeting +
// first adaptation question). From then on every real user turn continues the
// thread via `send` — there is no longer a "first message opens the thread"
// branch, because the thread already exists by the time the user types.
const startThread = () =>
  store.dispatch('autonomiaBuildThreads/start', {
    type: agentType.value,
    actuation: actuation.value,
    with_knowledge: withKnowledge.value,
  });

// STEP 0 -> conversation: the user picked a type plus the actuation/knowledge
// choices. Persist them and open the thread WITHOUT a user message so the
// Construtor speaks first (IA-fala-primeiro).
const onPickType = ({
  type,
  actuation: pickedActuation,
  withKnowledge: pickedKnowledge,
}) => {
  agentType.value = type;
  if (pickedActuation) actuation.value = pickedActuation;
  if (typeof pickedKnowledge === 'boolean')
    withKnowledge.value = pickedKnowledge;
  startThread();
};

// MULTIMODAL (async): the build runs in a job, so attached images can't ride
// inline. Each is uploaded to ActiveStorage first; the returned `signed_id`s
// travel with the turn (`image_signed_ids`) and the Builder resolves them in the
// job to read them inline. Pure-text turns skip this entirely (images empty).
const uploadImages = async images => {
  if (!images?.length) return [];
  const results = await Promise.all(
    images.map(file => AutonomiaBuilderImagesAPI.upload(file))
  );
  return results.map(({ data }) => data.signed_id);
};

const handleSend = async ({ content, images = [] }) => {
  try {
    const imageSignedIds = await uploadImages(images);
    // Defensive: if the opening start failed (no thread yet), the user's first
    // typed turn re-opens the thread with their message.
    if (!threadId.value) {
      await store.dispatch('autonomiaBuildThreads/start', {
        type: agentType.value,
        actuation: actuation.value,
        with_knowledge: withKnowledge.value,
        message: content,
        image_signed_ids: imageSignedIds,
      });
      return;
    }
    await store.dispatch('autonomiaBuildThreads/send', {
      threadId: threadId.value,
      content,
      extra: { image_signed_ids: imageSignedIds },
    });
  } catch (error) {
    // 409: the previous build is still running — friendlier than a failure.
    if (error?.response?.status === 409) {
      useAlert(t('AGENTS.BUILDER.BUILD_IN_PROGRESS'));
    } else {
      useAlert(t('AGENTS.BUILDER.SEND_ERROR'));
    }
  }
};

// Attach from the composer clip: upload each file as a knowledge source via the
// same pipeline the panel uses. Needs a draft agent (created after the first
// message); before that, nudge the user to start the conversation.
const attachFromChat = async ({ files }) => {
  if (!files?.length) return;
  if (!agentId.value) {
    useAlert(t('AGENTS.MATERIALS.NEED_START'));
    return;
  }
  await Promise.all(
    files.map(file =>
      store
        .dispatch('autonomiaSources/create', {
          agentId: agentId.value,
          descriptor: { file, kind: 'knowledge' },
        })
        .catch(() => useAlert(t('AGENTS.MATERIALS.UPLOAD_ERROR')))
    )
  );
  useAlert(t('AGENTS.BUILDER.ATTACH.ATTACHED'));
};

// URL NA CONVERSA: quando o usuário cola um link e pede "aprenda do site", em
// vez de recusar oferecemos adicioná-lo como CONHECIMENTO (a ingestão segura já
// existe via store). O Construtor NÃO navega na web; ele apenas usa o link como
// fonte após a confirmação do usuário no chip abaixo do chat.
const URL_REGEX = /\bhttps?:\/\/[^\s<>"')]+/gi;

const dismissedUrls = ref(new Set());
const isAttachingUrl = ref(false);

const lastUserUrl = computed(() => {
  const lastUser = [...messages.value]
    .reverse()
    .find(message => message.role === 'user');
  if (!lastUser?.content) return null;
  const matches = lastUser.content.match(URL_REGEX);
  return matches ? matches[matches.length - 1].replace(/[.,;:]+$/, '') : null;
});

const urlAlreadySource = computed(() =>
  sources.value.some(
    source =>
      source.external_link === lastUserUrl.value ||
      source.reference === lastUserUrl.value
  )
);

const showUrlSuggestion = computed(
  () =>
    canAttachInChat.value &&
    !!agentId.value &&
    !!lastUserUrl.value &&
    !urlAlreadySource.value &&
    !dismissedUrls.value.has(lastUserUrl.value)
);

const agentName = computed(
  () =>
    generatedAgent.value?.config?.name ||
    generatedAgent.value?.name ||
    t('AGENTS.BUILDER.URL_SUGGEST.FALLBACK_NAME')
);

const addUrlAsKnowledge = async () => {
  const url = lastUserUrl.value;
  if (!url || !agentId.value || isAttachingUrl.value) return;
  isAttachingUrl.value = true;
  try {
    await store.dispatch('autonomiaSources/create', {
      agentId: agentId.value,
      descriptor: { url, kind: 'knowledge' },
    });
    dismissedUrls.value.add(url);
    useAlert(t('AGENTS.BUILDER.URL_SUGGEST.ADDED'));
  } catch (error) {
    useAlert(t('AGENTS.BUILDER.URL_SUGGEST.ERROR'));
  } finally {
    isAttachingUrl.value = false;
  }
};

const dismissUrlSuggestion = () => {
  if (lastUserUrl.value) dismissedUrls.value.add(lastUserUrl.value);
};

const saveGreeting = async greeting => {
  if (!agentId.value) return;
  isSavingGreeting.value = true;
  try {
    await store.dispatch('autonomiaAgents/update', {
      id: agentId.value,
      greeting,
    });
    useAlert(t('AGENTS.REVIEW.SAVED'));
  } catch (error) {
    useAlert(t('AGENTS.TUNE.SAVE_ERROR'));
  } finally {
    isSavingGreeting.value = false;
  }
};

const testAgent = () => {
  if (!agentId.value) return;
  router.push({
    name: 'autonomia_agent_panel',
    params: { agentId: agentId.value, tab: 'test' },
  });
};

const connectInbox = async inboxId => {
  if (!agentId.value || !inboxId) return;
  // O backend exige agente ativo para conectar — o wizard cria em rascunho,
  // então ativa antes; se a conexão falhar, volta pra rascunho (sem "zumbi"
  // ativo-sem-canal).
  let activated = false;
  try {
    await store.dispatch('autonomiaAgents/update', {
      id: agentId.value,
      enabled: true,
      status: 'active',
    });
    activated = true;
    await store.dispatch('autonomiaChannels/connect', {
      agentId: agentId.value,
      inboxId,
    });
    router.push({
      name: 'autonomia_agent_panel',
      params: { agentId: agentId.value, tab: 'test' },
    });
  } catch (error) {
    if (activated) {
      await store
        .dispatch('autonomiaAgents/update', {
          id: agentId.value,
          enabled: false,
          status: 'draft',
        })
        .catch(() => {});
    }
    useAlert(t('AGENTS.CHANNELS.CONNECT_ERROR'));
  }
};

// Agente interno (copiloto) recém-criado: sem canal para conectar, a revisão
// ativa direto — senão o wizard terminava com o agente preso em rascunho.
const activateInternal = async () => {
  if (!agentId.value) return;
  try {
    await store.dispatch('autonomiaAgents/update', {
      id: agentId.value,
      enabled: true,
      status: 'active',
    });
    useAlert(t('AGENTS.REVIEW.ACTIVATED_INTERNAL'));
    router.push({
      name: 'autonomia_agent_panel',
      params: { agentId: agentId.value, tab: 'test' },
    });
  } catch (error) {
    useAlert(t('AGENTS.CHANNELS.CONNECT_ERROR'));
  }
};

// "Voltar" from review goes back to the conversation (where the materials panel
// lives). The agent was already generated; the user can tweak materials and ask
// the Construtor to adjust, or re-confirm to close.
const backToConversa = () => {
  wizardStep.value = 'conversa';
};

// Retry from the error banner. If a thread exists, actually RE-RUN the build via
// the retry endpoint (a failed build never re-enqueued before — polling a
// `failed` thread just re-read the failure). If the server refuses (e.g. the
// build settled meanwhile or is still legitimately processing), fall back to
// polling so the UI converges. Otherwise the opening `start` failed before any
// thread existed: resend the last user turn if there is one, else re-open the
// thread from the chosen type (IA-fala-primeiro opening). Clears the error first.
const retryBuild = () => {
  store.commit('autonomiaBuildThreads/SET_ERROR', null);
  if (threadId.value) {
    store
      .dispatch('autonomiaBuildThreads/retry', { threadId: threadId.value })
      .catch(() =>
        store.dispatch('autonomiaBuildThreads/poll', {
          threadId: threadId.value,
        })
      );
    return;
  }
  const lastUser = [...messages.value]
    .reverse()
    .find(message => message.role === 'user');
  if (lastUser?.content) {
    // Retry resends text only; the original images (if any) were consumed by the
    // turn they accompanied and are not re-uploaded.
    handleSend({ content: lastUser.content, images: [] });
    return;
  }
  if (agentType.value) startThread();
};

// Fire-and-forget the force-close finalize turn. Single source of truth for the
// three exit paths (advance button, X button, route-change/unmount), guarded by
// `finalizeFired` so a draft is never finalized twice (e.g. X then unmount).
const fireFinalize = () => {
  if (finalizeFired.value || !threadId.value) return;
  finalizeFired.value = true;
  store.dispatch('autonomiaBuildThreads/completeMaterials', {
    threadId: threadId.value,
    content: t('AGENTS.BUILDER.FINALIZE_SIGNAL'),
  });
};

// (A) Force-close the build from step 1. Sends the finalize signal turn (the
// existing close path: completeMaterials -> backend force_close?), which flips
// `phase` to `reviewing`; the watch below then advances the wizard to Revisão.
const finalizeBuild = async () => {
  if (!threadId.value || finalizing.value || finalizeFired.value) return;
  finalizing.value = true;
  finalizeFired.value = true;
  try {
    await store.dispatch('autonomiaBuildThreads/completeMaterials', {
      threadId: threadId.value,
      content: t('AGENTS.BUILDER.FINALIZE_SIGNAL'),
    });
  } catch (error) {
    finalizeFired.value = false;
    useAlert(t('AGENTS.BUILDER.FINALIZE_ERROR'));
  } finally {
    finalizing.value = false;
  }
};

const goToHub = () => {
  // If the user leaves step 1 having engaged but never closed, fire-and-forget
  // the finalize so the draft gets an instruction server-side (no need to wait
  // on the poll, since we're navigating away). Otherwise just leave.
  if (canAdvance.value) {
    fireFinalize();
    useAlert(t('AGENTS.BUILDER.FINALIZING'));
  }
  router.push({ name: 'autonomia_agents_index' });
};

// phase -> reviewing means the build closed and the agent was generated. Pull
// the eligible inboxes for the connect select and advance to the review step.
watch(
  () => [phase.value, generatedAgent.value],
  async ([newPhase, agent]) => {
    if (newPhase === 'reviewing' && agent) {
      wizardStep.value = 'revisao';
      try {
        await store.dispatch('autonomiaChannels/fetch', { agentId: agent.id });
      } catch (error) {
        // The Channels tab can still load these later; non-fatal here.
      }
    }
  }
);

// Move focus to the new step's heading on each transition so keyboard and
// screen-reader users follow the wizard. Headings carry `tabindex="-1"`.
const STEP_FOCUS_REFS = {
  revisao: () => revisaoStepRef.value,
  conversa: () => conversaHeadingRef.value,
};
watch(wizardStep, step => {
  nextTick(() => {
    const target = (STEP_FOCUS_REFS[step] || STEP_FOCUS_REFS.conversa)();
    target?.focus?.();
  });
});

onMounted(() => {
  // Start clean: the sources store is a module-level singleton, so a previous
  // builder/panel session leaves its records behind. Without clearing them a NEW
  // agent would show the PREVIOUS agent's knowledge (and "remove" would fail with
  // a mismatched agent id). Stop any in-flight poll and empty the list first.
  store.dispatch('autonomiaSources/stopPolling');
  store.commit('autonomiaSources/SET', []);
  // Then open the thread WITHOUT a user message so the Construtor speaks first
  // (IA-fala-primeiro). The opening turn arrives via polling.
  store.commit('autonomiaBuildThreads/RESET');
  if (agentType.value) startThread();
});

onBeforeUnmount(() => {
  // P0.1 RASCUNHO: a lay user who navigates away by route change (sidebar, browser
  // back) — not the X button — would otherwise leave a draft agent WITHOUT an
  // instruction. Replicate the `goToHub` guard here so any unmount with an engaged
  // draft (>=1 user turn, agent created, build not yet reviewing) force-closes the
  // build server-side. `finalizeFired` keeps it idempotent with the X path. An
  // empty draft (no user turn) creates no agent backend-side, so there is nothing
  // to finalize or discard.
  if (canAdvance.value) fireFinalize();
  store.dispatch('autonomiaBuildThreads/stopPolling');
  store.dispatch('autonomiaSources/stopPolling');
  store.commit('autonomiaSources/SET', []);
  store.commit('autonomiaBuildThreads/RESET');
});
</script>

<template>
  <div class="flex flex-col w-full h-full bg-n-background">
    <header
      class="flex items-center justify-between flex-shrink-0 gap-4 px-6 py-4 border-b border-n-weak"
    >
      <div class="flex items-center gap-2 shrink-0">
        <i class="i-lucide-sparkles size-5 text-n-iris-10" />
        <h1 class="text-base font-medium text-n-slate-12">
          {{ t('AGENTS.BUILDER.TITLE') }}
        </h1>
      </div>
      <BuilderStepBar :current="currentStep" class="flex-1 min-w-0" />
      <NextButton
        ghost
        slate
        sm
        icon="i-lucide-x"
        :label="t('AGENTS.BUILDER.EXIT')"
        class="shrink-0"
        @click="goToHub"
      />
    </header>

    <div class="flex-1 min-h-0 overflow-hidden">
      <!-- Step 0: choose the agent type (entry point for Hub + sidebar). -->
      <div v-if="showPicker" class="w-full h-full px-4 py-8 overflow-y-auto">
        <AgentTypePicker @select="onPickType" />
      </div>

      <div
        v-else
        class="flex flex-col w-full h-full max-w-6xl gap-4 px-4 py-6 mx-auto"
      >
        <div
          v-if="errorMessage"
          role="alert"
          class="flex items-start gap-2 px-4 py-3 text-xs rounded-lg bg-n-ruby-9/10 text-n-ruby-11 shrink-0"
        >
          <i class="i-lucide-triangle-alert size-4 mt-0.5 shrink-0" />
          <span class="flex-1">{{ errorMessage }}</span>
          <NextButton
            ghost
            ruby
            xs
            :label="t('AGENTS.BUILDER.RETRY')"
            class="shrink-0 -my-1"
            @click="retryBuild"
          />
        </div>

        <!-- Step 1: CONVERSA + MATERIAIS (two columns) -->
        <div
          v-if="wizardStep === 'conversa'"
          class="grid flex-1 min-h-0 grid-cols-1 gap-4 lg:grid-cols-[minmax(0,1fr)_22rem]"
        >
          <!-- LEFT: the interview -->
          <div class="flex flex-col min-h-0 max-lg:min-h-[60vh]">
            <div
              v-if="!messages.length"
              class="flex flex-col items-center gap-3 pt-6 pb-2 text-center shrink-0"
              aria-live="polite"
            >
              <span
                class="flex items-center justify-center rounded-full size-14 bg-n-iris-3 text-n-iris-10 ring-4 ring-n-iris-2"
              >
                <i class="i-lucide-sparkles size-7" />
              </span>
              <h2
                ref="conversaHeadingRef"
                tabindex="-1"
                class="text-base font-medium outline-none text-n-slate-12"
              >
                {{ t('AGENTS.BUILDER.TITLE') }}
              </h2>
              <p class="max-w-md text-sm leading-relaxed text-n-slate-11">
                {{ t('AGENTS.BUILDER.INTRO') }}
              </p>
            </div>

            <div
              v-if="showUrlSuggestion"
              class="flex items-center gap-2 px-3 py-2 mb-2 text-xs border rounded-lg shrink-0 border-n-weak bg-n-alpha-1 text-n-slate-11"
            >
              <i class="i-lucide-link size-4 shrink-0 text-n-iris-10" />
              <span class="flex-1 min-w-0 truncate">
                {{
                  t('AGENTS.BUILDER.URL_SUGGEST.PROMPT', {
                    url: lastUserUrl,
                    name: agentName,
                  })
                }}
              </span>
              <NextButton
                xs
                solid
                :is-loading="isAttachingUrl"
                :label="t('AGENTS.BUILDER.URL_SUGGEST.ADD')"
                class="shrink-0"
                @click="addUrlAsKnowledge"
              />
              <NextButton
                xs
                ghost
                slate
                icon="i-lucide-x"
                class="shrink-0"
                :aria-label="t('AGENTS.BUILDER.URL_SUGGEST.DISMISS')"
                @click="dismissUrlSuggestion"
              />
            </div>

            <BuilderChat
              class="flex-1 min-h-0"
              :messages="messages"
              :is-sending="isSending"
              :can-attach="canAttachInChat"
              :is-attaching="isAttachingInChat"
              @send="handleSend"
              @attach="attachFromChat"
            />

            <div v-if="canAdvance" class="flex justify-end pt-2 shrink-0">
              <NextButton
                solid
                sm
                icon="i-lucide-arrow-right"
                :label="t('AGENTS.BUILDER.ADVANCE_TO_REVIEW')"
                :is-loading="finalizing"
                @click="finalizeBuild"
              />
            </div>
          </div>

          <!-- RIGHT: live knowledge panel (the mock) -->
          <BuilderKnowledgePanel
            :agent-id="agentId"
            class="min-h-0 max-lg:h-96"
          />
        </div>

        <!-- Step 2: REVISÃO + CONECTAR -->
        <div
          v-else-if="wizardStep === 'revisao' && generatedAgent"
          ref="revisaoStepRef"
          tabindex="-1"
          class="flex-1 min-h-0 overflow-y-auto outline-none"
        >
          <BuilderReview
            :agent="generatedAgent"
            :eligible-inboxes="eligibleInboxes"
            :approved-count="approvedCount"
            :confidence-pct="confidencePct"
            :is-saving-greeting="isSavingGreeting"
            :is-connecting="channelFlags?.connecting"
            @save-greeting="saveGreeting"
            @test="testAgent"
            @connect="connectInbox"
            @activate="activateInternal"
            @back="backToConversa"
          />
        </div>
      </div>
    </div>
  </div>
</template>
