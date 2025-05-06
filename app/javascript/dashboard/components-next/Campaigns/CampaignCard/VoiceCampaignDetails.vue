<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { getInboxIconByType } from 'dashboard/helper/inbox';

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
  campaign: {
    type: Object,
    default: () => ({}),
  },
});

const { t } = useI18n();

const senderName = computed(() => 
  props.sender?.name || t('CAMPAIGN.VOICE.CARD.CAMPAIGN_DETAILS.BOT')
);

const senderThumbnail = computed(() => props.sender?.thumbnail || '');
</script>

<template>
  <div class="flex items-center gap-2 w-full overflow-hidden">
    <span class="flex-shrink-0 text-sm text-n-slate-11 whitespace-nowrap">
      {{ t('CAMPAIGN.VOICE.CARD.CAMPAIGN_DETAILS.SENT_BY') }}
    </span>
    <div class="flex items-center gap-1.5 flex-shrink-0">
      <Avatar
        :name="senderName"
        :src="senderThumbnail"
        :size="16"
        rounded-full
      />
      <span class="text-sm font-medium text-n-slate-12">
        {{ senderName }}
      </span>
    </div>
    <span class="flex-shrink-0 text-sm text-n-slate-11 whitespace-nowrap">
      {{ t('CAMPAIGN.VOICE.CARD.CAMPAIGN_DETAILS.FROM') }}
    </span>
    <div class="flex items-center gap-1.5 flex-shrink-0">
      <Icon :icon="inboxIcon" class="flex-shrink-0 text-n-slate-12 size-3" />
      <span class="text-sm font-medium text-n-slate-12">
        {{ inboxName }}
      </span>
    </div>
  </div>
</template>