<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import { getInboxIconByType } from 'dashboard/helper/inbox';
import {
  BROADCAST_CHANNELS,
  getBroadcastChannel,
} from 'dashboard/helper/campaignHelper';

import CardLayout from 'dashboard/components-next/CardLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ProactiveCampaignDetails from './ProactiveCampaignDetails.vue';
import BroadcastCampaignDetails from './BroadcastCampaignDetails.vue';

const props = defineProps({
  title: {
    type: String,
    default: '',
  },
  message: {
    type: String,
    default: '',
  },
  isLiveChatType: {
    type: Boolean,
    default: false,
  },
  isEnabled: {
    type: Boolean,
    default: false,
  },
  status: {
    type: String,
    default: '',
  },
  sender: {
    type: Object,
    default: null,
  },
  inbox: {
    type: Object,
    default: null,
  },
  scheduledAt: {
    type: Number,
    default: 0,
  },
});

const emit = defineEmits(['edit', 'delete']);

const { t } = useI18n();

const STATUS_COMPLETED = 'completed';
const STATUS_PROCESSING = 'processing';

const { formatMessage } = useMessageFormatter();

const isScheduled = computed(
  () =>
    props.status !== STATUS_COMPLETED &&
    props.status !== STATUS_PROCESSING &&
    props.scheduledAt * 1000 > Date.now()
);

const statusChipClass = computed(() => {
  if (props.isLiveChatType) {
    return props.isEnabled
      ? 'text-n-teal-11 bg-n-alpha-2'
      : 'text-n-slate-12 bg-n-alpha-2';
  }

  if (props.status === STATUS_COMPLETED) return 'text-n-teal-11 bg-n-teal-2';
  if (props.status === STATUS_PROCESSING) return 'text-n-blue-11 bg-n-blue-2';

  return 'text-n-amber-11 bg-n-amber-2';
});

const campaignStatus = computed(() => {
  if (props.isLiveChatType) {
    return props.isEnabled
      ? t('CAMPAIGN.PROACTIVE.CARD.STATUS.ENABLED')
      : t('CAMPAIGN.PROACTIVE.CARD.STATUS.DISABLED');
  }

  if (props.status === STATUS_COMPLETED) {
    return t('CAMPAIGN.BROADCAST.CARD.STATUS.COMPLETED');
  }

  if (props.status === STATUS_PROCESSING) {
    return t('CAMPAIGN.BROADCAST.CARD.STATUS.PROCESSING');
  }

  return t('CAMPAIGN.BROADCAST.CARD.STATUS.SCHEDULED');
});

const channelLabel = computed(() =>
  getBroadcastChannel(props.inbox) === BROADCAST_CHANNELS.WHATSAPP
    ? t('CAMPAIGN.CHANNEL.WHATSAPP')
    : t('CAMPAIGN.CHANNEL.SMS')
);

// Broadcasts can only be edited while they are still waiting to be sent.
const isEditable = computed(() => props.isLiveChatType || isScheduled.value);

const inboxName = computed(() => props.inbox?.name || '');

const inboxIcon = computed(() => {
  const {
    medium,
    channel_type: type,
    voice_enabled: voiceEnabled,
  } = props.inbox;
  return getInboxIconByType(type, medium, 'fill', voiceEnabled);
});
</script>

<template>
  <CardLayout layout="row">
    <div class="flex flex-col items-start justify-between flex-1 min-w-0 gap-2">
      <div class="flex justify-between gap-3 w-fit">
        <span
          class="text-base font-medium capitalize text-n-slate-12 line-clamp-1"
        >
          {{ title }}
        </span>
        <span
          v-if="!isLiveChatType"
          class="text-xs font-medium inline-flex items-center h-6 px-2 py-0.5 rounded-md bg-n-alpha-2 text-n-slate-11"
        >
          {{ channelLabel }}
        </span>
        <span
          class="text-xs font-medium inline-flex items-center h-6 px-2 py-0.5 rounded-md"
          :class="statusChipClass"
        >
          {{ campaignStatus }}
        </span>
      </div>
      <div
        v-dompurify-html="formatMessage(message, false, false, false)"
        class="text-sm text-n-slate-11 line-clamp-1 [&>p]:mb-0 h-6"
      />
      <div class="flex items-center w-full h-6 gap-2 overflow-hidden">
        <ProactiveCampaignDetails
          v-if="isLiveChatType"
          :sender="sender"
          :inbox-name="inboxName"
          :inbox-icon="inboxIcon"
        />
        <BroadcastCampaignDetails
          v-else
          :inbox-name="inboxName"
          :inbox-icon="inboxIcon"
          :scheduled-at="scheduledAt"
        />
      </div>
    </div>
    <div class="flex items-center justify-end w-20 gap-2">
      <Button
        v-if="isEditable"
        variant="faded"
        size="sm"
        color="slate"
        icon="i-lucide-sliders-vertical"
        @click="emit('edit')"
      />
      <Button
        variant="faded"
        color="ruby"
        size="sm"
        icon="i-lucide-trash"
        @click="emit('delete')"
      />
    </div>
  </CardLayout>
</template>
