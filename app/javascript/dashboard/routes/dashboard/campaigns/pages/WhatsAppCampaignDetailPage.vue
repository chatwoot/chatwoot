<script setup>
import { ref, computed, onMounted, onUnmounted, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import CampaignsAPI from 'dashboard/api/campaigns';
import { useMapGetter } from 'dashboard/composables/store';

import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import PaginationFooter from 'dashboard/components-next/pagination/PaginationFooter.vue';

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const currentAccountId = useMapGetter('getCurrentAccountId');

const campaign = ref(null);
const isLoading = ref(true);
const pollingInterval = ref(null);
const currentPage = ref(1);

const campaignContacts = computed(
  () => campaign.value?.campaign_contacts || []
);
const statistics = computed(
  () =>
    campaign.value?.statistics || {
      total: 0,
      sent: 0,
      failed: 0,
      pending: 0,
      skipped: 0,
    }
);
const paginationMeta = computed(() => campaign.value?.meta || {});
const totalContacts = computed(() => paginationMeta.value.total_count || 0);

const preparationProgress = computed(() => {
  if (!campaign.value) return 0;
  const total = campaign.value.total_contacts_count || 0;
  const prepared = campaign.value.prepared_contacts_count || 0;
  if (total === 0) return 100;
  return Math.round((prepared / total) * 100);
});

const isPreparingContacts = computed(
  () => campaign.value?.contacts_preparation_status === 'preparing'
);

const statusColors = {
  pending: 'bg-n-yellow-3 text-n-yellow-11',
  sent: 'bg-n-green-3 text-n-green-11',
  failed: 'bg-n-red-3 text-n-red-11',
  skipped: 'bg-n-slate-3 text-n-slate-11',
};

const getStatusLabel = status => {
  const labels = {
    pending: t('CAMPAIGN.DETAIL.STATUS.PENDING'),
    sent: t('CAMPAIGN.DETAIL.STATUS.SENT'),
    failed: t('CAMPAIGN.DETAIL.STATUS.FAILED'),
    skipped: t('CAMPAIGN.DETAIL.STATUS.SKIPPED'),
  };
  return labels[status] || status;
};

const formatDate = date => {
  if (!date) return '-';
  return new Date(date).toLocaleString();
};

const goBack = () => {
  router.push({ name: 'campaigns_whatsapp_index' });
};

const stopPolling = () => {
  if (pollingInterval.value) {
    clearInterval(pollingInterval.value);
    pollingInterval.value = null;
  }
};

async function fetchCampaign() {
  try {
    const response = await CampaignsAPI.show(route.params.campaignId, {
      page: currentPage.value,
      per_page: 25,
    });
    campaign.value = response.data;

    // Start polling if contacts are being prepared
    if (
      response.data.contacts_preparation_status === 'preparing' &&
      !pollingInterval.value
    ) {
      pollingInterval.value = setInterval(fetchCampaign, 2000);
    } else if (
      response.data.contacts_preparation_status !== 'preparing' &&
      pollingInterval.value
    ) {
      stopPolling();
    }
  } catch (error) {
    // Error handled silently
  }
}

const handlePageChange = newPage => {
  currentPage.value = newPage;
  fetchCampaign();
};

watch(
  () => route.params.campaignId,
  async () => {
    stopPolling();
    isLoading.value = true;
    campaign.value = null;
    currentPage.value = 1;
    await fetchCampaign();
    isLoading.value = false;
  }
);

onMounted(async () => {
  await fetchCampaign();
  isLoading.value = false;
});

onUnmounted(() => {
  stopPolling();
});
</script>

<template>
  <div class="flex flex-col h-full">
    <!-- Header -->
    <div
      class="flex items-center justify-between p-6 border-b border-n-slate-6"
    >
      <div class="flex items-center gap-4">
        <Button
          variant="faded"
          color="slate"
          icon="i-lucide-arrow-left"
          @click="goBack"
        />
        <div>
          <h1 class="text-2xl font-semibold text-n-slate-12">
            {{ campaign?.title }}
          </h1>
          <p class="text-sm text-n-slate-11 mt-1">
            {{ t('CAMPAIGN.DETAIL.SUBTITLE') }}
          </p>
        </div>
      </div>
    </div>

    <!-- Preparation Progress Banner -->
    <div
      v-if="isPreparingContacts && !isLoading"
      class="mx-6 mt-6 p-4 bg-n-blue-2 border border-n-blue-6 rounded-lg"
    >
      <div class="flex items-center justify-between mb-2">
        <div class="flex items-center gap-2">
          <Spinner class="w-4 h-4" />
          <p class="text-sm font-medium text-n-blue-12">
            {{ t('CAMPAIGN.DETAIL.PREPARING_CONTACTS') }}
          </p>
        </div>
        <p class="text-sm text-n-blue-11">
          {{ campaign.prepared_contacts_count }}
          {{ t('CAMPAIGN.DETAIL.OF') }}
          {{ campaign.total_contacts_count }}
        </p>
      </div>
      <div class="w-full bg-n-blue-3 rounded-full h-2">
        <div
          class="bg-n-blue-9 h-2 rounded-full transition-all duration-300"
          :style="{ width: `${preparationProgress}%` }"
        />
      </div>
    </div>

    <!-- Statistics Cards -->
    <div v-if="!isLoading" class="grid grid-cols-5 gap-4 p-6">
      <div
        class="p-4 border border-n-slate-6 shadow outline-1 outline outline-n-container rounded-2xl bg-n-solid-2"
      >
        <p class="text-sm text-n-slate-11">
          {{ t('CAMPAIGN.DETAIL.STATS.TOTAL') }}
        </p>
        <p class="text-2xl font-semibold text-n-slate-12 mt-1">
          {{ statistics.total }}
        </p>
      </div>
      <div
        class="p-4 border border-n-slate-6 shadow outline-1 outline outline-n-container rounded-2xl bg-n-solid-2"
      >
        <p class="text-sm text-n-green-11">
          {{ t('CAMPAIGN.DETAIL.STATS.SENT') }}
        </p>
        <p class="text-2xl font-semibold text-n-green-12 mt-1">
          {{ statistics.sent }}
        </p>
      </div>
      <div
        class="p-4 border border-n-slate-6 shadow outline-1 outline outline-n-container rounded-2xl bg-n-solid-2"
      >
        <p class="text-sm text-n-red-11">
          {{ t('CAMPAIGN.DETAIL.STATS.FAILED') }}
        </p>
        <p class="text-2xl font-semibold text-n-red-12 mt-1">
          {{ statistics.failed }}
        </p>
      </div>
      <div
        class="p-4 border border-n-slate-6 shadow outline-1 outline outline-n-container rounded-2xl bg-n-solid-2"
      >
        <p class="text-sm text-n-yellow-11">
          {{ t('CAMPAIGN.DETAIL.STATS.PENDING') }}
        </p>
        <p class="text-2xl font-semibold text-n-yellow-12 mt-1">
          {{ statistics.pending }}
        </p>
      </div>
      <div
        class="p-4 border border-n-slate-6 shadow outline-1 outline outline-n-container rounded-2xl bg-n-solid-2"
      >
        <p class="text-sm text-n-slate-11">
          {{ t('CAMPAIGN.DETAIL.STATS.SKIPPED') }}
        </p>
        <p class="text-2xl font-semibold text-n-slate-12 mt-1">
          {{ statistics.skipped }}
        </p>
      </div>
    </div>

    <!-- Loading State -->
    <div v-if="isLoading" class="flex items-center justify-center py-20">
      <Spinner />
    </div>

    <!-- Contacts Table -->
    <div v-else class="flex-1 overflow-auto p-6">
      <div
        class="bg-n-white dark:bg-n-slate-1 rounded-lg border border-n-slate-6 overflow-hidden"
      >
        <table class="w-full">
          <thead class="bg-n-solid-2 border-b border-n-slate-6">
            <tr>
              <th class="text-left p-4 text-sm font-medium text-n-slate-12">
                {{ t('CAMPAIGN.DETAIL.TABLE.CONTACT') }}
              </th>
              <th class="text-left p-4 text-sm font-medium text-n-slate-12">
                {{ t('CAMPAIGN.DETAIL.TABLE.PHONE') }}
              </th>
              <th class="text-left p-4 text-sm font-medium text-n-slate-12">
                {{ t('CAMPAIGN.DETAIL.TABLE.STATUS') }}
              </th>
              <th class="text-left p-4 text-sm font-medium text-n-slate-12">
                {{ t('CAMPAIGN.DETAIL.TABLE.SENT_AT') }}
              </th>
              <th class="text-left p-4 text-sm font-medium text-n-slate-12">
                {{ t('CAMPAIGN.DETAIL.TABLE.ERROR') }}
              </th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="campaignContact in campaignContacts"
              :key="campaignContact.id"
              class="border-b border-n-slate-6 hover:bg-n-slate-2"
            >
              <td class="p-4">
                <div class="flex items-center gap-3">
                  <img
                    v-if="campaignContact.contact.thumbnail"
                    :src="campaignContact.contact.thumbnail"
                    class="w-8 h-8 rounded-full"
                    :alt="campaignContact.contact.name"
                  />
                  <div
                    v-else
                    class="w-8 h-8 rounded-full bg-n-slate-3 flex items-center justify-center text-n-slate-11 text-sm font-medium"
                  >
                    {{ campaignContact.contact.name?.charAt(0).toUpperCase() }}
                  </div>
                  <div>
                    <router-link
                      :to="{
                        name: 'contacts_edit',
                        params: {
                          accountId: currentAccountId,
                          contactId: campaignContact.contact.id,
                        },
                      }"
                      class="text-sm font-medium text-n-slate-12 hover:text-n-blue-11 hover:underline"
                    >
                      {{ campaignContact.contact.name }}
                    </router-link>
                    <p class="text-xs text-n-slate-11">
                      {{ campaignContact.contact.email }}
                    </p>
                  </div>
                </div>
              </td>
              <td class="p-4 text-sm text-n-slate-11">
                {{ campaignContact.contact.phone_number || '-' }}
              </td>
              <td class="p-4">
                <span
                  :class="statusColors[campaignContact.status]"
                  class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium"
                >
                  {{ getStatusLabel(campaignContact.status) }}
                </span>
              </td>
              <td class="p-4 text-sm text-n-slate-11">
                {{ formatDate(campaignContact.sent_at) }}
              </td>
              <td class="p-4 text-sm text-n-red-11">
                {{ campaignContact.error_message || '-' }}
              </td>
            </tr>
          </tbody>
        </table>

        <!-- Empty State -->
        <div v-if="campaignContacts.length === 0" class="p-12 text-center">
          <p class="text-n-slate-11">
            {{ t('CAMPAIGN.DETAIL.EMPTY_STATE') }}
          </p>
        </div>

        <!-- Pagination -->
        <div v-if="totalContacts > 0" class="border-t border-n-slate-6 p-4">
          <PaginationFooter
            :current-page="currentPage"
            :total-items="totalContacts"
            :items-per-page="25"
            @update:current-page="handlePageChange"
          />
        </div>
      </div>
    </div>
  </div>
</template>
