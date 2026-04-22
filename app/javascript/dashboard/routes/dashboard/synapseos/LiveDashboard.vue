<script setup>
// CUSTOMIZAÇÃO_SYNAPSEOS: Live Dashboard (esquadrão Alice&Iza, Otto, Luís, Fernanda, Ângela, Vitor).
import { computed, onBeforeUnmount, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useStore } from 'vuex';
import { formatDistanceToNow, parseISO } from 'date-fns';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';

import SynapseCard from 'next/synapseos/SynapseCard.vue';
import SynapseStatusPill from 'next/synapseos/SynapseStatusPill.vue';
import SynapseBadge from 'next/synapseos/SynapseBadge.vue';
import { useSynapseosLiveStore } from 'dashboard/store/synapseos/useSynapseosLive.js';

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const store = useStore();
const liveStore = useSynapseosLiveStore();

const pollTimer = ref(null);
const accountId = computed(() => Number(route.params.accountId));

const AGENT_ICONS = {
  alice_iza: 'i-lucide-bot',
  otto: 'i-lucide-clipboard-list',
  luis: 'i-lucide-wrench',
  fernanda: 'i-lucide-rotate-ccw',
  angela: 'i-lucide-seedling',
  vitor: 'i-lucide-dollar-sign',
};

const statusTone = status => {
  if (status === 'online') return 'success';
  if (status === 'idle') return 'warning';
  return 'neutral';
};

const relativeTime = isoString => {
  if (!isoString) return t('SYNAPSEOS.LIVE.LAST_ACTION_NONE');
  try {
    return formatDistanceToNow(parseISO(isoString), { addSuffix: true });
  } catch (_err) {
    return '—';
  }
};

const formatTimeInStage = seconds => {
  if (seconds === null || seconds === undefined) return '—';
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  const s = seconds % 60;
  if (h > 0) return `${h}h ${String(m).padStart(2, '0')}m`;
  return `${m}:${String(s).padStart(2, '0')}`;
};

const rowClass = row => {
  const t2 = row.time_in_stage_seconds || 0;
  if (t2 > 14400) return '!bg-s-error-soft';
  if (t2 > 3600) return '!bg-s-warning-soft';
  return '';
};

const assigneeTone = type => (type === 'AgentBot' ? 'brand' : 'neutral');

const openConversation = row => {
  router.push({
    name: 'inbox_conversation',
    params: { accountId: accountId.value, conversation_id: row.id },
  }).catch(() => {
    // fallback: direct navigation if named route not available
    window.location.href = `/app/accounts/${accountId.value}/conversations/${row.id}`;
  });
};

const refresh = () => liveStore.fetchLive(accountId.value);

onMounted(() => {
  refresh();
  const pubsubToken = store.getters.getCurrentUser?.pubsub_token;
  if (pubsubToken) {
    liveStore.subscribe({ accountId: accountId.value, pubsubToken });
  }
  // Polling fallback in case Cable silently drops.
  pollTimer.value = setInterval(refresh, 10000);
});

onBeforeUnmount(() => {
  if (pollTimer.value) clearInterval(pollTimer.value);
  liveStore.unsubscribe();
});
</script>

<template>
  <div class="bg-s-bg p-8 space-y-6 h-full overflow-auto">
    <header class="flex flex-col gap-1">
      <h1 class="text-2xl font-semibold text-s-primary">
        {{ t('SYNAPSEOS.LIVE.TITLE') }}
      </h1>
      <p class="text-sm text-s-muted">
        {{ t('SYNAPSEOS.LIVE.SUBTITLE') }}
      </p>
    </header>

    <SynapseCard :title="t('SYNAPSEOS.LIVE.AGENTS_SECTION')">
      <template #actions>
        <SynapseStatusPill :tone="liveStore.isConnected ? 'success' : 'neutral'" size="sm">
          {{ liveStore.isConnected
            ? t('SYNAPSEOS.LIVE.CABLE.CONNECTED')
            : t('SYNAPSEOS.LIVE.CABLE.POLLING') }}
        </SynapseStatusPill>
      </template>

      <ul class="divide-y divide-s-border-subtle">
        <li
          v-for="agent in liveStore.agents"
          :key="agent.slug"
          class="flex items-center gap-4 py-3"
        >
          <span
            class="inline-flex items-center justify-center size-10 rounded-xl bg-s-brand-soft text-s-brand-text shrink-0"
          >
            <span :class="['size-5', AGENT_ICONS[agent.slug] || 'i-lucide-sparkles']" />
          </span>
          <div class="flex-1 min-w-0">
            <div class="flex items-center gap-2">
              <span class="text-sm font-medium text-s-primary truncate">
                {{ agent.display_name }}
              </span>
              <SynapseStatusPill :tone="statusTone(agent.status)" size="sm">
                {{ t(`SYNAPSEOS.LIVE.STATUS.${agent.status.toUpperCase()}`) }}
              </SynapseStatusPill>
            </div>
            <p class="text-xs text-s-muted truncate">
              {{ agent.last_action || t('SYNAPSEOS.LIVE.LAST_ACTION_NONE') }}
            </p>
          </div>
          <span class="text-xs text-s-muted whitespace-nowrap">
            {{ relativeTime(agent.last_action_at) }}
          </span>
        </li>
      </ul>
    </SynapseCard>

    <SynapseCard :title="t('SYNAPSEOS.LIVE.HOT_CONVERSATIONS')" padding="none">
      <DataTable
        :value="liveStore.hotConversations"
        :loading="liveStore.isLoading"
        data-key="id"
        removable-sort
        :row-class="rowClass"
        class="w-full"
        @row-click="event => openConversation(event.data)"
      >
        <Column field="id" :header="t('SYNAPSEOS.LIVE.COLUMNS.CONVERSATION')" sortable>
          <template #body="{ data }">
            <span class="text-sm font-medium text-s-primary">#{{ data.id }}</span>
          </template>
        </Column>

        <Column
          field="contact_name"
          :header="t('SYNAPSEOS.LIVE.COLUMNS.CONTACT')"
          sortable
        >
          <template #body="{ data }">
            <span class="text-sm text-s-secondary">{{ data.contact_name || '—' }}</span>
          </template>
        </Column>

        <Column field="assignee_name" :header="t('SYNAPSEOS.LIVE.COLUMNS.ASSIGNEE')">
          <template #body="{ data }">
            <div class="flex items-center gap-2">
              <span class="text-sm text-s-primary">{{ data.assignee_name || '—' }}</span>
              <SynapseBadge v-if="data.assignee_type" :tone="assigneeTone(data.assignee_type)">
                {{ data.assignee_type }}
              </SynapseBadge>
            </div>
          </template>
        </Column>

        <Column field="status_label" :header="t('SYNAPSEOS.LIVE.COLUMNS.STATUS')">
          <template #body="{ data }">
            <SynapseBadge v-if="data.status_label" tone="brand">
              {{ data.status_label }}
            </SynapseBadge>
            <span v-else class="text-xs text-s-muted">—</span>
          </template>
        </Column>

        <Column
          field="time_in_stage_seconds"
          :header="t('SYNAPSEOS.LIVE.COLUMNS.TIME_IN_STAGE')"
          sortable
        >
          <template #body="{ data }">
            <span class="text-sm text-s-secondary">
              {{ formatTimeInStage(data.time_in_stage_seconds) }}
            </span>
          </template>
        </Column>
      </DataTable>
    </SynapseCard>
  </div>
</template>
