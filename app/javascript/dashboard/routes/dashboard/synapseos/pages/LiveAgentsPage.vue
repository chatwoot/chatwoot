<script setup>
import { ref, onMounted, onBeforeUnmount } from 'vue';
import { useI18n } from 'vue-i18n';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import Tag from 'primevue/tag';
import axios from 'axios';
import { useRoute } from 'vue-router';

const { t } = useI18n();
const route = useRoute();
const agents = ref([]);
const loading = ref(true);
const pollTimer = ref(null);

const severityForAvailability = availability => {
  const map = {
    online: 'success',
    busy: 'warn',
    offline: 'secondary',
  };
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

onMounted(() => {
  fetchAgents();
  pollTimer.value = setInterval(fetchAgents, 15000);
});

onBeforeUnmount(() => {
  if (pollTimer.value) clearInterval(pollTimer.value);
});
</script>

<template>
  <div class="flex flex-col gap-4 p-6 h-full overflow-auto">
    <header class="flex items-start justify-between">
      <div>
        <h1 class="text-xl font-semibold text-n-slate-12">
          {{ t('SYNAPSEOS.LIVE_AGENTS.TITLE') }}
        </h1>
        <p class="text-sm text-n-slate-11">
          {{ t('SYNAPSEOS.LIVE_AGENTS.SUBTITLE') }}
        </p>
      </div>
    </header>

    <DataTable
      :value="agents"
      :loading="loading"
      striped-rows
      data-key="id"
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
            <div v-else class="size-8 rounded-full bg-n-slate-4 flex items-center justify-center text-xs text-n-slate-11">
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
          {{ formatSeconds(data.avg_first_response_seconds) }}
        </template>
      </Column>

      <Column field="role" :header="t('SYNAPSEOS.LIVE_AGENTS.COL_ROLE')" sortable>
        <template #body="{ data }">
          <span class="text-xs text-n-slate-11 capitalize">{{ data.role }}</span>
        </template>
      </Column>
    </DataTable>
  </div>
</template>
