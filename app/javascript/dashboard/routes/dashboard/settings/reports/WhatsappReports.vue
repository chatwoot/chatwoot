<script setup>
import ReportHeader from './components/ReportHeader.vue';
import WhatsappCampaigns from './components/Filters/WhatsappCampaigns.vue';
import WhatsappInboxes from './components/Filters/WhatsappInboxes.vue';
import WhatsappCampaignData from './components/WhatsappCampaignData.vue';
import { ref } from 'vue';

const selectedInbox = ref(null);
const handleInboxUpdate = inbox => {
  selectedInbox.value = inbox;
};

const selectedCampaign = ref(null);
const handleCampaignUpdate = campaign => {
  console.log("Changed campaign: ", campaign)
  selectedCampaign.value = campaign;
};
</script>
<template>
  <ReportHeader :header-title="$t('BOT_REPORTS.HEADER')" />
  <div class="flex flex-row gap-4 [&>*]:w-[200px]">
    <WhatsappInboxes
      @inbox-filter-selection="handleInboxUpdate"
    ></WhatsappInboxes>
    <WhatsappCampaigns
      v-if="selectedInbox !== null"
      :selected-inbox="selectedInbox"
      @campaign-filter-selection="handleCampaignUpdate"
    ></WhatsappCampaigns>
    <div class="flex-1"></div>
  </div>
  <WhatsappCampaignData
    v-if="selectedCampaign !== null"
    :campaign="selectedCampaign"
    :key="selectedCampaign.id"
  ></WhatsappCampaignData>
</template>
