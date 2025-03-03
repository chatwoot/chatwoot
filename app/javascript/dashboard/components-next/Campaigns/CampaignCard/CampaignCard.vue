<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import { getInboxIconByType } from 'dashboard/helper/inbox';

import CardLayout from 'dashboard/components-next/CardLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import LiveChatCampaignDetails from './LiveChatCampaignDetails.vue';
import SMSCampaignDetails from './SMSCampaignDetails.vue';
import WhatsappCampaignDetails from './WhatsappCampaignDetails.vue';
const props = defineProps({
  title: {
    type: String,
    default: '',
  },
  message: {
    type: String,
    default: '',
  },
  campaignType: {
    type: String,
    default: 'whatsapp',
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
    type: [Number, String],
    default: 0,
  },
});

const emit = defineEmits(['edit', 'delete', 'report']);

const { t } = useI18n();

const STATUS_COMPLETED = 'completed';

const { formatMessage } = useMessageFormatter();

const isActive = computed(() =>
  props.campaignType === 'liveChat' || props.campaignType === 'whatsapp'
    ? props.isEnabled
    : props.status !== STATUS_COMPLETED
);

const statusTextColor = computed(() => ({
  'text-n-teal-11': isActive.value,
  'text-n-slate-12': !isActive.value,
}));

const campaignStatus = computed(() => {
  if (props.campaignType === 'liveChat') {
    return props.isEnabled
      ? t('CAMPAIGN.LIVE_CHAT.CARD.STATUS.ENABLED')
      : t('CAMPAIGN.LIVE_CHAT.CARD.STATUS.DISABLED');
  }

  return props.status === STATUS_COMPLETED
    ? t('CAMPAIGN.SMS.CARD.STATUS.COMPLETED')
    : t('CAMPAIGN.SMS.CARD.STATUS.SCHEDULED');
});

const inboxName = computed(() => props.inbox?.name || '');

const scheduledTime = computed(() => {
  const utcDate = new Date(props.scheduledAt);
  const istDate = utcDate.toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' });
  return istDate;
});

const inboxIcon = computed(() => {
  const { phone_number: phoneNumber, channel_type: type } = props.inbox;
  return getInboxIconByType(type, phoneNumber);
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
          class="text-xs font-medium inline-flex items-center h-6 px-2 py-0.5 rounded-md bg-n-alpha-2"
          :class="statusTextColor"
        >
          {{ campaignStatus }}
        </span>
      </div>
      <div
        v-dompurify-html="formatMessage(message || 'Hi this is rohit')"
        class="text-sm text-n-slate-11 line-clamp-1 [&>p]:mb-0 h-6"
      />
      <div class="flex items-center w-full h-6 gap-2 overflow-hidden">
        <LiveChatCampaignDetails
          v-if="campaignType === 'liveChat'"
          :sender="sender"
          :inbox-name="inboxName"
          :inbox-icon="inboxIcon"
        />
        <WhatsappCampaignDetails
          v-else-if="campaignType === 'whatsapp'"
          :inbox-name="inboxName"
          :inbox-icon="inboxIcon"
          :scheduled-at="scheduledTime"
        />
        <SMSCampaignDetails
          v-else
          :inbox-name="inboxName"
          :inbox-icon="inboxIcon"
          :scheduled-at="scheduledAt"
        />
      </div>
    </div>
    <div class="flex items-center justify-end w-50 gap-2">
      <Button
        v-if="campaignType === 'whatsapp'"
        variant="faded"
        size="sm"
        color="slate"
        icon="i-lucide-file-text"
        @click="emit('report')"
      />
      <Button
        v-if="
          campaignType === 'liveChat' ||
          (campaignType === 'whatsapp' && status !== 'completed')
        "
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
