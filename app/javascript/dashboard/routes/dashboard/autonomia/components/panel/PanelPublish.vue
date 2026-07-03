<script setup>
import { computed, onMounted, onBeforeUnmount } from 'vue';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';

import BuilderReview from '../builder/BuilderReview.vue';

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
const router = useRouter();

const eligibleInboxes = useMapGetter('autonomiaChannels/getEligible');
const channelFlags = useMapGetter('autonomiaChannels/getUIFlags');
const agentFlags = useMapGetter('autonomiaAgents/getUIFlags');
const sources = useMapGetter('autonomiaSources/getSources');

const approvedCount = computed(
  () =>
    sources.value.filter(source => source.review?.status === 'accepted').length
);

const confidencePct = computed(() =>
  Math.round((props.agent?.config?.knowledge_confidence || 0) * 100)
);

const isPublishing = computed(
  () => !!agentFlags.value?.updatingItem || !!channelFlags.value?.connecting
);

const goToTest = () => {
  router.replace({
    name: 'autonomia_agent_panel',
    params: { agentId: props.agentId, tab: 'test' },
  });
};

const saveGreeting = async greeting => {
  try {
    await store.dispatch('autonomiaAgents/update', {
      id: props.agentId,
      greeting,
    });
    useAlert(t('AGENTS.REVIEW.SAVED'));
  } catch (error) {
    useAlert(t('AGENTS.TUNE.SAVE_ERROR'));
  }
};

const connectInbox = async inboxId => {
  if (!inboxId) return;
  // O backend exige agente ativo para conectar, então ativa primeiro — mas se a
  // conexão falhar, restaura o estado anterior (senão fica "ativo sem canal").
  const previous = {
    enabled: props.agent?.enabled === true,
    status: props.agent?.status || 'draft',
  };
  let activated = false;
  try {
    await store.dispatch('autonomiaAgents/update', {
      id: props.agentId,
      enabled: true,
      status: 'active',
    });
    activated = true;
    await store.dispatch('autonomiaChannels/connect', {
      agentId: props.agentId,
      inboxId,
    });
    goToTest();
  } catch (error) {
    if (activated) {
      await store
        .dispatch('autonomiaAgents/update', { id: props.agentId, ...previous })
        .catch(() => {});
    }
    useAlert(t('AGENTS.CHANNELS.CONNECT_ERROR'));
  }
};

// Agente interno (copiloto da equipe) não conecta canal — ativa direto.
// É o que o lista no seletor "Copiloto Autonom.ia" das conversas (a API
// só devolve agentes internal/both com status active e enabled).
const activateInternal = async () => {
  try {
    await store.dispatch('autonomiaAgents/update', {
      id: props.agentId,
      enabled: true,
      status: 'active',
    });
    useAlert(t('AGENTS.REVIEW.ACTIVATED_INTERNAL'));
    goToTest();
  } catch (error) {
    useAlert(t('AGENTS.CHANNELS.CONNECT_ERROR'));
  }
};

onMounted(() => {
  store.dispatch('autonomiaChannels/fetch', { agentId: props.agentId });
  store.dispatch('autonomiaSources/fetch', { agentId: props.agentId });
});

onBeforeUnmount(() => {
  store.dispatch('autonomiaSources/stopPolling');
});
</script>

<template>
  <div class="w-full max-w-4xl px-6 py-6 mx-auto">
    <BuilderReview
      :agent="agent"
      :eligible-inboxes="eligibleInboxes"
      :approved-count="approvedCount"
      :confidence-pct="confidencePct"
      :is-saving-greeting="agentFlags?.updatingItem"
      :is-connecting="isPublishing"
      @save-greeting="saveGreeting"
      @test="goToTest"
      @connect="connectInbox"
      @activate="activateInternal"
      @back="goToTest"
    />
  </div>
</template>
