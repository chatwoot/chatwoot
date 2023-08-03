<template>
  <div class="px-2 flex flex-row">
    <div class="w-2/3">
      <div v-if="isLoading" class="items-center flex text-base justify-center">
        <spinner />
        <span>{{ $t('CAMPAIGN.LIST.LOADING_MESSAGE') }}</span>
      </div>
      <empty-state v-if="showEmptyResult" :title="emptyMessage" />
      <div v-else>
        <div
          v-for="campaign in campaigns"
          :key="campaign.id"
          class="bg-white dark:bg-slate-800 mb-2 border border-slate-50 dark:border-slate-900 rounded-md px-5 py-4"
        >
          <div class="flex flex-row items-start justify-between">
            <div class="flex flex-col">
              <div class="text-base font-medium -mt-1">
                {{ campaign.title }}
              </div>
            </div>
            <div class="flex flex-row space-x-4">
              <woot-button
                variant="link"
                icon="edit"
                color-scheme="secondary"
                size="small"
                @click="$emit('on-edit-click', campaign)"
              >
                {{ $t('CAMPAIGN.LIST.BUTTONS.EDIT') }}
              </woot-button>
              <woot-button
                variant="link"
                icon="dismiss-circle"
                size="small"
                color-scheme="secondary"
                @click="$emit('on-delete-click', campaign)"
              >
                {{ $t('CAMPAIGN.LIST.BUTTONS.DELETE') }}
              </woot-button>
            </div>
          </div>

          <div
            v-dompurify-html="formatMessage(campaign.message)"
            class="text-sm line-clamp-2 [&>p]:mb-0"
          />
          <div class="flex flex-row mt-4 items-center space-x-3">
            <inbox-name :inbox="campaign.inbox" class="ltr:ml-0 rtl:mr-0" />
            <user-avatar-with-name
              v-if="campaign.sender"
              :user="campaign.sender"
            />
            <div class="text-xs text-woot-600  text-truncate w-1/4">
              {{ campaign.trigger_rules.url }}
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class="w-1/3 text-sm p-4">
      <div>
        Ongoing Campaigns allow the customer to send outbound messages in
        website live chat to their contacts which would trigger more
        conversations. You can create an ongoing campaign so that if a user
        visited a page and stayed for x minutes, you could send outbound
        message. This will help in more conversions. Step 1. Click on the
        Campaigns tab in the sidebar. You will see the list of campaigns that
        you have already added to the inbox. campaign Step 2. Click on the
        "Create a campaign" button., it will display a modal where you can input
        the campaign details. add-ongoing-campaign These are the inputs required
        to create the campaign: Input Description Title Campaign name Message
        Message to be sent in a campaign Sent by Agent details URL URL which
        campaigns work Time on page Time to wait until the campaign should be
        displayed (Seconds) Enable campaign The flag which shows whether the
        campaign is enabled or not The URLs in the campaign supports the
        wildcard patterns. See this guide to learn more about building a
        wildcard pattern.
      </div>
    </div>
  </div>
</template>

<script>
import { mixin as clickaway } from 'vue-clickaway';
import Spinner from 'shared/components/Spinner.vue';
import Label from 'dashboard/components/ui/Label';
import EmptyState from 'dashboard/components/widgets/EmptyState.vue';
import WootButton from 'dashboard/components/ui/WootButton.vue';
import messageFormatterMixin from 'shared/mixins/messageFormatterMixin';
import UserAvatarWithName from 'dashboard/components/widgets/UserAvatarWithName';
import campaignMixin from 'shared/mixins/campaignMixin';
import timeMixin from 'dashboard/mixins/time';
import rtlMixin from 'shared/mixins/rtlMixin';
import InboxName from 'dashboard/components/widgets/InboxName';

export default {
  components: {
    EmptyState,
    Spinner,
    UserAvatarWithName,
    InboxName,
  },

  mixins: [
    clickaway,
    timeMixin,
    campaignMixin,
    messageFormatterMixin,
    rtlMixin,
  ],

  props: {
    campaigns: {
      type: Array,
      default: () => [],
    },
    showEmptyResult: {
      type: Boolean,
      default: false,
    },
    isLoading: {
      type: Boolean,
      default: false,
    },
  },

  computed: {
    currentInboxId() {
      return this.$route.params.inboxId;
    },
    inbox() {
      return this.$store.getters['inboxes/getInbox'](this.currentInboxId);
    },
    inboxes() {
      if (this.isOngoingType) {
        return this.$store.getters['inboxes/getWebsiteInboxes'];
      }
      return this.$store.getters['inboxes/getTwilioInboxes'];
    },
    emptyMessage() {
      if (this.isOngoingType) {
        return this.inboxes.length
          ? this.$t('CAMPAIGN.ONGOING.404')
          : this.$t('CAMPAIGN.ONGOING.INBOXES_NOT_FOUND');
      }

      return this.inboxes.length
        ? this.$t('CAMPAIGN.ONE_OFF.404')
        : this.$t('CAMPAIGN.ONE_OFF.INBOXES_NOT_FOUND');
    },
    tableData() {
      if (this.isLoading) {
        return [];
      }
      return this.campaigns.map(item => {
        return {
          ...item,
          url: item.trigger_rules.url,
          timeOnPage: item.trigger_rules.time_on_page,
          scheduledAt: item.scheduled_at
            ? this.messageStamp(new Date(item.scheduled_at), 'LLL d, h:mm a')
            : '---',
        };
      });
    },
    columns() {
      const visibleToAllTable = [];
      if (this.isOngoingType) {
        return [
          ...visibleToAllTable,
          {
            field: 'enabled',
            key: 'enabled',
            title: this.$t('CAMPAIGN.LIST.TABLE_HEADER.STATUS'),
            align: this.isRTLView ? 'right' : 'left',
            renderBodyCell: ({ row }) => {
              const labelText = row.enabled
                ? this.$t('CAMPAIGN.LIST.STATUS.ENABLED')
                : this.$t('CAMPAIGN.LIST.STATUS.DISABLED');
              const colorScheme = row.enabled ? 'success' : 'secondary';
              return <Label title={labelText} colorScheme={colorScheme} />;
            },
          },
          {
            field: 'url',
            key: 'url',
            title: this.$t('CAMPAIGN.LIST.TABLE_HEADER.URL'),
            align: this.isRTLView ? 'right' : 'left',
            renderBodyCell: ({ row }) => (
              <div class="overflow-hidden whitespace-nowrap text-ellipsis">
                <a
                  target="_blank"
                  rel="noopener noreferrer nofollow"
                  href={row.url}
                  title={row.url}
                >
                  {row.url}
                </a>
              </div>
            ),
          },
          {
            field: 'timeOnPage',
            key: 'timeOnPage',
            title: this.$t('CAMPAIGN.LIST.TABLE_HEADER.TIME_ON_PAGE'),
            align: this.isRTLView ? 'right' : 'left',
          },
        ];
      }
      return [
        ...visibleToAllTable,
        {
          field: 'campaign_status',
          key: 'campaign_status',
          title: this.$t('CAMPAIGN.LIST.TABLE_HEADER.STATUS'),
          align: this.isRTLView ? 'right' : 'left',
          renderBodyCell: ({ row }) => {
            const labelText =
              row.campaign_status === 'completed'
                ? this.$t('CAMPAIGN.LIST.STATUS.COMPLETED')
                : this.$t('CAMPAIGN.LIST.STATUS.ACTIVE');
            const colorScheme =
              row.campaign_status === 'completed' ? 'secondary' : 'success';
            return <Label title={labelText} colorScheme={colorScheme} />;
          },
        },
        {
          field: 'scheduledAt',
          key: 'scheduledAt',
          title: this.$t('CAMPAIGN.LIST.TABLE_HEADER.SCHEDULED_AT'),
          align: this.isRTLView ? 'right' : 'left',
        },
        {
          field: 'buttons',
          key: 'buttons',
          title: '',
          align: this.isRTLView ? 'right' : 'left',
          renderBodyCell: row => (
            <div class="justify-evenly flex flex-row min-w-[12.5rem]">
              <WootButton
                variant="link"
                icon="dismiss-circle"
                color-scheme="secondary"
                onClick={() => this.$emit('on-delete-click', row)}
              >
                {this.$t('CAMPAIGN.LIST.BUTTONS.DELETE')}
              </WootButton>
            </div>
          ),
        },
      ];
    },
  },
};
</script>
