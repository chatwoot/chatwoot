<template>
  <div
    class="bg-white dark:bg-slate-800 mb-2 border border-slate-50 dark:border-slate-900 rounded-md px-5 py-4"
  >
    <div class="flex flex-row items-start justify-between">
      <div class="flex flex-col">
        <div class="text-base font-medium -mt-1 mb-1">
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

    <div class="flex flex-row mt-5 items-center space-x-3">
      <woot-label
        small
        :title="campaignStatus"
        :color-scheme="colorScheme"
        class="text-xs mr-3"
      />
      <inbox-name :inbox="campaign.inbox" class="ltr:ml-0 rtl:mr-0 mb-1" />
      <user-avatar-with-name
        v-if="campaign.sender"
        :user="campaign.sender"
        class="mb-1"
      />
      <div
        v-if="campaign.trigger_rules.url"
        class="text-xs text-woot-600 mb-1 text-truncate w-1/4"
      >
        {{ campaign.trigger_rules.url }}
      </div>
      <div
        v-if="campaign.scheduled_at"
        class="text-xs text-slate-700 dark:text-slate-500 mb-1"
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
import timeMixin from 'dashboard/mixins/time';

export default {
  components: {
    UserAvatarWithName,
    InboxName,
  },
  mixins: [messageFormatterMixin, timeMixin],
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
};
</script>
