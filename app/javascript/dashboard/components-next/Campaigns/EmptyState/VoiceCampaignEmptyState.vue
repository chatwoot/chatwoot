<script setup>
import { VOICE_CAMPAIGN_EMPTY_STATE_CONTENT } from './CampaignEmptyStateContent';
import { useI18n } from 'vue-i18n';

import EmptyStateLayout from './CustomEmptyStateLayout.vue';
import CampaignCard from 'dashboard/components-next/Campaigns/CampaignCard/CampaignCard.vue';

defineProps({
  title: {
    type: String,
    default: '',
  },
  subtitle: {
    type: String,
    default: '',
  },
});

const { t } = useI18n();
</script>

<template>
  <EmptyStateLayout :title="title" :subtitle="subtitle">
    <template #empty-state-item>
      <div class="flex flex-col gap-4 p-px">
        <div 
          v-for="(campaign, index) in VOICE_CAMPAIGN_EMPTY_STATE_CONTENT" 
          :key="campaign.id"
          :style="{
            opacity: index === 0 ? 1 : index === 1 ? 0.7 : index === 2 ? 0.4 : 0.2
          }"
        >
          <CampaignCard
            :title="campaign.title"
            :message="campaign.message"
            :is-enabled="campaign.enabled"
            :status="campaign.campaign_status"
            :sender="campaign.sender"
            :inbox="campaign.inbox"
            :scheduled-at="campaign.scheduled_at"
            :is-voice-type="true"
          />
        </div>
      </div>
    </template>
    <template #actions>
      <div class="mt-10 py-5 px-8 rounded-lg bg-slate-800/5 border border-slate-300/10 max-w-[32rem] mx-auto text-center shadow-sm">
        <p class="mb-4 text-sm text-slate-700 dark:text-slate-300 font-medium">
          {{ t('CAMPAIGN.VOICE.EMPTY_STATE.JS_API_DESCRIPTION') }}
        </p>
        <code class="block px-5 py-4 overflow-auto text-xs rounded bg-slate-800 text-slate-200 text-left">
          chatwoot.triggerVoiceCampaign({
            campaignId: 'CAMPAIGN_ID',
            user: {
              name: 'John Doe', 
              phone: '+1234567890'
            }
          });
        </code>
      </div>
    </template>
  </EmptyStateLayout>
</template>