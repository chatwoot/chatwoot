<script setup>
import { ref, computed, onMounted } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import ReportHeader from './components/ReportHeader.vue';
import ReportFilterSelector from './components/FilterSelector.vue';
import MetaCampaignsTable from './components/MetaCampaignsTable.vue';
import MetaCampaignsSummary from './components/MetaCampaignsSummary.vue';
import { useAlert } from 'dashboard/composables';

const store = useStore();
const { t } = useI18n();

const selectedInboxId = ref(null);
const dateRange = ref({
  from: Math.floor(Date.now() / 1000) - 30 * 24 * 60 * 60, // Last 30 days
  to: Math.floor(Date.now() / 1000),
});

const campaigns = computed(() => store.getters['metaCampaigns/getCampaigns']);
const summary = computed(() => store.getters['metaCampaigns/getSummary']);
const uiFlags = computed(() => store.getters['metaCampaigns/getUIFlags']);
const inboxes = computed(() => store.getters['inboxes/getWhatsAppInboxes']);

const fetchData = async () => {
  const params = {
    since: dateRange.value.from,
    until: dateRange.value.to,
  };

  if (selectedInboxId.value) {
    params.inbox_id = selectedInboxId.value;
  }

  try {
    await Promise.all([
      store.dispatch('metaCampaigns/fetchCampaigns', params),
      store.dispatch('metaCampaigns/fetchSummary', params),
    ]);
  } catch (error) {
    useAlert(t('META_CAMPAIGNS.API.ERROR'));
  }
};

const onFilterChange = ({ from, to }) => {
  dateRange.value = { from, to };
  fetchData();
};

const onInboxChange = inboxId => {
  selectedInboxId.value = inboxId;
  fetchData();
};

onMounted(() => {
  store.dispatch('inboxes/get');
  fetchData();
});
</script>

<template>
  <ReportHeader
    :header-title="$t('META_CAMPAIGNS.HEADER')"
    :header-description="$t('META_CAMPAIGNS.DESCRIPTION')"
  />

  <div class="flex flex-col gap-4 p-6 dark:bg-slate-900">
    <!-- Filters -->
    <div class="flex gap-4">
      <ReportFilterSelector
        :show-agents-filter="false"
        :show-group-by-filter="false"
        :show-business-hours-switch="false"
        @filter-change="onFilterChange"
      />

      <select
        v-model="selectedInboxId"
        class="rounded-md border border-slate-300 bg-white px-3 py-2 text-slate-900 dark:border-slate-600 dark:bg-slate-800 dark:text-slate-100"
        @change="onInboxChange(selectedInboxId)"
      >
        <option :value="null">
          {{ $t('META_CAMPAIGNS.ALL_INBOXES') }}
        </option>
        <option v-for="inbox in inboxes" :key="inbox.id" :value="inbox.id">
          {{ inbox.name }}
        </option>
      </select>
    </div>

    <!-- Summary Cards -->
    <MetaCampaignsSummary
      :summary="summary"
      :is-loading="uiFlags.isFetchingSummary"
    />

    <!-- Campaigns Table -->
    <MetaCampaignsTable
      :campaigns="campaigns"
      :is-loading="uiFlags.isFetchingCampaigns"
    />
  </div>
</template>
