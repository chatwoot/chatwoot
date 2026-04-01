<script setup>
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { messageStamp } from 'shared/helpers/timeHelper';

import { useI18n } from 'vue-i18n';
defineProps({
  inboxName: {
    type: String,
    default: '',
  },
  inboxIcon: {
    type: String,
    default: '',
  },
  scheduledAt: {
    type: Number,
    default: 0,
  },
});

const { t } = useI18n();
</script>

<template>
  <span class="flex-shrink-0 whitespace-nowrap text-sm text-on-surface-variant">
    {{ t('CAMPAIGN.SMS.CARD.CAMPAIGN_DETAILS.SENT_FROM') }}
  </span>
  <div class="flex items-center gap-1.5 flex-shrink-0">
    <Icon :icon="inboxIcon" class="size-3 flex-shrink-0 text-on-surface" />
    <span class="text-sm font-medium text-on-surface">
      {{ inboxName }}
    </span>
  </div>

  <span class="flex-shrink-0 whitespace-nowrap text-sm text-on-surface-variant">
    {{ t('CAMPAIGN.SMS.CARD.CAMPAIGN_DETAILS.ON') }}
  </span>
  <span class="flex-1 truncate text-sm font-medium text-on-surface">
    {{ messageStamp(new Date(scheduledAt), 'LLL d, h:mm a') }}
  </span>
</template>
