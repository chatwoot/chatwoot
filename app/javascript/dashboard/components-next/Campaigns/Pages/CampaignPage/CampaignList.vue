<script setup>
import CampaignCard from 'dashboard/components-next/Campaigns/CampaignCard/CampaignCard.vue';

import { useConfig } from 'dashboard/composables/useConfig';

import { canShowWhatsAppCampaignAnalytics } from 'dashboard/helper/whatsappCampaignAnalytics';

defineProps({
  campaigns: {
    type: Array,

    required: true,
  },

  isLiveChatType: {
    type: Boolean,

    default: false,
  },

  clickableCards: {
    type: Boolean,

    default: false,
  },
});

const emit = defineEmits(['edit', 'delete', 'select', 'analytics']);

const { isEnterprise } = useConfig();

const handleEdit = campaign => emit('edit', campaign);

const handleDelete = campaign => emit('delete', campaign);

const handleSelect = campaign => emit('select', campaign);

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
      :execution-stats="campaign.execution_stats"
      :is-live-chat-type="isLiveChatType"
      :clickable="clickableCards"
      :show-analytics="canShowWhatsAppCampaignAnalytics(campaign, isEnterprise)"
      @edit="handleEdit(campaign)"
      @delete="handleDelete(campaign)"
      @select="handleSelect(campaign)"
      @analytics="handleAnalytics(campaign)"
    />
  </div>
</template>
