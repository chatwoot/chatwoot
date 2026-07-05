<script setup>
import { ref, computed, watch, onMounted, onBeforeUnmount } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';

import NextButton from 'dashboard/components-next/button/Button.vue';
import TabBar from 'dashboard/components-next/tabbar/TabBar.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import MaterialDropzone from './MaterialDropzone.vue';
import MaterialCard from './MaterialCard.vue';
import SourceAddDialog from '../panel/SourceAddDialog.vue';

// KNOWLEDGE PANEL — the right column of the builder's step 1 (the approved
// mock). It sits ALONGSIDE the conversation: the user drops what the agent
// should KNOW (Conhecimento) and what it can SEND (Mídias p/ enviar), and the
// Revisor scores each file inline (Pronto / Analisando / Revisar). There is NO
// "Continuar/Pular" here anymore — closing is driven by the conversation; the
// Construtor confirms the knowledge state before it finalizes.
const props = defineProps({
  // Nullable: before the user's first message no draft agent exists yet, so the
  // dropzone is shown disabled with a hint. Once the agent id arrives, uploads
  // work and the list is fetched.
  agentId: {
    type: [String, Number],
    default: null,
  },
});

const { t } = useI18n();
const store = useStore();

const knowledgeSources = useMapGetter('autonomiaSources/getKnowledgeSources');
const mediaSources = useMapGetter('autonomiaSources/getMediaSources');
const hasMediaKind = useMapGetter('autonomiaSources/hasMediaKind');
// Confiança é sobre a base de CONHECIMENTO — o poll assenta quando a knowledge revisou (mídia,
// que não passa pelo Revisor, não deve manter o poll rodando até o cap).
const allReviewed = useMapGetter('autonomiaSources/getKnowledgeReviewed');
const uiFlags = useMapGetter('autonomiaSources/getUIFlags');

// Live base confidence (0..1) recomputed by the Revisor after each review. The
// draft agent carries it in config.knowledge_confidence; we read it off the
// records list (the agent id is the same draft the conversation created).
const agent = computed(() =>
  props.agentId
    ? store.getters['autonomiaAgents/getRecord'](Number(props.agentId))
    : null
);
const confidence = computed(() => {
  const value = agent.value?.config?.knowledge_confidence;
  return Number.isFinite(value) ? value : null;
});
const confidencePct = computed(() =>
  confidence.value == null ? null : Math.round(confidence.value * 100)
);
// Same teal/amber/ruby scale used in the Conhecimento tab so the bar reads the
// same everywhere. Fraction 0..1, never 0..100.
const confidenceBarClass = computed(() => {
  if (confidence.value == null) return 'bg-n-slate-9';
  if (confidence.value >= 0.7) return 'bg-n-teal-9';
  if (confidence.value >= 0.4) return 'bg-n-amber-9';
  return 'bg-n-ruby-9';
});

const activeTabIndex = ref(0);
const resyncingId = ref(null);
const removingId = ref(null);

const tabs = computed(() => {
  const list = [
    {
      key: 'knowledge',
      label: t('AGENTS.MATERIALS.TABS.KNOWLEDGE'),
      count: knowledgeSources.value.length || undefined,
    },
  ];
  if (hasMediaKind.value) {
    list.push({
      key: 'media',
      label: t('AGENTS.MATERIALS.TABS.MEDIA'),
      count: mediaSources.value.length || undefined,
    });
  }
  return list;
});

const activeKind = computed(() =>
  activeTabIndex.value === 1 ? 'media' : 'knowledge'
);

const visibleSources = computed(() =>
  activeKind.value === 'media' ? mediaSources.value : knowledgeSources.value
);

const hasAgent = computed(() => !!props.agentId);
const isUploading = computed(() => uiFlags.value?.creatingItem);

// Teto de fontes de CONHECIMENTO por agente — espelha Source::MAX_KNOWLEDGE_SOURCES (o backend
// responde 422 ao estourar). Mídias de envio têm pipeline próprio, sem limite.
const KNOWLEDGE_LIMIT = 30;
const knowledgeCount = computed(() => knowledgeSources.value.length);
const knowledgeLimitReached = computed(
  () => knowledgeCount.value >= KNOWLEDGE_LIMIT
);
// Dropzone bloqueia por teto só na aba de conhecimento (defesa de UX antes do 422 do servidor).
const dropzoneDisabled = computed(
  () =>
    isUploading.value ||
    !hasAgent.value ||
    (activeKind.value === 'knowledge' && knowledgeLimitReached.value)
);

const onTabChanged = tab => {
  const index = tabs.value.findIndex(item => item.key === tab.key);
  if (index !== -1) activeTabIndex.value = index;
};

const uploadFiles = async files => {
  if (!props.agentId) {
    useAlert(t('AGENTS.MATERIALS.NEED_START'));
    return;
  }
  // Teto de conhecimento: corta o lote pelas vagas restantes (o servidor 422 cobre o resto). Mídia
  // não tem limite. Sem vaga, avisa e não sobe nada.
  let batch = files;
  if (activeKind.value === 'knowledge') {
    const remaining = KNOWLEDGE_LIMIT - knowledgeCount.value;
    if (remaining <= 0) {
      useAlert(t('AGENTS.MATERIALS.LIMIT_REACHED'));
      return;
    }
    batch = files.slice(0, remaining);
  }
  const results = await Promise.allSettled(
    batch.map(file =>
      store.dispatch('autonomiaSources/create', {
        agentId: props.agentId,
        descriptor: { file, kind: activeKind.value },
      })
    )
  );
  if (results.some(result => result.status === 'rejected')) {
    useAlert(t('AGENTS.MATERIALS.UPLOAD_ERROR'));
  }
};

const onResync = async sourceId => {
  resyncingId.value = sourceId;
  try {
    await store.dispatch('autonomiaSources/resync', {
      agentId: props.agentId,
      sourceId,
    });
  } catch (error) {
    useAlert(t('AGENTS.MATERIALS.RESEND_ERROR'));
  } finally {
    resyncingId.value = null;
  }
};

const onRemove = async sourceId => {
  removingId.value = sourceId;
  try {
    await store.dispatch('autonomiaSources/remove', {
      agentId: props.agentId,
      sourceId,
    });
  } catch (error) {
    useAlert(t('AGENTS.MATERIALS.REMOVE_ERROR'));
  } finally {
    removingId.value = null;
  }
};

const fetchSources = () => {
  if (!props.agentId) return;
  store.dispatch('autonomiaSources/fetch', { agentId: props.agentId });
};

// "Adicionar link" — links only ever become knowledge, so the affordance is
// shown on the knowledge tab and reuses the same SourceAddDialog the live
// agent's panel uses (it does the create dispatch + toast internally). The
// dialog needs a draft agent; the guard nudges the user to start the chat.
const addDialogRef = ref(null);
const openAddDialog = () => {
  if (!props.agentId) {
    useAlert(t('AGENTS.MATERIALS.NEED_START'));
    return;
  }
  // Links sempre viram conhecimento — respeita o mesmo teto do dropzone.
  if (knowledgeLimitReached.value) {
    useAlert(t('AGENTS.MATERIALS.LIMIT_REACHED'));
    return;
  }
  addDialogRef.value?.open();
};
const onSourceAdded = () => fetchSources();

// The draft agent appears only after the first message; fetch the moment its id
// arrives (and on mount if we already have it, e.g. returning from review).
watch(
  () => props.agentId,
  id => {
    if (id) fetchSources();
  }
);

// LIVE base confidence. The Revisor writes agent.config.knowledge_confidence in
// an ASYNC overall step that lands a beat AFTER each file is accepted — so a
// refresh gated on `!allReviewed` stopped fetching exactly when the final value
// appears (root cause: bar stuck empty). Instead, whenever the knowledge list
// changes we (re)start a short poll of the agent that keeps going until the
// confidence has landed AND everything is reviewed (or an attempt cap), so the
// bar reaches its final value live without a manual refresh.
let confidenceTimer = null;
const stopConfidencePoll = () => {
  if (confidenceTimer) {
    clearTimeout(confidenceTimer);
    confidenceTimer = null;
  }
};
const pollConfidence = async (attempt = 0) => {
  if (!props.agentId) return;
  try {
    await store.dispatch('autonomiaAgents/show', Number(props.agentId));
  } catch (error) {
    // Transient miss: keep the last value and try again on the next tick.
  }
  const settled = confidence.value != null && allReviewed.value;
  confidenceTimer =
    !settled && attempt < 8
      ? setTimeout(() => pollConfidence(attempt + 1), 3000)
      : null;
};

watch(knowledgeSources, () => {
  if (props.agentId && knowledgeSources.value.length) {
    stopConfidencePoll();
    pollConfidence(0);
  }
});

onMounted(fetchSources);

onBeforeUnmount(() => {
  stopConfidencePoll();
  store.dispatch('autonomiaSources/stopPolling');
});
</script>

<template>
  <section
    class="flex flex-col h-full min-h-0 overflow-hidden border rounded-xl border-n-weak bg-n-solid-1"
    :aria-label="t('AGENTS.MATERIALS.PANEL_TITLE')"
  >
    <div
      class="flex items-center justify-between flex-shrink-0 gap-2 px-4 pt-4"
    >
      <h2 class="text-xs font-semibold tracking-wide uppercase text-n-slate-11">
        {{ t('AGENTS.MATERIALS.PANEL_TITLE') }}
      </h2>
      <NextButton
        v-if="activeKind === 'knowledge'"
        ghost
        slate
        xs
        icon="i-lucide-link"
        :label="t('AGENTS.MATERIALS.ADD_LINK')"
        :disabled="!hasAgent || isUploading || knowledgeLimitReached"
        @click="openAddDialog"
      />
    </div>

    <div class="flex-shrink-0 px-4 pt-3">
      <TabBar
        :tabs="tabs"
        :initial-active-tab="activeTabIndex"
        @tab-changed="onTabChanged"
      />
    </div>

    <!-- Live base confidence: climbs as the Revisor settles each knowledge file
         (the agent is re-fetched on every poll cycle). Knowledge tab only. -->
    <div
      v-if="
        activeKind === 'knowledge' &&
        knowledgeSources.length &&
        confidencePct !== null
      "
      class="flex-shrink-0 px-4 pt-3"
    >
      <div class="flex items-center justify-between mb-1.5">
        <span class="text-xs font-medium text-n-slate-11">
          {{ t('AGENTS.MATERIALS.CONFIDENCE_OVERALL') }}
        </span>
        <span class="text-xs font-medium tabular-nums text-n-slate-12">
          {{ t('AGENTS.MATERIALS.PERCENT', { value: confidencePct }) }}
        </span>
      </div>
      <div
        class="w-full h-2 overflow-hidden rounded-full bg-n-alpha-2"
        role="progressbar"
        :aria-valuenow="confidencePct"
        aria-valuemin="0"
        aria-valuemax="100"
        :aria-label="t('AGENTS.MATERIALS.CONFIDENCE_OVERALL')"
      >
        <div
          class="h-full rounded-full transition-all duration-500"
          :class="confidenceBarClass"
          :style="{ width: `${confidencePct}%` }"
        />
      </div>
    </div>

    <!-- POPULATED: compact dropzone pinned on top, list scrolls below. -->
    <div
      v-if="visibleSources.length"
      class="flex flex-col flex-1 min-h-0 gap-3 p-4"
    >
      <MaterialDropzone
        compact
        :kind="activeKind"
        :disabled="dropzoneDisabled"
        @files="uploadFiles"
      />
      <div
        v-if="isUploading"
        class="flex items-center justify-center gap-2 text-xs text-n-slate-11"
      >
        <Spinner :size="16" />
        <span>{{ t('AGENTS.MATERIALS.STATUS.SENDING') }}</span>
      </div>
      <!-- aria-live so a screen reader hears each file flip from "analisando"
           to "pronto"/"revisar" as the Revisor settles. -->
      <div
        class="flex flex-col flex-1 min-h-0 gap-2.5 overflow-y-auto -mr-1.5 pr-1.5"
        role="list"
        aria-live="polite"
      >
        <MaterialCard
          v-for="source in visibleSources"
          :key="source.id"
          :source="source"
          :resyncing="resyncingId === source.id"
          :removing="removingId === source.id"
          @resync="onResync"
          @remove="onRemove"
        />
      </div>
    </div>

    <!-- EMPTY: center the dropzone + hint vertically so there is no dead space. -->
    <div
      v-else
      class="flex flex-col items-center justify-center flex-1 gap-4 px-5 py-4 text-center"
    >
      <MaterialDropzone
        class="w-full"
        :kind="activeKind"
        :disabled="dropzoneDisabled"
        @files="uploadFiles"
      />
      <div
        v-if="isUploading"
        class="flex items-center justify-center gap-2 text-xs text-n-slate-11"
      >
        <Spinner :size="16" />
        <span>{{ t('AGENTS.MATERIALS.STATUS.SENDING') }}</span>
      </div>
      <p class="max-w-xs text-xs leading-relaxed text-n-slate-10">
        {{
          hasAgent
            ? t('AGENTS.MATERIALS.EMPTY')
            : t('AGENTS.MATERIALS.NEED_START')
        }}
      </p>
    </div>

    <!-- Contador X/30 (aba conhecimento): espelha o teto do servidor; avisa quando cheio. -->
    <div
      v-if="activeKind === 'knowledge'"
      class="flex items-center justify-between flex-shrink-0 gap-2 px-4 py-2.5 text-xs border-t border-n-weak"
    >
      <span class="tabular-nums text-n-slate-11">
        {{
          t('AGENTS.MATERIALS.COUNT', {
            count: knowledgeCount,
            limit: KNOWLEDGE_LIMIT,
          })
        }}
      </span>
      <span v-if="knowledgeLimitReached" class="font-medium text-n-amber-11">
        {{ t('AGENTS.MATERIALS.LIMIT_REACHED') }}
      </span>
    </div>

    <SourceAddDialog
      v-if="hasAgent"
      ref="addDialogRef"
      :agent-id="Number(agentId)"
      @added="onSourceAdded"
    />
  </section>
</template>
