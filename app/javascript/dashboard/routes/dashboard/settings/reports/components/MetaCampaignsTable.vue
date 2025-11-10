<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter, useRoute } from 'vue-router';

const props = defineProps({
  campaigns: {
    type: Array,
    default: () => [],
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
});

const { t } = useI18n();
const router = useRouter();
const route = useRoute();

const formatDate = timestamp => {
  if (!timestamp) return '-';
  return new Date(timestamp).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  });
};

const getTypeLabel = type => {
  const types = {
    ad: t('META_CAMPAIGNS.TYPES.AD'),
    post: t('META_CAMPAIGNS.TYPES.POST'),
  };
  return types[type] || type;
};

const hasCampaigns = computed(() => props.campaigns.length > 0);

const goToCampaignDetail = sourceId => {
  router.push({
    name: 'meta_campaign_reports_show',
    params: {
      accountId: route.params.accountId,
      id: sourceId,
    },
  });
};
</script>

<template>
  <div
    class="rounded-lg border border-slate-200 bg-white shadow-sm dark:border-slate-700 dark:bg-slate-800"
  >
    <div class="border-b border-slate-200 px-6 py-4 dark:border-slate-700">
      <h3 class="text-lg font-semibold text-slate-900 dark:text-slate-100">
        {{ $t('META_CAMPAIGNS.TABLE.TITLE') }}
      </h3>
    </div>

    <div v-if="isLoading" class="p-6">
      <div class="space-y-3">
        <div
          v-for="i in 5"
          :key="i"
          class="h-16 animate-pulse rounded bg-slate-100 dark:bg-slate-700"
        />
      </div>
    </div>

    <div v-else-if="!hasCampaigns" class="p-12 text-center">
      <h4 class="mb-2 text-lg font-semibold text-slate-900 dark:text-slate-100">
        {{ $t('META_CAMPAIGNS.TABLE.NO_DATA') }}
      </h4>
      <p class="text-sm text-slate-600 dark:text-slate-400">
        {{ $t('META_CAMPAIGNS.TABLE.NO_DATA_DESCRIPTION') }}
      </p>
    </div>

    <div v-else class="overflow-x-auto">
      <table class="w-full">
        <thead class="bg-slate-50 dark:bg-slate-900/50">
          <tr>
            <th
              class="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-slate-600 dark:text-slate-400"
            >
              {{ $t('META_CAMPAIGNS.TABLE.CAMPAIGN_ID') }}
            </th>
            <th
              class="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-slate-600 dark:text-slate-400"
            >
              {{ $t('META_CAMPAIGNS.TABLE.TYPE') }}
            </th>
            <th
              class="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-slate-600 dark:text-slate-400"
            >
              {{ $t('META_CAMPAIGNS.TABLE.HEADLINE') }}
            </th>
            <th
              class="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-slate-600 dark:text-slate-400"
            >
              {{ $t('META_CAMPAIGNS.TABLE.INTERACTIONS') }}
            </th>
            <th
              class="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-slate-600 dark:text-slate-400"
            >
              {{ $t('META_CAMPAIGNS.TABLE.FIRST_INTERACTION') }}
            </th>
            <th
              class="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-slate-600 dark:text-slate-400"
            >
              {{ $t('META_CAMPAIGNS.TABLE.LAST_INTERACTION') }}
            </th>
          </tr>
        </thead>
        <tbody
          class="divide-y divide-slate-200 bg-white dark:divide-slate-700 dark:bg-slate-800"
        >
          <tr
            v-for="campaign in campaigns"
            :key="campaign.source_id"
            class="transition-colors hover:bg-slate-50 dark:hover:bg-slate-700/50 cursor-pointer"
            @click="goToCampaignDetail(campaign.source_id)"
          >
            <td class="whitespace-nowrap px-6 py-4">
              <div class="flex items-center">
                <span
                  class="rounded bg-blue-100 px-2 py-1 text-xs font-mono text-blue-800 dark:bg-blue-900/50 dark:text-blue-300"
                >
                  {{ campaign.source_id }}
                </span>
              </div>
            </td>
            <td class="whitespace-nowrap px-6 py-4">
              <span
                class="inline-flex rounded-full px-2 py-1 text-xs font-semibold"
                :class="{
                  'bg-green-100 text-green-800 dark:bg-green-900/50 dark:text-green-300':
                    campaign.source_type === 'ad',
                  'bg-purple-100 text-purple-800 dark:bg-purple-900/50 dark:text-purple-300':
                    campaign.source_type === 'post',
                }"
              >
                {{ getTypeLabel(campaign.source_type) }}
              </span>
            </td>
            <td class="px-6 py-4">
              <div class="max-w-xs">
                <p
                  class="truncate text-sm font-medium text-slate-900 dark:text-slate-100"
                >
                  {{ campaign.metadata?.headline || '-' }}
                </p>
                <p
                  v-if="campaign.metadata?.body"
                  class="truncate text-xs text-slate-500 dark:text-slate-400"
                >
                  {{ campaign.metadata.body }}
                </p>
              </div>
            </td>
            <td class="whitespace-nowrap px-6 py-4">
              <span
                class="inline-flex items-center rounded-full bg-slate-100 px-3 py-1 text-sm font-semibold text-slate-800 dark:bg-slate-700 dark:text-slate-200"
              >
                {{ campaign.interaction_count }}
              </span>
            </td>
            <td
              class="whitespace-nowrap px-6 py-4 text-sm text-slate-600 dark:text-slate-400"
            >
              {{ formatDate(campaign.first_interaction) }}
            </td>
            <td
              class="whitespace-nowrap px-6 py-4 text-sm text-slate-600 dark:text-slate-400"
            >
              {{ formatDate(campaign.last_interaction) }}
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
