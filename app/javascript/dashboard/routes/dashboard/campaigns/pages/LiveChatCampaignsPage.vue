<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToggle } from '@vueuse/core';
import { useStoreGetters, useMapGetter } from 'dashboard/composables/store';
import { CAMPAIGN_TYPES } from 'shared/constants/campaign.js';

import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import CampaignLayout from 'dashboard/components-next/Campaigns/CampaignLayout.vue';
import CampaignList from 'dashboard/components-next/Campaigns/Pages/CampaignPage/CampaignList.vue';
import LiveChatCampaignDialog from 'dashboard/components-next/Campaigns/Pages/CampaignPage/LiveChatCampaign/LiveChatCampaignDialog.vue';
import EditLiveChatCampaignDialog from 'dashboard/components-next/Campaigns/Pages/CampaignPage/LiveChatCampaign/EditLiveChatCampaignDialog.vue';
import ConfirmDeleteCampaignDialog from 'dashboard/components-next/Campaigns/Pages/CampaignPage/ConfirmDeleteCampaignDialog.vue';
import LiveChatCampaignEmptyState from 'dashboard/components-next/Campaigns/EmptyState/LiveChatCampaignEmptyState.vue';

const { t } = useI18n();
const getters = useStoreGetters();

const editLiveChatCampaignDialogRef = ref(null);
const confirmDeleteCampaignDialogRef = ref(null);
const selectedCampaign = ref(null);

const uiFlags = useMapGetter('campaigns/getUIFlags');
const isFetchingCampaigns = computed(() => uiFlags.value.isFetching);

const [showLiveChatCampaignDialog, toggleLiveChatCampaignDialog] = useToggle();

const liveChatCampaigns = computed(() =>
  getters['campaigns/getCampaigns'].value(CAMPAIGN_TYPES.ONGOING)
);

const hasNoLiveChatCampaigns = computed(
  () => liveChatCampaigns.value?.length === 0 && !isFetchingCampaigns.value
);

const handleEdit = campaign => {
  selectedCampaign.value = campaign;
  editLiveChatCampaignDialogRef.value.dialogRef.open();
};
const handleDelete = campaign => {
  selectedCampaign.value = campaign;
  confirmDeleteCampaignDialogRef.value.dialogRef.open();
};
</script>

<template>
  <CampaignLayout
    :header-title="t('CAMPAIGN.LIVE_CHAT.HEADER_TITLE')"
    :button-label="t('CAMPAIGN.LIVE_CHAT.NEW_CAMPAIGN')"
    @click="toggleLiveChatCampaignDialog()"
    @close="toggleLiveChatCampaignDialog(false)"
  >
    <template #action>
      <LiveChatCampaignDialog
        v-if="showLiveChatCampaignDialog"
        @close="toggleLiveChatCampaignDialog(false)"
      />
    </template>

    <div
      v-if="isFetchingCampaigns"
      class="flex items-center justify-center py-10 text-n-slate-11"
    >
      <Spinner />
    </div>
    <CampaignList
      v-else-if="!hasNoLiveChatCampaigns"
      :campaigns="liveChatCampaigns"
      is-live-chat-type
      @edit="handleEdit"
      @delete="handleDelete"
    />
    <LiveChatCampaignEmptyState
      v-else
      :title="t('CAMPAIGN.LIVE_CHAT.EMPTY_STATE.TITLE')"
      :subtitle="t('CAMPAIGN.LIVE_CHAT.EMPTY_STATE.SUBTITLE')"
      class="pt-14"
    />
    <EditLiveChatCampaignDialog
      ref="editLiveChatCampaignDialogRef"
      :selected-campaign="selectedCampaign"
    />
    <ConfirmDeleteCampaignDialog
      ref="confirmDeleteCampaignDialogRef"
      :selected-campaign="selectedCampaign"
    />
  </CampaignLayout>
</template>
