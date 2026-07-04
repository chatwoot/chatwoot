<script setup>
import { ref, computed, watch, onMounted, onBeforeUnmount } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';

import NextButton from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import MaterialCard from '../builder/MaterialCard.vue';
import MaterialDropzone from '../builder/MaterialDropzone.vue';
import SourceAddDialog from './SourceAddDialog.vue';

// CONHECIMENTO tab: manage what the agent knows over time — include and remove
// materials at any moment, with the SAME quality verdict (nota/rótulo/resumo +
// "revisar"/Reenviar) the user saw in the Materiais step. Reuses MaterialCard
// and MaterialDropzone so quality is never hidden after creation. An overall
// confidence bar mirrors the Builder. IP OCULTO: only human-facing review
// content is read; never the instruction/scaffold.
const props = defineProps({
  agent: {
    type: Object,
    required: true,
  },
  agentId: {
    type: Number,
    required: true,
  },
});

const { t } = useI18n();
const store = useStore();

const sources = useMapGetter('autonomiaSources/getKnowledgeSources');
const allReviewed = useMapGetter('autonomiaSources/getAllReviewed');
const uiFlags = useMapGetter('autonomiaSources/getUIFlags');

const addDialogRef = ref(null);
// Removing a material is destructive and has no undo — hold the pending source
// so the confirm dialog can name it, and only delete after the user confirms.
const removeDialogRef = ref(null);
const pendingRemove = ref(null);
// The store uiFlags are module-wide, so track the in-flight row id locally to
// keep the spinner on a single card, not every card.
const resyncingId = ref(null);
const removingId = ref(null);

// Overall knowledge confidence (0..1) computed by the Revisor; shown as a bar so
// the user can see the base health at a glance, just like in the Builder.
const confidence = computed(() => {
  const value = props.agent.config?.knowledge_confidence;
  return Number.isFinite(value) ? value : null;
});
const confidencePct = computed(() =>
  confidence.value == null ? null : Math.round(confidence.value * 100)
);
const confidenceBarClass = computed(() => {
  if (confidence.value == null) return 'bg-n-slate-9';
  if (confidence.value >= 0.7) return 'bg-n-teal-9';
  if (confidence.value >= 0.4) return 'bg-n-amber-9';
  return 'bg-n-ruby-9';
});

const fetchSources = () => {
  store.dispatch('autonomiaSources/fetch', { agentId: props.agentId });
};

const refreshAgent = () => {
  store.dispatch('autonomiaAgents/show', props.agentId);
};

const openAddDialog = () => {
  addDialogRef.value?.open();
};

// Inline drag-and-drop upload (knowledge group). Each dropped file becomes a
// source; the Revisor reprocesses and the confidence bar updates on refresh.
const onFilesDropped = async files => {
  const uploads = Array.from(files).map(file =>
    store.dispatch('autonomiaSources/create', {
      agentId: props.agentId,
      descriptor: { file, kind: 'knowledge' },
    })
  );
  try {
    await Promise.all(uploads);
    // Adding material re-scores the base; refresh the agent so the confidence
    // bar reflects the new value (it reads agent.config.knowledge_confidence).
    refreshAgent();
  } catch (error) {
    useAlert(t('AGENTS.MATERIALS.UPLOAD_ERROR'));
  }
};

// New material added via the dialog (upload OR link): refresh both the source
// list and the agent so the confidence bar doesn't stay stale.
const onSourceAdded = () => {
  fetchSources();
  refreshAgent();
};

const onResync = async sourceId => {
  resyncingId.value = sourceId;
  try {
    await store.dispatch('autonomiaSources/resync', {
      agentId: props.agentId,
      sourceId,
    });
  } catch (error) {
    useAlert(t('AGENTS.KNOWLEDGE.RESYNC_ERROR'));
  } finally {
    resyncingId.value = null;
  }
};

// Trash click no longer deletes on the spot: open a confirm dialog naming the
// material (destructive, no undo — the old silent delete looked like "nothing
// happened" on a missed click and risked wiping the base by accident).
const askRemove = sourceId => {
  pendingRemove.value = sources.value.find(source => source.id === sourceId);
  if (pendingRemove.value) removeDialogRef.value?.open();
};

const removeName = computed(
  () => pendingRemove.value?.title || pendingRemove.value?.reference || ''
);

const confirmRemove = async () => {
  const sourceId = pendingRemove.value?.id;
  if (!sourceId) return;

  removingId.value = sourceId;
  try {
    await store.dispatch('autonomiaSources/remove', {
      agentId: props.agentId,
      sourceId,
    });
    removeDialogRef.value?.close();
    useAlert(t('AGENTS.KNOWLEDGE.REMOVE_SUCCESS'));
    // Removing a material re-scores the base; refresh the confidence bar.
    refreshAgent();
  } catch (error) {
    // Keep the dialog open on failure so the user can retry (pendingRemove is
    // cleared by the dialog's @close, not here).
    useAlert(t('AGENTS.KNOWLEDGE.REMOVE_ERROR'));
  } finally {
    removingId.value = null;
  }
};

// The sources store polls and re-fetches the list while the Revisor processes,
// but the confidence bar reads agent.config.knowledge_confidence — refresh the
// agent on each poll cycle until everything is reviewed so the bar doesn't freeze.
watch(sources, () => {
  if (sources.value.length && !allReviewed.value) refreshAgent();
});

onMounted(fetchSources);

onBeforeUnmount(() => {
  store.dispatch('autonomiaSources/stopPolling');
});
</script>

<template>
  <div class="flex flex-col w-full h-full max-w-3xl gap-5 px-6 py-6 mx-auto">
    <div class="flex items-start justify-between flex-shrink-0 gap-3">
      <div class="flex flex-col">
        <h2 class="text-sm font-medium text-n-slate-12">
          {{ t('AGENTS.KNOWLEDGE.TITLE') }}
        </h2>
        <p class="text-xs text-n-slate-10">
          {{ t('AGENTS.KNOWLEDGE.SUBTITLE') }}
        </p>
      </div>
      <NextButton
        solid
        sm
        icon="i-lucide-plus"
        :label="t('AGENTS.KNOWLEDGE.ADD')"
        @click="openAddDialog"
      />
    </div>

    <!-- Overall confidence bar (mirrors the Builder Materiais step). -->
    <div
      v-if="confidencePct !== null"
      class="flex flex-col gap-2 px-4 py-3 border rounded-xl border-n-weak bg-n-solid-1"
    >
      <div class="flex items-center justify-between">
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
          class="h-full rounded-full transition-all"
          :class="confidenceBarClass"
          :style="{ width: `${confidencePct}%` }"
        />
      </div>
    </div>

    <MaterialDropzone kind="knowledge" @files="onFilesDropped" />

    <div
      v-if="uiFlags.fetchingList && !sources.length"
      class="flex items-center justify-center flex-1 text-n-slate-11"
    >
      <Spinner :size="24" />
    </div>

    <div
      v-else-if="!sources.length"
      class="flex flex-col items-center justify-center flex-1 gap-3 px-6 py-12 text-center border border-dashed rounded-xl border-n-weak text-n-slate-10"
    >
      <span
        class="flex items-center justify-center rounded-full size-12 bg-n-alpha-1"
      >
        <Icon icon="i-lucide-book-open" class="text-xl text-n-slate-11" />
      </span>
      <p class="max-w-xs text-sm text-n-slate-11">
        {{ t('AGENTS.KNOWLEDGE.EMPTY') }}
      </p>
    </div>

    <ul v-else class="flex flex-col gap-3">
      <li v-for="source in sources" :key="source.id">
        <MaterialCard
          :source="source"
          :resyncing="resyncingId === source.id"
          :removing="removingId === source.id"
          @resync="onResync"
          @remove="askRemove"
        />
      </li>
    </ul>

    <SourceAddDialog
      ref="addDialogRef"
      :agent-id="agentId"
      @added="onSourceAdded"
    />

    <Dialog
      ref="removeDialogRef"
      type="alert"
      :title="t('AGENTS.KNOWLEDGE.REMOVE_CONFIRM_TITLE')"
      :description="
        t('AGENTS.KNOWLEDGE.REMOVE_CONFIRM_DESC', { name: removeName })
      "
      :confirm-button-label="t('AGENTS.KNOWLEDGE.REMOVE_CONFIRM_BUTTON')"
      :is-loading="removingId !== null"
      @confirm="confirmRemove"
      @close="pendingRemove = null"
    />
  </div>
</template>
