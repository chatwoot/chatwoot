<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import { messageStamp } from 'shared/helpers/timeHelper';
import { getInboxIconByType } from 'dashboard/helper/inbox';

import CardLayout from 'dashboard/components-next/CardLayout.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Thumbnail from 'dashboard/components-next/thumbnail/Thumbnail.vue';

const props = defineProps({
  title: {
    type: String,
    default: '',
  },
  message: {
    type: String,
    default: '',
  },
  isOngoingType: {
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
  triggerRules: {
    type: Object,
    default: null,
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

const { formatMessage } = useMessageFormatter();

const senderName = computed(
  () =>
    props.sender?.name ||
    t('CAMPAIGN.ONGOING_CAMPAIGNS_PAGE.CARD.CAMPAIGN_DETAILS.BOT')
);

const senderThumbnailSrc = computed(() => props.sender?.thumbnail);

const inboxName = computed(() => props.inbox?.name || '');

const inboxIcon = computed(() => {
  const { phone_number: phoneNumber, channel_type: type } = props.inbox;
  return getInboxIconByType(type, phoneNumber);
});

const triggerURL = computed(() => props.triggerRules?.url || '');

const statusTextColor = computed(() => ({
  'text-n-teal-11': props.isOngoingType
    ? props.isEnabled
    : props.status !== STATUS_COMPLETED,
  'text-n-slate-12': props.isOngoingType
    ? !props.isEnabled
    : props.status === STATUS_COMPLETED,
}));

const campaignStatus = computed(() => {
  if (props.isOngoingType) {
    return props.isEnabled
      ? t('CAMPAIGN.ONGOING_CAMPAIGNS_PAGE.CARD.STATUS.ENABLED')
      : t('CAMPAIGN.ONGOING_CAMPAIGNS_PAGE.CARD.STATUS.DISABLED');
  }

  return props.status === STATUS_COMPLETED
    ? t('CAMPAIGN.ONE_OFF_CAMPAIGNS_PAGE.CARD.STATUS.COMPLETED')
    : t('CAMPAIGN.ONE_OFF_CAMPAIGNS_PAGE.CARD.STATUS.ACTIVE');
});
</script>

<template>
  <CardLayout class="flex !flex-row justify-between flex-1 gap-8">
    <template #header>
      <div class="flex flex-col items-start w-[calc(100%-112px)] gap-2">
        <div class="flex justify-between h-6 gap-3 w-fit">
          <span class="text-base font-medium text-n-slate-12 line-clamp-1">
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
          v-dompurify-html="formatMessage(message)"
          class="text-sm text-n-slate-11 line-clamp-1 [&>p]:mb-0 h-6"
        />
        <div class="flex items-center w-full h-6 gap-2 overflow-hidden">
          <span
            v-if="isOngoingType"
            class="flex-shrink-0 text-sm text-n-slate-11 whitespace-nowrap"
          >
            {{
              t('CAMPAIGN.ONGOING_CAMPAIGNS_PAGE.CARD.CAMPAIGN_DETAILS.SENT_BY')
            }}
          </span>
          <div
            v-if="isOngoingType"
            class="flex items-center gap-1.5 flex-shrink-0"
          >
            <Thumbnail
              :author="sender || { name: senderName }"
              :name="senderName"
              :src="senderThumbnailSrc"
            />
            <span class="text-sm font-medium text-n-slate-12">
              {{ senderName }}
            </span>
          </div>
          <span
            v-if="isOngoingType"
            class="flex-shrink-0 text-sm text-n-slate-11 whitespace-nowrap"
          >
            {{
              t('CAMPAIGN.ONGOING_CAMPAIGNS_PAGE.CARD.CAMPAIGN_DETAILS.FROM')
            }}
          </span>
          <span
            v-else
            class="flex-shrink-0 text-sm text-n-slate-11 whitespace-nowrap"
          >
            {{
              t(
                'CAMPAIGN.ONE_OFF_CAMPAIGNS_PAGE.CARD.CAMPAIGN_DETAILS.SENT_FROM'
              )
            }}
          </span>
          <div class="flex items-center gap-1.5 flex-shrink-0">
            <Icon
              :icon="inboxIcon"
              class="flex-shrink-0 text-n-slate-12 size-3"
            />
            <span class="text-sm font-medium text-n-slate-12">
              {{ inboxName }}
            </span>
          </div>
          <span
            v-if="isOngoingType"
            class="flex-shrink-0 text-sm text-n-slate-11 whitespace-nowrap"
          >
            {{ t('CAMPAIGN.ONGOING_CAMPAIGNS_PAGE.CARD.CAMPAIGN_DETAILS.URL') }}
          </span>
          <span
            v-if="isOngoingType"
            class="flex-1 text-sm font-medium truncate text-n-blue-text"
          >
            {{ triggerURL }}
          </span>
          <span
            v-if="!isOngoingType"
            class="flex-shrink-0 text-sm text-n-slate-11 whitespace-nowrap"
          >
            {{ t('CAMPAIGN.ONE_OFF_CAMPAIGNS_PAGE.CARD.CAMPAIGN_DETAILS.ON') }}
          </span>
          <span
            v-if="!isOngoingType"
            class="flex-1 text-sm font-medium truncate text-n-slate-12"
          >
            {{ messageStamp(new Date(scheduledAt), 'LLL d, h:mm a') }}
          </span>
        </div>
      </div>
    </template>
    <template #footer>
      <div class="flex items-center justify-end w-20 gap-2">
        <Button
          v-if="isOngoingType"
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
    </template>
  </CardLayout>
</template>
