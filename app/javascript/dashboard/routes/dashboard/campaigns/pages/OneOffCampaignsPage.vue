<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToggle } from '@vueuse/core';
import { useStoreGetters } from 'dashboard/composables/store';
import { CAMPAIGN_TYPES } from 'shared/constants/campaign.js';

import CampaignLayout from 'dashboard/components-next/Campaigns/CampaignLayout.vue';
import CampaignList from 'dashboard/components-next/Campaigns/Pages/CampaignPage/CampaignList.vue';
import OneOffCampaignDialog from 'dashboard/components-next/Campaigns/Pages/CampaignPage/OneOffCampaign/OneOffCampaignDialog.vue';

const { t } = useI18n();
const getters = useStoreGetters();

const [showOneOffCampaignDialog, toggleOneOffCampaignDialog] = useToggle();

const oneOffCampaigns = computed(() =>
  getters['campaigns/getCampaigns'].value(CAMPAIGN_TYPES.ONE_OFF)
);
</script>

<template>
  <CampaignLayout
    :header-title="t('CAMPAIGN.ONE_OFF_CAMPAIGNS_PAGE.HEADER_TITLE')"
    :button-label="t('CAMPAIGN.ONE_OFF_CAMPAIGNS_PAGE.NEW_CAMPAIGN')"
    @click="toggleOneOffCampaignDialog()"
    @close="toggleOneOffCampaignDialog(false)"
  >
    <template #action>
      <OneOffCampaignDialog
        v-if="showOneOffCampaignDialog"
        @close="toggleOneOffCampaignDialog(false)"
      />
    </template>
    <template #content>
      <CampaignList :campaigns="oneOffCampaigns" />
    </template>
  </CampaignLayout>
</template>
