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
          @click="$emit('edit', campaign)"
        >
          {{ $t('CAMPAIGN.LIST.BUTTONS.EDIT') }}
        </woot-button>
        <woot-button
          variant="link"
          icon="dismiss-circle"
          size="small"
          color-scheme="secondary"
          @click="$emit('delete', campaign)"
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
      <inbox-name :inbox="campaign.inbox" class="mb-1 ltr:ml-0 rtl:mr-0" />
      <user-avatar-with-name
        v-if="campaign.sender"
        :user="campaign.sender"
        class="mb-1"
      />
      <div
        v-if="campaign.trigger_rules.url"
        class="w-1/4 mb-1 text-xs text-woot-600 text-truncate"
      >
        {{ campaign.trigger_rules.url }}
      </div>
      <div
        v-if="campaign.scheduled_at"
        class="mb-1 text-xs text-slate-700 dark:text-slate-500"
      >
        {{ messageStamp(new Date(campaign.scheduled_at), 'LLL d, h:mm a') }}
      </div>
    </div>
  </div>
</template>

<script>
import UserAvatarWithName from 'dashboard/components/widgets/UserAvatarWithName.vue';
import InboxName from 'dashboard/components/widgets/InboxName.vue';
import messageFormatterMixin from 'shared/mixins/messageFormatterMixin';
import { messageStamp } from 'shared/helpers/timeHelper';

export default {
  components: {
    UserAvatarWithName,
    InboxName,
  },
  mixins: [messageFormatterMixin],
  props: {
    campaign: {
      type: Object,
      required: true,
    },
    isOngoingType: {
      type: Boolean,
      default: true,
    },
  },

  computed: {
    campaignStatus() {
      if (this.isOngoingType) {
        return this.campaign.enabled
          ? this.$t('CAMPAIGN.LIST.STATUS.ENABLED')
          : this.$t('CAMPAIGN.LIST.STATUS.DISABLED');
      }

      return this.campaign.campaign_status === 'completed'
        ? this.$t('CAMPAIGN.LIST.STATUS.COMPLETED')
        : this.$t('CAMPAIGN.LIST.STATUS.ACTIVE');
    },
    colorScheme() {
      if (this.isOngoingType) {
        return this.campaign.enabled ? 'success' : 'secondary';
      }
      return this.campaign.campaign_status === 'completed'
        ? 'secondary'
        : 'success';
    },
  },
  methods: {
    messageStamp,
  },
};
</script>
