<script setup>
import { ref, computed, onMounted, onBeforeUnmount } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
/* global axios */
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import SynapseCard from 'next/synapseos/SynapseCard.vue';
import SynapseKpiCard from 'next/synapseos/SynapseKpiCard.vue';
import SynapseStatusPill from 'next/synapseos/SynapseStatusPill.vue';
import SynapseBadge from 'next/synapseos/SynapseBadge.vue';
import SynapseInput from 'next/synapseos/SynapseInput.vue';
import SynapseEmptyState from 'next/synapseos/SynapseEmptyState.vue';
import AgentConversationsPanel from '../components/AgentConversationsPanel.vue';

const { t } = useI18n();
const route = useRoute();
const agents = ref([]);
const loading = ref(true);
const fetchError = ref(null);
const pollTimer = ref(null);
const searchQuery = ref('');
const selectedAgent = ref(null);

const availabilityTone = availability => {
  const map = { online: 'success', busy: 'warning', offline: 'neutral' };
  return map[availability] || 'neutral';
};

const formatSeconds = seconds => {
  if (seconds === null || seconds === undefined) return '—';
  if (seconds < 60) return `${seconds}s`;
  const minutes = Math.floor(seconds / 60);
  const remainder = seconds % 60;
  return remainder ? `${minutes}m ${remainder}s` : `${minutes}m`;
};

const firstResponseClass = seconds => {
  if (seconds === null || seconds === undefined) return 'text-s-muted';
  return seconds > 300 ? 'text-s-warning-text' : 'text-s-muted';
};

const fetchAgents = async () => {
  const accountId = route.params.accountId;
  try {
    const { data } = await axios.get(
      `/api/v1/accounts/${accountId}/synapseos/live_agents`
    );
    agents.value = Array.isArray(data) ? data : [];
    fetchError.value = null;
  } catch (err) {
    // Endpoint falhou (401/403/404/500/network). Sem try/catch o loading
    // ficava eterno; agora registramos o erro e desligamos o spinner.
    fetchError.value =
      err?.response?.data?.message ||
      err?.message ||
      'Falha ao carregar agentes';
    if (import.meta.env.DEV) {
      // eslint-disable-next-line no-console
      console.error('[LiveAgents] fetch failed', err);
    }
  } finally {
    loading.value = false;
  }
};

const filteredAgents = computed(() => {
  if (!searchQuery.value.trim()) return agents.value;
  const q = searchQuery.value.toLowerCase();
  return agents.value.filter(
    a => a.name?.toLowerCase().includes(q) || a.email?.toLowerCase().includes(q)
  );
});

const summary = computed(() => {
  const total = agents.value.length;
  const online = agents.value.filter(a => a.availability === 'online').length;
  const busy = agents.value.filter(a => a.availability === 'busy').length;
  const offline = agents.value.filter(a => a.availability === 'offline').length;
  const openConversations = agents.value.reduce(
    (sum, a) => sum + (a.open_conversations || 0),
    0
  );
  const handledToday = agents.value.reduce(
    (sum, a) => sum + (a.conversations_today || 0),
    0
  );
  return { total, online, busy, offline, openConversations, handledToday };
});

const summaryCards = computed(() => [
  {
    key: 'total',
    label: t('SYNAPSEOS.LIVE_AGENTS.SUMMARY.TOTAL'),
    value: summary.value.total,
    icon: 'i-lucide-users',
    tone: 'neutral',
  },
  {
    key: 'online',
    label: t('SYNAPSEOS.LIVE_AGENTS.SUMMARY.ONLINE'),
    value: summary.value.online,
    icon: 'i-lucide-wifi',
    tone: 'success',
  },
  {
    key: 'busy',
    label: t('SYNAPSEOS.LIVE_AGENTS.SUMMARY.BUSY'),
    value: summary.value.busy,
    icon: 'i-lucide-clock',
    tone: 'warning',
  },
  {
    key: 'offline',
    label: t('SYNAPSEOS.LIVE_AGENTS.SUMMARY.OFFLINE'),
    value: summary.value.offline,
    icon: 'i-lucide-wifi-off',
    tone: 'neutral',
  },
  {
    key: 'open',
    label: t('SYNAPSEOS.LIVE_AGENTS.SUMMARY.OPEN'),
    value: summary.value.openConversations,
    icon: 'i-lucide-message-circle',
    tone: 'brand',
  },
  {
    key: 'handled',
    label: t('SYNAPSEOS.LIVE_AGENTS.SUMMARY.HANDLED_TODAY'),
    value: summary.value.handledToday,
    icon: 'i-lucide-check-circle',
    tone: 'success',
  },
]);

const handleRowClick = event => {
  const agent = event?.data;
  if (!agent) return;
  if (selectedAgent.value?.id === agent.id) {
    selectedAgent.value = null;
  } else {
    selectedAgent.value = agent;
  }
};

const rowClass = data =>
  selectedAgent.value?.id === data?.id ? 'bg-s-subtle' : null;

onMounted(() => {
  fetchAgents();
  pollTimer.value = setInterval(fetchAgents, 15000);
});

onBeforeUnmount(() => {
  if (pollTimer.value) clearInterval(pollTimer.value);
});
</script>

<template>
  <div
    class="bg-s-bg p-4 sm:p-6 md:p-8 space-y-4 md:space-y-6 h-full w-full flex-1 min-w-0 overflow-auto"
  >
    <header class="flex flex-col gap-1">
      <h1 class="text-xl md:text-2xl font-semibold text-s-primary">
        {{ t('SYNAPSEOS.LIVE_AGENTS.TITLE') }}
      </h1>
      <p class="text-sm text-s-muted">
        {{ t('SYNAPSEOS.LIVE_AGENTS.SUBTITLE') }}
      </p>
    </header>

    <div
      v-if="fetchError"
      class="flex items-start gap-3 p-3 rounded-lg border border-s-error/30 bg-s-error-soft text-s-error-text text-sm"
    >
      <span class="i-lucide-alert-triangle size-4 mt-0.5 shrink-0" />
      <div class="flex-1">
        <strong class="font-semibold">Falha ao carregar agentes.</strong>
        <p class="text-xs mt-0.5 opacity-80">{{ fetchError }}</p>
      </div>
      <button
        class="i-lucide-refresh-cw size-4 shrink-0 hover:opacity-60"
        @click="fetchAgents"
      />
    </div>

    <section
      class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-3 sm:gap-4"
    >
      <SynapseKpiCard
        v-for="card in summaryCards"
        :key="card.key"
        :label="card.label"
        :value="String(card.value)"
        :icon="card.icon"
        :tone="card.tone"
      />
    </section>

    <div
      class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3 sm:gap-4"
    >
      <div class="w-full sm:w-72">
        <SynapseInput
          id="live-agents-search"
          v-model="searchQuery"
          icon-leading="i-lucide-search"
          :placeholder="t('SYNAPSEOS.LIVE_AGENTS.SEARCH_PLACEHOLDER')"
        />
      </div>
      <span class="text-xs text-s-muted">
        {{ t('SYNAPSEOS.LIVE_AGENTS.REFRESH_HINT') }}
      </span>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-[3fr_2fr] gap-4">
      <SynapseCard padding="none">
        <DataTable
          :value="filteredAgents"
          :loading="loading"
          data-key="id"
          removable-sort
          :row-class="rowClass"
          :pt="{
            table: { class: 'min-w-full' },
            bodyRow: {
              class:
                'cursor-pointer hover:bg-s-subtle transition-colors border-b border-s-border-subtle',
            },
            headerRow: { class: 'bg-s-subtle' },
            headerCell: {
              class:
                'text-xs font-semibold uppercase tracking-wide text-s-secondary !bg-s-subtle !border-b !border-s-border px-4 py-3 whitespace-nowrap',
            },
            bodyCell: {
              class: 'px-4 py-3 text-sm text-s-primary align-middle',
            },
            emptyMessage: { class: 'text-center py-8 text-sm text-s-muted' },
            loadingOverlay: { class: '!bg-s-surface/70' },
          }"
          class="w-full"
          @row-click="handleRowClick"
        >
          <template #empty>
            <SynapseEmptyState
              icon="i-lucide-users"
              :title="t('SYNAPSEOS.LIVE_AGENTS.EMPTY_TITLE')"
              :description="t('SYNAPSEOS.LIVE_AGENTS.EMPTY_DESCRIPTION')"
              size="md"
            />
          </template>
          <Column
            field="name"
            :header="t('SYNAPSEOS.LIVE_AGENTS.COL_NAME')"
            sortable
          >
            <template #body="{ data }">
              <div class="flex items-center gap-3">
                <img
                  v-if="data.thumbnail"
                  :src="data.thumbnail"
                  :alt="data.name"
                  class="rounded-full size-8"
                />
                <div
                  v-else
                  class="rounded-full size-8 bg-s-subtle flex items-center justify-center text-xs text-s-secondary font-medium"
                >
                  {{ data.name?.[0]?.toUpperCase() || '?' }}
                </div>
                <div class="flex flex-col min-w-0">
                  <span class="text-sm font-semibold !text-s-primary truncate">{{
                    data.name
                  }}</span>
                  <span class="text-xs !text-s-secondary truncate">{{
                    data.email
                  }}</span>
                </div>
              </div>
            </template>
          </Column>

          <Column
            field="availability"
            :header="t('SYNAPSEOS.LIVE_AGENTS.COL_STATUS')"
            sortable
          >
            <template #body="{ data }">
              <SynapseStatusPill :tone="availabilityTone(data.availability)">
                {{
                  t(
                    `SYNAPSEOS.LIVE_AGENTS.STATUS.${data.availability.toUpperCase()}`
                  )
                }}
              </SynapseStatusPill>
            </template>
          </Column>

          <Column
            field="open_conversations"
            :header="t('SYNAPSEOS.LIVE_AGENTS.COL_OPEN')"
            sortable
          />
          <Column
            field="conversations_today"
            :header="t('SYNAPSEOS.LIVE_AGENTS.COL_TODAY')"
            sortable
          />

          <Column
            field="avg_first_response_seconds"
            :header="t('SYNAPSEOS.LIVE_AGENTS.COL_FIRST_RESPONSE')"
            sortable
          >
            <template #body="{ data }">
              <span
                :class="[
                  'text-sm',
                  firstResponseClass(data.avg_first_response_seconds),
                ]"
              >
                {{ formatSeconds(data.avg_first_response_seconds) }}
              </span>
            </template>
          </Column>

          <Column
            field="role"
            :header="t('SYNAPSEOS.LIVE_AGENTS.COL_ROLE')"
            sortable
          >
            <template #body="{ data }">
              <SynapseBadge
                :tone="data.role === 'administrator' ? 'brand' : 'neutral'"
              >
                <span class="capitalize">{{ data.role }}</span>
              </SynapseBadge>
            </template>
          </Column>
        </DataTable>
      </SynapseCard>

      <div v-if="selectedAgent">
        <AgentConversationsPanel
          :agent="selectedAgent"
          @close="selectedAgent = null"
        />
      </div>
      <SynapseCard
        v-else
        padding="none"
        class="hidden lg:flex items-center justify-center min-h-[300px]"
      >
        <SynapseEmptyState
          icon="i-lucide-mouse-pointer-click"
          :title="t('SYNAPSEOS.LIVE_AGENTS.PANEL.HINT')"
          size="sm"
        />
      </SynapseCard>
    </div>
  </div>
</template>
