<script setup>
import { ref, computed, onMounted, onBeforeUnmount } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import axios from 'axios';
import Card from 'primevue/card';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import Tag from 'primevue/tag';
import InputText from 'primevue/inputtext';

const { t } = useI18n();
const route = useRoute();
const agents = ref([]);
const loading = ref(true);
const pollTimer = ref(null);
const searchQuery = ref('');

const severityForAvailability = availability => {
  const map = { online: 'success', busy: 'warn', offline: 'secondary' };
  return map[availability] || 'secondary';
};

const formatSeconds = seconds => {
  if (seconds === null || seconds === undefined) return '—';
  if (seconds < 60) return `${seconds}s`;
  const minutes = Math.floor(seconds / 60);
  const remainder = seconds % 60;
  return remainder ? `${minutes}m ${remainder}s` : `${minutes}m`;
};

const fetchAgents = async () => {
  const accountId = route.params.accountId;
  const { data } = await axios.get(`/api/v1/accounts/${accountId}/synapseos/live_agents`);
  agents.value = data;
  loading.value = false;
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
  const openConversations = agents.value.reduce((sum, a) => sum + (a.open_conversations || 0), 0);
  const handledToday = agents.value.reduce((sum, a) => sum + (a.conversations_today || 0), 0);
  return { total, online, busy, offline, openConversations, handledToday };
});

onMounted(() => {
  fetchAgents();
  pollTimer.value = setInterval(fetchAgents, 15000);
});

onBeforeUnmount(() => {
  if (pollTimer.value) clearInterval(pollTimer.value);
});
</script>

<template>
  <div class="flex flex-col gap-6 p-6 h-full overflow-auto">
    <header class="flex flex-col gap-2">
      <h1 class="text-2xl font-semibold text-n-slate-12">
        {{ t('SYNAPSEOS.LIVE_AGENTS.TITLE') }}
      </h1>
      <p class="text-sm text-n-slate-11">
        {{ t('SYNAPSEOS.LIVE_AGENTS.SUBTITLE') }}
      </p>
    </header>

    <section class="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-6 gap-3">
      <Card class="!shadow-none border border-n-weak">
        <template #content>
          <div class="flex flex-col gap-1">
            <span class="text-xs uppercase tracking-wide text-n-slate-10">{{ t('SYNAPSEOS.LIVE_AGENTS.SUMMARY.TOTAL') }}</span>
            <span class="text-2xl font-semibold text-n-slate-12">{{ summary.total }}</span>
          </div>
        </template>
      </Card>
      <Card class="!shadow-none border border-n-weak">
        <template #content>
          <div class="flex flex-col gap-1">
            <span class="text-xs uppercase tracking-wide text-n-slate-10">{{ t('SYNAPSEOS.LIVE_AGENTS.SUMMARY.ONLINE') }}</span>
            <span class="text-2xl font-semibold text-n-teal-9">{{ summary.online }}</span>
          </div>
        </template>
      </Card>
      <Card class="!shadow-none border border-n-weak">
        <template #content>
          <div class="flex flex-col gap-1">
            <span class="text-xs uppercase tracking-wide text-n-slate-10">{{ t('SYNAPSEOS.LIVE_AGENTS.SUMMARY.BUSY') }}</span>
            <span class="text-2xl font-semibold text-n-amber-9">{{ summary.busy }}</span>
          </div>
        </template>
      </Card>
      <Card class="!shadow-none border border-n-weak">
        <template #content>
          <div class="flex flex-col gap-1">
            <span class="text-xs uppercase tracking-wide text-n-slate-10">{{ t('SYNAPSEOS.LIVE_AGENTS.SUMMARY.OFFLINE') }}</span>
            <span class="text-2xl font-semibold text-n-slate-11">{{ summary.offline }}</span>
          </div>
        </template>
      </Card>
      <Card class="!shadow-none border border-n-weak">
        <template #content>
          <div class="flex flex-col gap-1">
            <span class="text-xs uppercase tracking-wide text-n-slate-10">{{ t('SYNAPSEOS.LIVE_AGENTS.SUMMARY.OPEN') }}</span>
            <span class="text-2xl font-semibold text-n-blue-9">{{ summary.openConversations }}</span>
          </div>
        </template>
      </Card>
      <Card class="!shadow-none border border-n-weak">
        <template #content>
          <div class="flex flex-col gap-1">
            <span class="text-xs uppercase tracking-wide text-n-slate-10">{{ t('SYNAPSEOS.LIVE_AGENTS.SUMMARY.HANDLED_TODAY') }}</span>
            <span class="text-2xl font-semibold text-n-slate-12">{{ summary.handledToday }}</span>
          </div>
        </template>
      </Card>
    </section>

    <div class="flex items-center justify-between">
      <InputText
        v-model="searchQuery"
        :placeholder="t('SYNAPSEOS.LIVE_AGENTS.SEARCH_PLACEHOLDER')"
        class="w-72"
      />
      <span class="text-xs text-n-slate-10">
        {{ t('SYNAPSEOS.LIVE_AGENTS.REFRESH_HINT') }}
      </span>
    </div>

    <Card class="!shadow-none border border-n-weak">
      <template #content>
        <DataTable
          :value="filteredAgents"
          :loading="loading"
          data-key="id"
          removable-sort
          :pt="{ table: { class: 'min-w-full' } }"
          class="w-full"
        >
          <Column field="name" :header="t('SYNAPSEOS.LIVE_AGENTS.COL_NAME')" sortable>
            <template #body="{ data }">
              <div class="flex items-center gap-3">
                <img
                  v-if="data.thumbnail"
                  :src="data.thumbnail"
                  :alt="data.name"
                  class="size-8 rounded-full"
                >
                <div v-else class="size-8 rounded-full bg-n-slate-4 flex items-center justify-center text-xs text-n-slate-11 font-medium">
                  {{ data.name?.[0]?.toUpperCase() || '?' }}
                </div>
                <div class="flex flex-col">
                  <span class="font-medium text-n-slate-12">{{ data.name }}</span>
                  <span class="text-xs text-n-slate-10">{{ data.email }}</span>
                </div>
              </div>
            </template>
          </Column>

          <Column field="availability" :header="t('SYNAPSEOS.LIVE_AGENTS.COL_STATUS')" sortable>
            <template #body="{ data }">
              <Tag
                :value="t(`SYNAPSEOS.LIVE_AGENTS.STATUS.${data.availability.toUpperCase()}`)"
                :severity="severityForAvailability(data.availability)"
              />
            </template>
          </Column>

          <Column field="open_conversations" :header="t('SYNAPSEOS.LIVE_AGENTS.COL_OPEN')" sortable />
          <Column field="conversations_today" :header="t('SYNAPSEOS.LIVE_AGENTS.COL_TODAY')" sortable />

          <Column field="avg_first_response_seconds" :header="t('SYNAPSEOS.LIVE_AGENTS.COL_FIRST_RESPONSE')" sortable>
            <template #body="{ data }">
              {{ formatSeconds(data.avg_first_response_seconds) }}
            </template>
          </Column>

          <Column field="role" :header="t('SYNAPSEOS.LIVE_AGENTS.COL_ROLE')" sortable>
            <template #body="{ data }">
              <span class="text-xs text-n-slate-11 capitalize">{{ data.role }}</span>
            </template>
          </Column>
        </DataTable>
      </template>
    </Card>
  </div>
</template>
