<script setup>
import MarketingCampaignCard from './MarketingCampaignCard.vue';

defineProps({
  campaigns: {
    type: Array,
    required: true,
  },
});

const emit = defineEmits(['edit', 'delete']);

const handleEdit = campaign => emit('edit', campaign);
const handleDelete = campaign => emit('delete', campaign);
</script>

<template>
  <div class="flex flex-col gap-4">
    <MarketingCampaignCard
      v-for="campaign in campaigns"
      :key="campaign.id"
      :title="campaign.title"
      :description="campaign.description"
      :start-date="campaign.start_date"
      :end-date="campaign.end_date"
      :source-id="campaign.source_id"
      :active="campaign.active"
      @edit="handleEdit(campaign)"
      @delete="handleDelete(campaign)"
    />
  </div>
</template>
