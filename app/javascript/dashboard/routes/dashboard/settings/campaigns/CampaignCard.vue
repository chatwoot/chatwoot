<script setup>
import UserAvatarWithName from 'dashboard/components/widgets/UserAvatarWithName.vue';
import InboxName from 'dashboard/components/widgets/InboxName.vue';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import { messageStamp } from 'shared/helpers/timeHelper';
import { useI18n } from 'vue-i18n';
import { computed } from 'vue';

const props = defineProps({
  campaign: {
    type: Object,
    required: true,
  },
  isOngoingType: {
    type: Boolean,
    default: true,
  },
});

const emit = defineEmits(['edit', 'delete']);

const { t } = useI18n();

const { formatMessage } = useMessageFormatter();

const campaignStatus = computed(() => {
  if (props.isOngoingType) {
    return props.campaign.enabled
      ? t('CAMPAIGN.LIST.STATUS.ENABLED')
      : t('CAMPAIGN.LIST.STATUS.DISABLED');
  }

  return props.campaign.campaign_status === 'completed'
    ? t('CAMPAIGN.LIST.STATUS.COMPLETED')
    : t('CAMPAIGN.LIST.STATUS.ACTIVE');
});

const colorScheme = computed(() => {
  if (props.isOngoingType) {
    return props.campaign.enabled ? 'success' : 'secondary';
  }
  return props.campaign.campaign_status === 'completed'
    ? 'secondary'
    : 'success';
});

const campaignReport = computed(() => {
  const audience = props.campaign.audience;
  const reports = {
    total: 0,
  };
  // eslint-disable-next-line no-plusplus
  for (let i = 0; i < audience.length; i++) {
    const a = audience[i];
    if (!reports[a.status]) {
      reports[a.status] = 0;
    }
    reports.total += 1;
    reports[a.status] += 1;
  }
  return reports;
});
</script>

<template>
  <div
    class="px-5 py-4 mb-2 bg-white border rounded-md dark:bg-slate-800 border-slate-50 dark:border-slate-900"
  >
    <div class="flex flex-row items-start justify-between">
      <div class="flex flex-col">
        <div
          class="mb-1 -mt-1 text-base font-medium text-slate-900 dark:text-slate-100"
        >
          {{ campaign.title }}
        </div>
        <div
          v-dompurify-html="formatMessage(campaign.message)"
          class="text-sm line-clamp-1 [&>p]:mb-0"
        />
      </div>
      <div class="flex flex-row space-x-4">
        <woot-button
          v-if="isOngoingType"
          variant="link"
          icon="edit"
          color-scheme="secondary"
          size="small"
          @click="emit('edit', campaign)"
        >
          {{ $t('CAMPAIGN.LIST.BUTTONS.EDIT') }}
        </woot-button>
        <woot-button
          variant="link"
          icon="dismiss-circle"
          size="small"
          color-scheme="secondary"
          @click="emit('delete', campaign)"
        >
          {{ $t('CAMPAIGN.LIST.BUTTONS.DELETE') }}
        </woot-button>
      </div>
    </div>

    <div class="flex flex-row items-center mt-5 space-x-3">
      <woot-label
        small
        :title="campaignStatus"
        :color-scheme="colorScheme"
        class="mr-3 text-xs"
      />
      <InboxName :inbox="campaign.inbox" class="mb-1 ltr:ml-0 rtl:mr-0" />
      <UserAvatarWithName
        v-if="campaign.sender"
        :user="campaign.sender"
        class="mb-1"
      />
      <div
        v-if="campaign.trigger_rules.url"
        :title="campaign.trigger_rules.url"
        class="w-1/4 mb-1 text-xs text-woot-600 truncate"
      >
        {{ campaign.trigger_rules.url }}
      </div>
      <div
        v-if="campaign.scheduled_at"
        class="w-1/4 mb-1 text-xs text-slate-700 dark:text-slate-500"
      >
        {{ messageStamp(new Date(campaign.scheduled_at), 'LLL d, h:mm a') }}
      </div>
    </div>

    <div
      v-if="campaign.inbox.channel_type == 'Channel::Whatsapp'"
      class="flex flex-row items-center mt-5 space-x-3"
    >
      <div class="mb-1 text-xs text-slate-700 dark:text-slate-500">
        {{ $t('CAMPAIGN.AUDIENCE.REPORT') }}:
      </div>
      <div class="mb-1 text-xs text-slate-700 dark:text-slate-500">
        {{ campaignReport }}
      </div>
    </div>
  </div>
</template>
