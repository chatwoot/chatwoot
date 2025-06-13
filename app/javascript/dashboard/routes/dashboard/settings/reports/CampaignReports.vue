<script setup>
import ReportHeader from './components/ReportHeader.vue';
import V4Button from 'dashboard/components-next/button/Button.vue';
import ReportChannels from './components/Filters/ReportChannels.vue';
import ReportCampaigns from './components/Filters/ReportCampaigns.vue';
import ReportInboxes from './components/Filters/ReportInboxes.vue';
import WhatsappCampaignData from './components/WhatsappCampaignData.vue';
import { ref } from 'vue';
import EmptyCampaignReportState from './components/EmptyCampaignReportState.vue';
import { useStore } from 'vuex';

const store = useStore();

const selectedChannel = ref(null);
const selectedInbox = ref(null);
const selectedCampaign = ref(null);

const handleChannelUpdate = channel => {
  if (channel !== selectedChannel.value) {
    selectedChannel.value = channel;
    selectedInbox.value = null;
    selectedCampaign.value = null;
  }
};

const handleInboxUpdate = inbox => {
  if (inbox?.id !== selectedInbox?.value?.id) {
    selectedInbox.value = inbox;
    selectedCampaign.value = null;
  }
};

const handleCampaignUpdate = campaign => {
  selectedCampaign.value = campaign;
};

const downloadReports = () => {
  store.dispatch('downloadCampaignReports', {
    campaign_id: selectedCampaign.value.id,
    fileName: `campaign${selectedCampaign.value.id}_report.csv`,
  });
};
</script>

<template>
  <ReportHeader :header-title="$t('CAMPAIGN_REPORTS.HEADER')">
    <V4Button
      v-if="selectedCampaign !== null"
      :label="$t('CAMPAIGN_REPORTS.DOWNLOAD_REPORTS')"
      icon="i-ph-download-simple"
      size="sm"
      @click="downloadReports"
    />
  </ReportHeader>
  <div class="flex flex-row gap-4 [&>*]:w-[200px]">
    <ReportChannels @report-channel-selection="handleChannelUpdate" />
    <ReportInboxes
      v-if="selectedChannel !== null"
      :type="selectedChannel"
      @inbox-filter-selection="handleInboxUpdate"
    />
    <ReportCampaigns
      v-if="selectedInbox !== null"
      :selected-inbox="selectedInbox"
      :selected-channel="selectedChannel"
      @campaign-filter-selection="handleCampaignUpdate"
    />
    <div class="flex-1" />
  </div>
  <WhatsappCampaignData
    v-if="selectedCampaign !== null && selectedChannel == 'Channel::Whatsapp'"
    :key="selectedCampaign.id"
    :campaign="selectedCampaign"
  />
  <EmptyCampaignReportState v-else />
</template>
