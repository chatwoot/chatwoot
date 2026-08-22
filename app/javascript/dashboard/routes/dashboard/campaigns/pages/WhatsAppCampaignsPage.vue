<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStoreGetters, useMapGetter } from 'dashboard/composables/store';
import { INBOX_TYPES } from 'dashboard/helper/inbox';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import CampaignLayout from 'dashboard/components-next/Campaigns/CampaignLayout.vue';
import CampaignList from 'dashboard/components-next/Campaigns/Pages/CampaignPage/CampaignList.vue';
import WhatsAppCampaignsTable from 'dashboard/components-next/Campaigns/Pages/CampaignPage/WhatsAppCampaign/WhatsAppCampaignsTable.vue';
import WhatsAppCampaignsFilterBar from 'dashboard/components-next/Campaigns/Pages/CampaignPage/WhatsAppCampaign/WhatsAppCampaignsFilterBar.vue';
import WhatsAppCampaignDetailPanel from 'dashboard/components-next/Campaigns/Pages/CampaignPage/WhatsAppCampaign/WhatsAppCampaignDetailPanel.vue';
import WhatsAppCampaignDialog from 'dashboard/components-next/Campaigns/Pages/CampaignPage/WhatsAppCampaign/WhatsAppCampaignDialog.vue';
import ConfirmDeleteCampaignDialog from 'dashboard/components-next/Campaigns/Pages/CampaignPage/ConfirmDeleteCampaignDialog.vue';
import WhatsAppCampaignEmptyState from 'dashboard/components-next/Campaigns/EmptyState/WhatsAppCampaignEmptyState.vue';
import WhatsAppCampaignAttributionNotice from 'dashboard/components-next/Campaigns/Pages/CampaignPage/WhatsAppCampaign/WhatsAppCampaignAttributionNotice.vue';
import PaginationFooter from 'dashboard/components-next/pagination/PaginationFooter.vue';
import { useRouter } from 'vue-router';

const DEFAULT_ITEMS_PER_PAGE = 25;
const PER_PAGE_OPTIONS = [15, 25, 50];

const { t } = useI18n();
const getters = useStoreGetters();
const router = useRouter();

const selectedCampaign = ref(null);
const editingCampaign = ref(null);
const detailCampaign = ref(null);
const currentPage = ref(1);
const itemsPerPage = ref(DEFAULT_ITEMS_PER_PAGE);
const searchQuery = ref('');
const statusFilter = ref('all');
const inboxId = ref(null);
const whatsAppCampaignDialogRef = ref(null);
const detailPanelRef = ref(null);

const uiFlags = useMapGetter('campaigns/getUIFlags');
const isFetchingCampaigns = computed(() => uiFlags.value.isFetching);
const confirmDeleteCampaignDialogRef = ref(null);

const WhatsAppCampaigns = computed(
  () => getters['campaigns/getWhatsAppCampaigns'].value
);

const whatsappInboxes = computed(() => {
  const seen = new Map();
  WhatsAppCampaigns.value.forEach(campaign => {
    if (
      campaign.inbox?.id &&
      campaign.inbox?.channel_type === INBOX_TYPES.WHATSAPP
    ) {
      seen.set(campaign.inbox.id, campaign.inbox);
    }
  });
  return [...seen.values()];
});

const sortedCampaigns = computed(() =>
  [...(WhatsAppCampaigns.value || [])].sort(
    (a, b) => new Date(b.scheduled_at || 0) - new Date(a.scheduled_at || 0)
  )
);

const hasActiveFilters = computed(
  () =>
    Boolean(searchQuery.value.trim()) ||
    statusFilter.value !== 'all' ||
    inboxId.value != null
);

const filteredCampaigns = computed(() => {
  const query = searchQuery.value.trim().toLowerCase();

  return sortedCampaigns.value.filter(campaign => {
    if (statusFilter.value !== 'all') {
      if (campaign.campaign_status !== statusFilter.value) return false;
    }
    if (inboxId.value != null && campaign.inbox?.id !== inboxId.value) {
      return false;
    }
    if (query && !campaign.title?.toLowerCase().includes(query)) return false;
    return true;
  });
});

const paginatedCampaigns = computed(() => {
  const start = (currentPage.value - 1) * itemsPerPage.value;
  return filteredCampaigns.value.slice(start, start + itemsPerPage.value);
});

const hasNoWhatsAppCampaigns = computed(
  () => WhatsAppCampaigns.value?.length === 0 && !isFetchingCampaigns.value
);

const showFilteredEmpty = computed(
  () =>
    !isFetchingCampaigns.value &&
    WhatsAppCampaigns.value?.length > 0 &&
    filteredCampaigns.value.length === 0
);

watch([searchQuery, statusFilter, inboxId, itemsPerPage], () => {
  currentPage.value = 1;
});

const openCreateDialog = () => {
  editingCampaign.value = null;
  whatsAppCampaignDialogRef.value?.dialogRef.open();
};

const handleEdit = campaign => {
  editingCampaign.value = campaign;
  whatsAppCampaignDialogRef.value?.dialogRef.open();
};

const handleDelete = campaign => {
  selectedCampaign.value = campaign;
  confirmDeleteCampaignDialogRef.value.dialogRef.open();
};

const goToAnalytics = campaign => {
  detailPanelRef.value?.close();
  router.push({
    name: 'campaigns_whatsapp_analytics',
    params: { campaignId: campaign.id },
  });
};

const handleShowDetail = campaign => {
  detailCampaign.value = campaign;
  detailPanelRef.value?.open();
};

const handleSelect = campaign => {
  if (
    campaign.campaign_status === 'draft' ||
    campaign.campaign_status === 'active'
  ) {
    handleEdit(campaign);
    return;
  }
  handleShowDetail(campaign);
};

const handleCloseDialog = () => {
  editingCampaign.value = null;
};

const handlePageChange = page => {
  currentPage.value = page;
};

const clearFilters = () => {
  searchQuery.value = '';
  statusFilter.value = 'all';
  inboxId.value = null;
};
</script>

<template>
  <CampaignLayout
    full-width
    :header-title="t('CAMPAIGN.WHATSAPP.HEADER_TITLE')"
    :button-label="t('CAMPAIGN.WHATSAPP.NEW_CAMPAIGN')"
    @click="openCreateDialog"
  >
    <WhatsAppCampaignAttributionNotice class="mb-4" />

    <div
      v-if="isFetchingCampaigns"
      class="flex items-center justify-center py-10 text-n-slate-11"
    >
      <Spinner />
    </div>

    <template v-else-if="!hasNoWhatsAppCampaigns">
      <div class="hidden md:flex flex-col gap-4">
        <WhatsAppCampaignsFilterBar
          v-model:search-query="searchQuery"
          v-model:status-filter="statusFilter"
          v-model:inbox-id="inboxId"
          :campaigns="sortedCampaigns"
          :inboxes="whatsappInboxes"
          :filtered-count="filteredCampaigns.length"
          :has-active-filters="hasActiveFilters"
          @clear-filters="clearFilters"
        />

        <WhatsAppCampaignsTable
          :campaigns="paginatedCampaigns"
          :empty-message="
            showFilteredEmpty ? t('CAMPAIGN.WHATSAPP.LIST.EMPTY_FILTER') : ''
          "
          @show-detail="handleShowDetail"
          @edit="handleEdit"
          @delete="handleDelete"
          @analytics="goToAnalytics"
        />

        <footer
          v-if="filteredCampaigns.length > 0"
          class="sticky bottom-0 z-10 -mx-6 px-6 border-t border-n-weak bg-n-surface-1"
        >
          <PaginationFooter
            :current-page="currentPage"
            :total-items="filteredCampaigns.length"
            :items-per-page="itemsPerPage"
            :per-page-options="PER_PAGE_OPTIONS"
            current-page-info="CAMPAIGN.WHATSAPP.LIST.PAGE_INFO"
            class="!px-0 before:hidden"
            @update:current-page="handlePageChange"
            @update:items-per-page="itemsPerPage = $event"
          />
        </footer>
      </div>

      <div class="flex flex-col gap-4 md:hidden">
        <WhatsAppCampaignsFilterBar
          v-model:search-query="searchQuery"
          v-model:status-filter="statusFilter"
          v-model:inbox-id="inboxId"
          :campaigns="sortedCampaigns"
          :inboxes="whatsappInboxes"
          :filtered-count="filteredCampaigns.length"
          :has-active-filters="hasActiveFilters"
          @clear-filters="clearFilters"
        />
        <CampaignList
          v-if="filteredCampaigns.length > 0"
          :campaigns="paginatedCampaigns"
          clickable-cards
          @edit="handleEdit"
          @delete="handleDelete"
          @select="handleSelect"
          @analytics="goToAnalytics"
        />
        <p v-else class="py-10 text-center text-body-main text-n-slate-11">
          {{ t('CAMPAIGN.WHATSAPP.LIST.EMPTY_FILTER') }}
        </p>
        <footer
          v-if="filteredCampaigns.length > 0"
          class="border-t border-n-weak pt-2"
        >
          <PaginationFooter
            :current-page="currentPage"
            :total-items="filteredCampaigns.length"
            :items-per-page="itemsPerPage"
            :per-page-options="PER_PAGE_OPTIONS"
            current-page-info="CAMPAIGN.WHATSAPP.LIST.PAGE_INFO"
            class="!bg-transparent !px-0 before:hidden"
            @update:current-page="handlePageChange"
            @update:items-per-page="itemsPerPage = $event"
          />
        </footer>
      </div>
    </template>

    <WhatsAppCampaignEmptyState
      v-else
      :title="t('CAMPAIGN.WHATSAPP.EMPTY_STATE.TITLE')"
      :subtitle="t('CAMPAIGN.WHATSAPP.EMPTY_STATE.SUBTITLE')"
      class="pt-14"
    />

    <ConfirmDeleteCampaignDialog
      ref="confirmDeleteCampaignDialogRef"
      :selected-campaign="selectedCampaign"
    />
  </CampaignLayout>

  <WhatsAppCampaignDialog
    ref="whatsAppCampaignDialogRef"
    :selected-campaign="editingCampaign"
    @close="handleCloseDialog"
  />

  <WhatsAppCampaignDetailPanel
    ref="detailPanelRef"
    :campaign="detailCampaign"
    @analytics="goToAnalytics"
  />
</template>
