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
  <span class="flex-shrink-0 text-sm text-s-muted whitespace-nowrap">
    {{ t('CAMPAIGN.SMS.CARD.CAMPAIGN_DETAILS.SENT_FROM') }}
  </span>
  <div class="flex items-center gap-1.5 flex-shrink-0">
    <Icon :icon="inboxIcon" class="flex-shrink-0 text-s-primary size-3" />
    <span class="text-sm font-medium text-s-primary">
      {{ inboxName }}
    </span>
  </div>

  <span class="flex-shrink-0 text-sm text-s-muted whitespace-nowrap">
    {{ t('CAMPAIGN.SMS.CARD.CAMPAIGN_DETAILS.ON') }}
  </span>
  <span class="flex-1 text-sm font-medium truncate text-s-primary">
    {{ messageStamp(new Date(scheduledAt), 'LLL d, h:mm a') }}
  </span>
</template>
