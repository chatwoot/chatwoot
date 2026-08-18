<script setup>
import CampaignCard from 'dashboard/components-next/Campaigns/CampaignCard/CampaignCard.vue';
import { INBOX_TYPES } from 'dashboard/helper/inbox';
import { useConfig } from 'dashboard/composables/useConfig';

defineProps({
  campaigns: {
    type: Array,
    required: true,
  },
  isLiveChatType: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['edit', 'delete', 'analytics']);
const ANALYTICS_CAMPAIGN_STATUSES = ['processing', 'completed'];
const { isEnterprise } = useConfig();

const handleEdit = campaign => emit('edit', campaign);
const handleDelete = campaign => emit('delete', campaign);
const handleAnalytics = campaign => emit('analytics', campaign);
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
      :inbox="campaign.inbox"
      :scheduled-at="campaign.scheduled_at"
      :is-live-chat-type="isLiveChatType"
      :show-analytics="
        isEnterprise &&
        campaign.inbox?.channel_type === INBOX_TYPES.WHATSAPP &&
        ANALYTICS_CAMPAIGN_STATUSES.includes(campaign.campaign_status)
      "
      @edit="handleEdit(campaign)"
      @delete="handleDelete(campaign)"
      @analytics="handleAnalytics(campaign)"
    />
  </div>
</template>
