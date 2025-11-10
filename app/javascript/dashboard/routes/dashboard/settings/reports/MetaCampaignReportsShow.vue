<script setup>
import { ref, computed, onMounted } from 'vue';
import { useStore } from 'vuex';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import ReportHeader from './components/ReportHeader.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const store = useStore();
const route = useRoute();
const router = useRouter();
const { t } = useI18n();

const sourceId = route.params.id;
const dateRange = ref({
  from: Math.floor(Date.now() / 1000) - 30 * 24 * 60 * 60,
  to: Math.floor(Date.now() / 1000),
});

const campaignDetails = computed(
  () => store.getters['metaCampaigns/getCampaignDetails']
);
const uiFlags = computed(() => store.getters['metaCampaigns/getUIFlags']);

const interactions = computed(
  () => campaignDetails.value?.interactions || []
);

const formatDate = timestamp => {
  if (!timestamp) return '-';
  return new Date(timestamp).toLocaleString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
};

const goBack = () => {
  router.push({ name: 'meta_campaign_reports_index' });
};

const goToConversation = conversationId => {
  const accountId = route.params.accountId;
  router.push({
    name: 'inbox_conversation',
    params: { accountId, conversation_id: conversationId },
  });
};

const fetchData = async () => {
  const params = {
    since: dateRange.value.from,
    until: dateRange.value.to,
  };

  try {
    await store.dispatch('metaCampaigns/fetchCampaignDetails', {
      sourceId,
      params,
    });
  } catch (error) {
    console.error('Failed to fetch campaign details:', error);
  }
};

onMounted(() => {
  fetchData();
});
</script>

<template>
  <div class="flex flex-col h-full">
    <ReportHeader
      :header-title="$t('META_CAMPAIGNS.DETAIL.HEADER')"
      :header-description="$t('META_CAMPAIGNS.DETAIL.DESCRIPTION')"
    />

    <div
      v-if="uiFlags.isFetchingDetails"
      class="flex-1 flex items-center justify-center"
    >
      <Spinner />
    </div>

    <div
      v-else-if="campaignDetails"
      class="flex flex-col gap-6 p-6 dark:bg-slate-900"
    >
      <!-- Back Button -->
      <button
        class="flex items-center gap-2 text-slate-600 hover:text-slate-900 dark:text-slate-400 dark:hover:text-slate-100 w-fit"
        @click="goBack"
      >
        <svg
          class="w-5 h-5"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M15 19l-7-7 7-7"
          />
        </svg>
        {{ $t('META_CAMPAIGNS.DETAIL.BACK_TO_CAMPAIGNS') }}
      </button>

      <!-- Campaign ID -->
      <div>
        <h2 class="text-2xl font-bold text-slate-900 dark:text-slate-100">
          {{ $t('META_CAMPAIGNS.DETAIL.CAMPAIGN_TITLE') }}
        </h2>
        <p class="text-sm text-slate-600 dark:text-slate-400 mt-1">
          {{ $t('META_CAMPAIGNS.DETAIL.CAMPAIGN_ID') }}:
          <span
            class="font-mono bg-slate-100 dark:bg-slate-700 px-2 py-1 rounded"
          >
            {{ sourceId }}
          </span>
        </p>
      </div>

      <!-- Interactions Table -->
      <div
        class="rounded-lg border border-slate-200 bg-white shadow-sm dark:border-slate-700 dark:bg-slate-800"
      >
        <div class="border-b border-slate-200 px-6 py-4 dark:border-slate-700">
          <h3 class="text-lg font-semibold text-slate-900 dark:text-slate-100">
            {{ $t('META_CAMPAIGNS.DETAIL.INTERACTIONS_TITLE') }}
            <span class="text-slate-600 dark:text-slate-400">
              ({{ interactions.length }})
            </span>
          </h3>
        </div>

        <div v-if="interactions.length === 0" class="p-12 text-center">
          <p class="text-sm text-slate-600 dark:text-slate-400">
            {{ $t('META_CAMPAIGNS.DETAIL.NO_INTERACTIONS') }}
          </p>
        </div>

        <div v-else class="overflow-x-auto">
          <table class="w-full">
            <thead class="bg-slate-50 dark:bg-slate-900/50">
              <tr>
                <th
                  class="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-slate-600 dark:text-slate-400"
                >
                  {{ $t('META_CAMPAIGNS.DETAIL.CONTACT_NAME') }}
                </th>
                <th
                  class="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-slate-600 dark:text-slate-400"
                >
                  {{ $t('META_CAMPAIGNS.DETAIL.INTERACTION_DATE') }}
                </th>
              </tr>
            </thead>
            <tbody
              class="divide-y divide-slate-200 bg-white dark:divide-slate-700 dark:bg-slate-800"
            >
              <tr
                v-for="interaction in interactions"
                :key="interaction.id"
                class="transition-colors hover:bg-slate-50 dark:hover:bg-slate-700/50"
              >
                <td class="px-6 py-4">
                  <button
                    class="text-blue-600 hover:text-blue-700 dark:text-blue-400 dark:hover:text-blue-300 font-medium"
                    @click="goToConversation(interaction.conversation_id)"
                  >
                    {{ interaction.contact_name }}
                  </button>
                </td>
                <td
                  class="whitespace-nowrap px-6 py-4 text-sm text-slate-600 dark:text-slate-400"
                >
                  {{ formatDate(interaction.created_at) }}
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <div v-else class="flex-1 flex items-center justify-center">
      <div class="text-center">
        <p class="text-lg font-semibold text-slate-900 dark:text-slate-100">
          {{ $t('META_CAMPAIGNS.DETAIL.NOT_FOUND') }}
        </p>
        <button
          class="mt-4 text-blue-600 hover:text-blue-700 dark:text-blue-400"
          @click="goBack"
        >
          {{ $t('META_CAMPAIGNS.DETAIL.BACK_TO_CAMPAIGNS') }}
        </button>
      </div>
    </div>
  </div>
</template>
