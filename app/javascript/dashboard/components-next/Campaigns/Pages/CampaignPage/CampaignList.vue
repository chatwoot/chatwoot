<script setup>
import CampaignCard from 'dashboard/components-next/Campaigns/CampaignCard/CampaignCard.vue';
import { useStoreGetters } from 'dashboard/composables/store';
defineProps({
  campaigns: {
    type: Array,
    required: true,
  },
  campaignType: {
    type: String,
    default: 'whatsapp',
  },
});

const emit = defineEmits(['edit', 'delete', 'report']);
const getters = useStoreGetters();
const getInboxByCampaignId = inboxId =>
  getters['inboxes/getInbox'].value(inboxId);

const handleReport = campaign => emit('report', campaign);
const handleEdit = campaign => emit('edit', campaign);
const handleDelete = campaign => emit('delete', campaign);
</script>

<template>
  <div class="flex flex-col gap-4">
    <CampaignCard
      v-for="campaign in campaigns"
      :key="campaign.id"
      :title="campaign.title"
      :message="campaign.message"
      :is-enabled="campaign.enabled"
      :status="campaign.campaign_status"
      :sender="campaign.sender"
      :inbox="
        campaignType === 'whatsapp'
          ? getInboxByCampaignId(campaign.inbox_id)
          : campaign.inbox
      "
      :scheduled-at="campaign.scheduled_at"
      :campaign-type="campaignType"
      @report="handleReport(campaign)"
      @edit="handleEdit(campaign)"
      @delete="handleDelete(campaign)"
    />
  </div>
</template>
