<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import { getInboxIconByType } from 'dashboard/helper/inbox';

import CardLayout from 'dashboard/components-next/CardLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import LiveChatCampaignDetails from './LiveChatCampaignDetails.vue';
import SMSCampaignDetails from './SMSCampaignDetails.vue';

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
  deliveryReport: {
    type: Object,
    default: null,
  },
});

const emit = defineEmits(['edit', 'delete', 'view']);

const { t } = useI18n();

const STATUS_COMPLETED = 'completed';
const DELIVERY_STATUS_COMPLETED_WITH_ERRORS = 'completed_with_errors';

const { formatMessage } = useMessageFormatter();

const hasDeliveryErrors = computed(
  () => props.deliveryReport?.status === DELIVERY_STATUS_COMPLETED_WITH_ERRORS
);

const isActive = computed(() =>
  props.isLiveChatType ? props.isEnabled : props.status !== STATUS_COMPLETED
);

const statusTextColor = computed(() => {
  if (hasDeliveryErrors.value) {
    return 'text-n-ruby-11';
  }
  return {
    'text-n-teal-11': isActive.value,
    'text-n-slate-12': !isActive.value,
  };
});

const campaignStatus = computed(() => {
  if (props.isLiveChatType) {
    return props.isEnabled
      ? t('CAMPAIGN.LIVE_CHAT.CARD.STATUS.ENABLED')
      : t('CAMPAIGN.LIVE_CHAT.CARD.STATUS.DISABLED');
  }

  // Check delivery report status first
  if (hasDeliveryErrors.value) {
    return t('CAMPAIGN.SMS.CARD.STATUS.COMPLETED_WITH_ERRORS');
  }

  return props.status === STATUS_COMPLETED
    ? t('CAMPAIGN.SMS.CARD.STATUS.COMPLETED')
    : t('CAMPAIGN.SMS.CARD.STATUS.SCHEDULED');
});

const failedCount = computed(() => {
  if (!hasDeliveryErrors.value || !props.deliveryReport?.failed) {
    return null;
  }
  return t('CAMPAIGN.SMS.CARD.FAILED_COUNT', {
    count: props.deliveryReport.failed,
  });
});

const hasDeliveryReport = computed(() => !!props.deliveryReport);

const inboxName = computed(() => props.inbox?.name || '');

const inboxIcon = computed(() => {
  const { medium, channel_type: type } = props.inbox;
  return getInboxIconByType(type, medium);
});

const handleCardClick = () => {
  if (hasDeliveryReport.value) {
    emit('view');
  }
};
</script>

<template>
  <CardLayout
    layout="row"
    :class="{ 'cursor-pointer hover:bg-n-alpha-2': hasDeliveryReport }"
    @click="handleCardClick"
  >
    <div class="flex flex-col items-start justify-between flex-1 min-w-0 gap-2">
      <div class="flex justify-between gap-3 w-fit">
        <span
          class="text-base font-medium capitalize text-n-slate-12 line-clamp-1"
        >
          {{ title }}
        </span>
        <div class="flex items-center gap-2">
          <span
            class="text-xs font-medium inline-flex items-center h-6 px-2 py-0.5 rounded-md bg-n-alpha-2"
            :class="statusTextColor"
          >
            {{ campaignStatus }}
          </span>
          <span
            v-if="failedCount"
            class="text-xs font-medium inline-flex items-center h-6 px-2 py-0.5 rounded-md bg-n-ruby-3 text-n-ruby-11"
          >
            {{ failedCount }}
          </span>
        </div>
      </div>
      <div
        v-dompurify-html="formatMessage(message, false, false, false)"
        class="text-sm text-n-slate-11 line-clamp-1 [&>p]:mb-0 h-6"
      />
      <div class="flex items-center w-full h-6 gap-2 overflow-hidden">
        <LiveChatCampaignDetails
          v-if="isLiveChatType"
          :sender="sender"
          :inbox-name="inboxName"
          :inbox-icon="inboxIcon"
        />
        <SMSCampaignDetails
          v-else
          :inbox-name="inboxName"
          :inbox-icon="inboxIcon"
          :scheduled-at="scheduledAt"
        />
      </div>
    </div>
    <div class="flex items-center justify-end gap-2">
      <Button
        v-if="hasDeliveryReport"
        variant="faded"
        size="sm"
        color="slate"
        icon="i-lucide-bar-chart-2"
        @click.stop="emit('view')"
      />
      <Button
        v-if="isLiveChatType"
        variant="faded"
        size="sm"
        color="slate"
        icon="i-lucide-sliders-vertical"
        @click.stop="emit('edit')"
      />
      <Button
        variant="faded"
        color="ruby"
        size="sm"
        icon="i-lucide-trash"
        @click.stop="emit('delete')"
      />
    </div>
  </CardLayout>
</template>
