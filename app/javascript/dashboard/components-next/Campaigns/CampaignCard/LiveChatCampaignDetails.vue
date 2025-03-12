<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  sender: {
    type: Object,
    default: null,
  },
  inboxName: {
    type: String,
    default: '',
  },
  inboxIcon: {
    type: String,
    default: '',
  },
});

const { t } = useI18n();

const senderName = computed(
  () => props.sender?.name || t('CAMPAIGN.LIVE_CHAT.CARD.CAMPAIGN_DETAILS.BOT')
);

const senderThumbnailSrc = computed(() => props.sender?.thumbnail);
</script>

<template>
  <span class="flex-shrink-0 text-sm text-n-slate-11 whitespace-nowrap">
    {{ t('CAMPAIGN.LIVE_CHAT.CARD.CAMPAIGN_DETAILS.SENT_BY') }}
  </span>
  <div class="flex items-center gap-1.5 flex-shrink-0">
    <Avatar
      :name="senderName"
      :src="senderThumbnailSrc"
      :size="16"
      rounded-full
    />
    <span class="text-sm font-medium text-n-slate-12">
      {{ senderName }}
    </span>
  </div>
  <span class="flex-shrink-0 text-sm text-n-slate-11 whitespace-nowrap">
    {{ t('CAMPAIGN.LIVE_CHAT.CARD.CAMPAIGN_DETAILS.FROM') }}
  </span>
  <div class="flex items-center gap-1.5 flex-shrink-0">
    <Icon :icon="inboxIcon" class="flex-shrink-0 text-n-slate-12 size-3" />
    <span class="text-sm font-medium text-n-slate-12">
      {{ inboxName }}
    </span>
  </div>
</template>
