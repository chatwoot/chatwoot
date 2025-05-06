<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToggle } from '@vueuse/core';
import { useStoreGetters, useMapGetter } from 'dashboard/composables/store';
import { CAMPAIGN_TYPES } from 'shared/constants/campaign.js';

import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import CampaignLayout from 'dashboard/components-next/Campaigns/CampaignLayout.vue';
import CampaignList from 'dashboard/components-next/Campaigns/Pages/CampaignPage/CampaignList.vue';
import VoiceCampaignDialog from 'dashboard/components-next/Campaigns/Pages/CampaignPage/VoiceCampaign/VoiceCampaignDialog.vue';
import ConfirmDeleteCampaignDialog from 'dashboard/components-next/Campaigns/Pages/CampaignPage/ConfirmDeleteCampaignDialog.vue';
import VoiceCampaignEmptyState from 'dashboard/components-next/Campaigns/EmptyState/VoiceCampaignEmptyState.vue';

const { t } = useI18n();
const getters = useStoreGetters();

const selectedCampaign = ref(null);
const [showVoiceCampaignDialog, toggleVoiceCampaignDialog] = useToggle();

const uiFlags = useMapGetter('campaigns/getUIFlags');
const isFetchingCampaigns = computed(() => uiFlags.value.isFetching);

const confirmDeleteCampaignDialogRef = ref(null);

const voiceCampaigns = computed(() =>
  getters['campaigns/getCampaigns'].value(CAMPAIGN_TYPES.VOICE)
);

const hasNoVoiceCampaigns = computed(
  () => voiceCampaigns.value?.length === 0 && !isFetchingCampaigns.value
);

const handleDelete = campaign => {
  selectedCampaign.value = campaign;
  confirmDeleteCampaignDialogRef.value.dialogRef.open();
};
</script>

<template>
  <CampaignLayout
    :header-title="t('CAMPAIGN.VOICE.HEADER_TITLE')"
    :button-label="t('CAMPAIGN.VOICE.NEW_CAMPAIGN')"
    @click="toggleVoiceCampaignDialog()"
    @close="toggleVoiceCampaignDialog(false)"
  >
    <template #action>
      <VoiceCampaignDialog
        v-if="showVoiceCampaignDialog"
        @close="toggleVoiceCampaignDialog(false)"
      />
    </template>
    <div
      v-if="isFetchingCampaigns"
      class="flex items-center justify-center py-10 text-n-slate-11"
    >
      <Spinner />
    </div>
    <CampaignList
      v-else-if="!hasNoVoiceCampaigns"
      :campaigns="voiceCampaigns"
      :is-voice-type="true"
      @delete="handleDelete"
    />
    <VoiceCampaignEmptyState
      v-else
      :title="t('CAMPAIGN.VOICE.EMPTY_STATE.TITLE')"
      :subtitle="t('CAMPAIGN.VOICE.EMPTY_STATE.SUBTITLE')"
      class="pt-14"
    />
    <ConfirmDeleteCampaignDialog
      ref="confirmDeleteCampaignDialogRef"
      :selected-campaign="selectedCampaign"
    />
  </CampaignLayout>
</template>