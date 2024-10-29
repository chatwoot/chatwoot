<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import { messageStamp } from 'shared/helpers/timeHelper';
import { getInboxClassByType } from 'dashboard/helper/inbox';

import CardLayout from 'dashboard/components-next/CardLayout.vue';
import FluentIcon from 'shared/components/FluentIcon/DashboardIcon.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Thumbnail from 'dashboard/components-next/thumbnail/Thumbnail.vue';

const props = defineProps({
  title: {
    type: String,
    required: true,
  },
  message: {
    type: String,
    required: true,
  },
  isOngoingType: {
    type: Boolean,
    default: false,
  },
  isEnabled: {
    type: Boolean,
    required: true,
  },
  status: {
    type: String,
    required: true,
  },
  triggerRules: {
    type: Object,
    required: true,
  },
  sender: {
    type: Object,
    required: true,
  },
  inbox: {
    type: Object,
    required: true,
  },
  scheduledAt: {
    type: Number,
    required: true,
  },
});

const { t } = useI18n();

const { formatMessage } = useMessageFormatter();

const senderName = computed(() => {
  return (
    props.sender?.name ||
    t('CAMPAIGN.ONGOING_CAMPAIGNS_PAGE.CARD.CAMPAIGN_DETAILS.BOT')
  );
});

const senderThumbnailSrc = computed(() => {
  return props.sender?.thumbnail;
});

const inboxName = computed(() => {
  return props.inbox?.name || '';
});

const inboxIcon = computed(() => {
  const { phone_number: phoneNumber, channel_type: type } = props.inbox;
  return getInboxClassByType(type, phoneNumber);
});

const triggerURL = computed(() => {
  return props.triggerRules?.url || '';
});

const statusTextColor = computed(() => {
  if (props.isOngoingType) {
    return props.isEnabled ? '!text-n-teal-11' : '!text-n-slate-12';
  }
  return props.status !== 'completed' ? '!text-n-teal-11' : '!text-n-slate-12';
});

const campaignStatus = computed(() => {
  if (props.isOngoingType) {
    return props.isEnabled
      ? t('CAMPAIGN.ONGOING_CAMPAIGNS_PAGE.CARD.STATUS.ENABLED')
      : t('CAMPAIGN.ONGOING_CAMPAIGNS_PAGE.CARD.STATUS.DISABLED');
  }

  return props.status === 'completed'
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
          <Button
            variant="ghost"
            size="sm"
            class="text-xs font-medium bg-n-alpha-2 hover:bg-n-alpha-1 !h-6 rounded-md border-0 !px-2 !py-0.5"
            :label="campaignStatus"
            :class="statusTextColor"
          />
        </div>
        <div
          v-dompurify-html="formatMessage(message)"
          class="text-sm text-n-slate-11 line-clamp-1 [&>p]:mb-0 h-6"
        />
        <div
          v-if="isOngoingType"
          class="flex items-center w-full h-6 gap-2 overflow-hidden"
        >
          <span class="flex-shrink-0 text-sm text-n-slate-11 whitespace-nowrap">
            {{
              t('CAMPAIGN.ONGOING_CAMPAIGNS_PAGE.CARD.CAMPAIGN_DETAILS.SENT_BY')
            }}
          </span>
          <div class="flex items-center gap-1.5 flex-shrink-0">
            <Thumbnail
              :author="sender || { name: senderName }"
              :name="senderName"
              :src="senderThumbnailSrc"
            />
            <span class="text-sm font-medium text-n-slate-12">
              {{ senderName }}
            </span>
          </div>
          <span class="flex-shrink-0 text-sm text-n-slate-11 whitespace-nowrap">
            {{
              t('CAMPAIGN.ONGOING_CAMPAIGNS_PAGE.CARD.CAMPAIGN_DETAILS.FROM')
            }}
          </span>
          <div class="flex items-center gap-1.5 flex-shrink-0">
            <FluentIcon :icon="inboxIcon" :size="12" class="text-n-slate-12" />
            <span class="text-sm font-medium text-n-slate-12">
              {{ inboxName }}
            </span>
          </div>
          <span class="flex-shrink-0 text-sm text-n-slate-11 whitespace-nowrap">
            {{ t('CAMPAIGN.ONGOING_CAMPAIGNS_PAGE.CARD.CAMPAIGN_DETAILS.URL') }}
          </span>
          <span class="flex-1 text-sm font-medium truncate text-n-blue">
            {{ triggerURL }}
          </span>
        </div>
        <div v-else class="flex items-center w-full h-6 gap-2 overflow-hidden">
          <span class="flex-shrink-0 text-sm text-n-slate-11 whitespace-nowrap">
            {{
              t(
                'CAMPAIGN.ONE_OFF_CAMPAIGNS_PAGE.CARD.CAMPAIGN_DETAILS.SENT_FROM'
              )
            }}
          </span>
          <div class="flex items-center gap-1.5 flex-shrink-0">
            <FluentIcon :icon="inboxIcon" :size="12" class="text-n-slate-12" />
            <span class="text-sm font-medium text-n-slate-12">
              {{ inboxName }}
            </span>
          </div>
          <span class="flex-shrink-0 text-sm text-n-slate-11 whitespace-nowrap">
            {{ t('CAMPAIGN.ONE_OFF_CAMPAIGNS_PAGE.CARD.CAMPAIGN_DETAILS.ON') }}
          </span>
          <span class="flex-1 text-sm font-medium truncate text-n-slate-12">
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
        />
        <Button variant="faded" color="ruby" size="sm" icon="i-lucide-trash" />
      </div>
    </template>
  </CardLayout>
</template>
