<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useAlert, useTrack } from 'dashboard/composables';
import { CAMPAIGN_TYPES } from 'shared/constants/campaign.js';
import { CAMPAIGNS_EVENTS } from 'dashboard/helper/AnalyticsHelper/events.js';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import BroadcastForm from 'dashboard/components-next/Campaigns/Pages/CampaignPage/Broadcast/BroadcastForm.vue';

const props = defineProps({
  mode: {
    type: String,
    default: 'create',
    validator: value => ['edit', 'create'].includes(value),
  },
  selectedCampaign: {
    type: Object,
    default: null,
  },
});

const { t } = useI18n();
const store = useStore();

const dialogRef = ref(null);
const broadcastFormRef = ref(null);

const uiFlags = useMapGetter('campaigns/getUIFlags');

const isEditMode = computed(() => props.mode === 'edit');
const isSaving = computed(() =>
  isEditMode.value ? uiFlags.value.isUpdating : uiFlags.value.isCreating
);
const isInvalidForm = computed(() => broadcastFormRef.value?.isSubmitDisabled);

const handleSubmit = async () => {
  const campaignDetails = broadcastFormRef.value.prepareCampaignDetails();

  try {
    if (isEditMode.value) {
      await store.dispatch('campaigns/update', {
        id: props.selectedCampaign.id,
        ...campaignDetails,
      });
      useAlert(t('CAMPAIGN.BROADCAST.FORM.API.UPDATE_SUCCESS_MESSAGE'));
    } else {
      await store.dispatch('campaigns/create', campaignDetails);
      // tracking this here instead of the store to track the type of campaign
      useTrack(CAMPAIGNS_EVENTS.CREATE_CAMPAIGN, {
        type: CAMPAIGN_TYPES.ONE_OFF,
      });
      useAlert(t('CAMPAIGN.BROADCAST.FORM.API.SUCCESS_MESSAGE'));
    }

    dialogRef.value.close();
  } catch (error) {
    useAlert(
      error?.response?.message || t('CAMPAIGN.BROADCAST.FORM.API.ERROR_MESSAGE')
    );
  }
};

defineExpose({ dialogRef });
</script>

<template>
  <Dialog
    ref="dialogRef"
    type="edit"
    width="xl"
    position="top"
    overflow-y-auto
    :title="
      isEditMode
        ? t('CAMPAIGN.BROADCAST.EDIT.TITLE')
        : t('CAMPAIGN.BROADCAST.CREATE.TITLE')
    "
    :confirm-button-label="
      isEditMode
        ? t('CAMPAIGN.BROADCAST.FORM.BUTTONS.SAVE')
        : t('CAMPAIGN.BROADCAST.FORM.BUTTONS.SUBMIT')
    "
    :is-loading="isSaving"
    :disable-confirm-button="isSaving || isInvalidForm"
    @confirm="handleSubmit"
  >
    <BroadcastForm
      ref="broadcastFormRef"
      :mode="mode"
      :selected-campaign="selectedCampaign"
    />
  </Dialog>
</template>
