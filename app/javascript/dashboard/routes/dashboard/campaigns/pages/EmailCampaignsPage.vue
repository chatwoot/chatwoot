<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToggle } from '@vueuse/core';
import {
  useStore,
  useStoreGetters,
  useMapGetter,
} from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';

import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import CampaignLayout from 'dashboard/components-next/Campaigns/CampaignLayout.vue';
import CampaignCard from 'dashboard/components-next/Campaigns/CampaignCard/CampaignCard.vue';
import EmailCampaignDialog from 'dashboard/components-next/Campaigns/Pages/CampaignPage/EmailCampaign/EmailCampaignDialog.vue';
import ConfirmDeleteCampaignDialog from 'dashboard/components-next/Campaigns/Pages/CampaignPage/ConfirmDeleteCampaignDialog.vue';
import CampaignEmptyState from 'dashboard/components-next/Campaigns/EmptyState/EmailCampaignEmptyState.vue';

const { t } = useI18n();
const getters = useStoreGetters();
const store = useStore();

const selectedCampaign = ref(null);
const [showEmailCampaignDialog, toggleEmailCampaignDialog] = useToggle();

const uiFlags = useMapGetter('campaigns/getUIFlags');
const isFetchingCampaigns = computed(() => uiFlags.value.isFetching);

const confirmDeleteCampaignDialogRef = ref(null);

const emailCampaigns = computed(
  () => getters['campaigns/getEmailCampaigns'].value
);

const hasNoEmailCampaigns = computed(
  () => emailCampaigns.value?.length === 0 && !isFetchingCampaigns.value
);

const handleDelete = campaign => {
  selectedCampaign.value = campaign;
  confirmDeleteCampaignDialogRef.value.dialogRef.open();
};

const handleSend = async campaign => {
  try {
    await store.dispatch('campaigns/trigger', campaign.id);
    useAlert(t('CAMPAIGN.EMAIL.LIST.SEND_SUCCESS'));
  } catch (error) {
    useAlert(error?.response?.message || t('CAMPAIGN.EMAIL.LIST.SEND_ERROR'));
  }
};
</script>

<template>
  <CampaignLayout
    :header-title="t('CAMPAIGN.EMAIL.HEADER_TITLE')"
    :button-label="t('CAMPAIGN.EMAIL.NEW_CAMPAIGN')"
    @click="toggleEmailCampaignDialog()"
    @close="toggleEmailCampaignDialog(false)"
  >
    <template #action>
      <EmailCampaignDialog
        v-if="showEmailCampaignDialog"
        @close="toggleEmailCampaignDialog(false)"
      />
    </template>
    <div
      v-if="isFetchingCampaigns"
      class="flex items-center justify-center py-10 text-n-slate-11"
    >
      <Spinner />
    </div>
    <div v-else-if="!hasNoEmailCampaigns" class="flex flex-col gap-4">
      <CampaignCard
        v-for="campaign in emailCampaigns"
        :key="campaign.id"
        :title="campaign.title"
        :message="campaign.message"
        :is-enabled="campaign.enabled"
        :status="campaign.campaign_status"
        :sender="campaign.sender"
        :inbox="campaign.inbox"
        :scheduled-at="campaign.scheduled_at"
      >
        <template #actions>
          <Button
            variant="ghost"
            color="slate"
            size="sm"
            :label="t('CAMPAIGN.EMAIL.LIST.SEND')"
            :disabled="
              campaign.campaign_status === 'processing' ||
              campaign.campaign_status === 'completed'
            "
            @click="handleSend(campaign)"
          />
          <Button
            variant="ghost"
            color="rose"
            size="sm"
            :label="t('CAMPAIGN.EMAIL.LIST.DELETE')"
            @click="handleDelete(campaign)"
          />
        </template>
      </CampaignCard>
    </div>
    <div v-else class="pt-14">
      <CampaignEmptyState
        :title="t('CAMPAIGN.EMAIL.EMPTY_STATE.TITLE')"
        :subtitle="t('CAMPAIGN.EMAIL.EMPTY_STATE.SUBTITLE')"
      />
    </div>
    <ConfirmDeleteCampaignDialog
      ref="confirmDeleteCampaignDialogRef"
      :selected-campaign="selectedCampaign"
    />
  </CampaignLayout>
</template>
