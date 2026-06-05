<script setup>
import { ref, watch, onMounted, onBeforeUnmount, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
/* global axios */
import SynapseCard from 'next/synapseos/SynapseCard.vue';
import SynapseStatusPill from 'next/synapseos/SynapseStatusPill.vue';
import SynapseButton from 'next/synapseos/SynapseButton.vue';
import SynapseEmptyState from 'next/synapseos/SynapseEmptyState.vue';

const props = defineProps({
  agent: { type: Object, required: true },
});

const emit = defineEmits(['close']);

const { t } = useI18n();
const route = useRoute();
const router = useRouter();

const conversations = ref([]);
const loading = ref(false);
const pollTimer = ref(null);

const statusTone = status => {
  const map = { open: 'success', resolved: 'neutral', pending: 'warning', snoozed: 'warning' };
  return map[status] || 'neutral';
};

const formatRelativeTime = iso => {
  if (!iso) return '';
  const then = new Date(iso).getTime();
  const delta = Math.max(0, Math.floor((Date.now() - then) / 1000));
  if (delta < 60) return `${delta}s`;
  if (delta < 3600) return `${Math.floor(delta / 60)}m`;
  if (delta < 86400) return `${Math.floor(delta / 3600)}h`;
  return `${Math.floor(delta / 86400)}d`;
};

const fetchConversations = async () => {
  if (!props.agent?.id) return;
  loading.value = true;
  try {
    const { data } = await axios.get(
      `/api/v1/accounts/${route.params.accountId}/synapseos/live_agents/${props.agent.id}/conversations`
    );
    conversations.value = data.conversations || [];
  } finally {
    loading.value = false;
  }
};

const openConversation = conv => {
  router.push({
    name: 'inbox_conversation',
    params: {
      accountId: route.params.accountId,
      conversation_id: conv.id,
    },
  });
};

const title = computed(() =>
  t('SYNAPSEOS.LIVE_AGENTS.PANEL.TITLE', { name: props.agent?.name || '' })
);

watch(() => props.agent?.id, () => {
  fetchConversations();
});

onMounted(() => {
  fetchConversations();
  pollTimer.value = setInterval(fetchConversations, 15000);
});

onBeforeUnmount(() => {
  if (pollTimer.value) clearInterval(pollTimer.value);
});
</script>

<template>
  <SynapseCard padding="none">
    <div class="flex items-center justify-between gap-3 px-4 py-3 border-b border-s-border-subtle">
      <div class="flex flex-col gap-0.5 min-w-0">
        <span class="text-sm font-semibold text-s-primary truncate">{{ title }}</span>
        <span class="text-xs text-s-muted">
          {{ t('SYNAPSEOS.LIVE_AGENTS.PANEL.COUNT', { n: conversations.length }) }}
        </span>
      </div>
      <SynapseButton size="sm" variant="ghost" icon="i-lucide-x" class="shrink-0" @click="emit('close')">
        {{ t('SYNAPSEOS.LIVE_AGENTS.PANEL.CLOSE') }}
      </SynapseButton>
    </div>

    <div v-if="loading && !conversations.length" class="px-4 py-6 text-sm text-s-muted">
      {{ t('SYNAPSEOS.LIVE_AGENTS.PANEL.LOADING') }}
    </div>

    <SynapseEmptyState
      v-else-if="!conversations.length"
      icon="i-lucide-inbox"
      :title="t('SYNAPSEOS.LIVE_AGENTS.PANEL.EMPTY')"
      size="sm"
      class="px-4"
    />

    <ul v-else class="divide-y divide-s-border-subtle max-h-[600px] overflow-auto">
      <li
        v-for="conv in conversations"
        :key="conv.id"
        class="px-4 py-3 hover:bg-s-subtle cursor-pointer flex items-start gap-3"
        @click="openConversation(conv)"
      >
        <img
          v-if="conv.contact?.thumbnail"
          :src="conv.contact.thumbnail"
          :alt="conv.contact.name"
          class="rounded-full size-9 shrink-0"
        >
        <div
          v-else
          class="rounded-full size-9 bg-s-subtle flex items-center justify-center text-xs text-s-secondary font-medium shrink-0"
        >
          {{ conv.contact?.name?.[0]?.toUpperCase() || '?' }}
        </div>

        <div class="flex-1 min-w-0 flex flex-col gap-1">
          <div class="flex items-center justify-between gap-2">
            <span class="text-sm font-medium text-s-primary truncate">
              {{ conv.contact?.name || '—' }}
            </span>
            <span class="text-xs text-s-muted shrink-0">
              {{ formatRelativeTime(conv.last_activity_at) }}
            </span>
          </div>
          <span v-if="conv.last_message?.content" class="text-xs text-s-muted truncate">
            {{ conv.last_message.content }}
          </span>
          <div class="flex items-center gap-2 mt-0.5">
            <span class="text-xs text-s-muted">#{{ conv.id }}</span>
            <SynapseStatusPill :tone="statusTone(conv.status)" size="sm">
              {{ t(`SYNAPSEOS.LIVE_AGENTS.PANEL.STATUS.${conv.status.toUpperCase()}`, conv.status) }}
            </SynapseStatusPill>
          </div>
        </div>
      </li>
    </ul>
  </SynapseCard>
</template>
