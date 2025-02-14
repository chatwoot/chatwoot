<script>
import UserAvatarWithName from 'dashboard/components/widgets/UserAvatarWithName.vue';
import InboxName from 'dashboard/components/widgets/InboxName.vue';
import messageFormatterMixin from 'shared/mixins/messageFormatterMixin';
import { messageStamp } from 'shared/helpers/timeHelper';
import CampaignReportModal from './CampaignReportModal.vue';

export default {
  components: {
    UserAvatarWithName,
    InboxName,
    CampaignReportModal,
  },
  mixins: [messageFormatterMixin],
  props: {
    campaign: {
      type: Object,
      required: true,
    },
    inbox: {
      type: Object,
      required: false, // Make this optional if it's not always passed
    },
    isOngoingType: {
      type: Boolean,
      default: true,
    },
  },
  data() {
    return {
      showReportModal: false, // Add state to control modal visibility
    };
  },

  computed: {
    failedContactsCount() {
      return this.campaign.failed_contacts_count ?? '1';
    },
    campaignStatus() {
      if (this.campaign.campaign_status === 'completed') {
        return this.$t('CAMPAIGN.LIST.STATUS.COMPLETED');
      }
      if (this.campaign.campaign_status === 'active') {
        return this.$t('CAMPAIGN.LIST.STATUS.ACTIVE');
      }

      // Then handle ongoing/whatsapp enabled/disabled status
      if (this.isOngoingType || this.isWhatsappType) {
        return this.campaign.enabled
          ? this.$t('CAMPAIGN.LIST.STATUS.ENABLED')
          : this.$t('CAMPAIGN.LIST.STATUS.DISABLED');
      }

      // For other campaigns, show active status
      return this.$t('CAMPAIGN.LIST.STATUS.ACTIVE');
    },
    isWhatsappType() {
      return this.campaign.campaign_type === 'whatsapp';
    },
    isCompleted() {
      return this.campaign.campaign_status === 'completed';
    },
    canShowReport() {
      // Only show report button for completed campaigns
      return (
        this.isCompleted &&
        (this.campaign.processed_contacts_count > 0 ||
          this.campaign.failed_contacts_count > 0)
      );
    },
    colorScheme() {
      if (this.isOngoingType || this.isWhatsappType) {
        return this.campaign.enabled ? 'success' : 'secondary';
      }
      return this.campaign.campaign_status === 'completed'
        ? 'secondary'
        : 'success';
    },
  },
  methods: {
    messageStamp,
    openReportModal() {
      this.showReportModal = true;
    },
    closeReportModal() {
      this.showReportModal = false;
    },
    handleReportError(error) {
      // Optional: Add error handling logic, e.g., showing a toast notification
    },
  },
};
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
      <div class="flex flex-row items-center">
        <div v-if="isWhatsappType" class="flex items-center space-x-8 mr-12">
          <div class="flex flex-col items-center">
            <span
              class="text-xl font-semibold text-slate-900 dark:text-slate-100"
            >
              {{
                campaign.processed_contacts_count !== null &&
                campaign.processed_contacts_count !== undefined
                  ? campaign.processed_contacts_count
                  : '_'
              }}
            </span>
            <span class="text-sm text-slate-600 dark:text-slate-400">
              {{ $t('CAMPAIGN.METRICS.SUCCESSFUL') }}
            </span>
          </div>

          <div class="flex flex-col items-center">
            <span
              class="text-xl font-semibold text-slate-900 dark:text-slate-100"
            >
              {{
                campaign.read_count !== null &&
                campaign.read_count !== undefined
                  ? campaign.read_count
                  : '_'
              }}
            </span>
            <span class="text-sm text-slate-600 dark:text-slate-400">
              {{ $t('CAMPAIGN.METRICS.READ') }}
            </span>
          </div>

          <div class="flex flex-col items-center">
            <span
              class="text-xl font-semibold text-slate-900 dark:text-slate-100"
            >
              {{
                failedContactsCount !== null &&
                failedContactsCount !== undefined
                  ? failedContactsCount
                  : '_'
              }}
            </span>
            <span class="text-sm text-slate-600 dark:text-slate-400">
              {{ $t('CAMPAIGN.METRICS.FAILED') }}
            </span>
          </div>
        </div>

        <!-- Action Buttons -->
        <div class="flex space-x-4">
          <woot-button
            v-if="isWhatsappType"
            variant="link"
            icon="document"
            color-scheme="secondary"
            size="small"
            class="ml-auto"
            @click="openReportModal"
          >
            {{ $t('CAMPAIGN.LIST.BUTTONS.SHOW_REPORT') }}
          </woot-button>
          <CampaignReportModal
            v-if="showReportModal"
            :campaign="campaign"
            @close="closeReportModal"
            @error="handleReportError"
          />
          <woot-button
            v-if="(isOngoingType || isWhatsappType) && !isCompleted"
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
    </div>

    <div class="flex flex-row items-center mt-5 space-x-3">
      <woot-label
        small
        :title="campaignStatus"
        :color-scheme="colorScheme"
        class="mr-3 text-xs"
      />
      <InboxName
        v-if="isWhatsappType"
        :inbox="inbox"
        class="mb-1 ltr:ml-0 rtl:mr-0"
      />
      <InboxName
        v-else
        :inbox="campaign.inbox"
        class="mb-1 ltr:ml-0 rtl:mr-0"
      />
      <UserAvatarWithName
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
        {{
          new Intl.DateTimeFormat('en-US', {
            year: 'numeric',
            month: 'short',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit',
            hour12: true,
          }).format(new Date(campaign.scheduled_at))
        }}
      </div>
    </div>
  </div>
</template>
