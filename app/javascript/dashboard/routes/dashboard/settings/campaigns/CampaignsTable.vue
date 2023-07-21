<template>
  <section class="campaigns-table-wrap">
    <empty-state v-if="showEmptyResult" :title="emptyMessage" />
    <ve-table
      v-else
      :columns="columns"
      scroll-width="190rem"
      :table-data="tableData"
      :border-around="true"
      style="max-width: calc(100vw - 18rem)"
    />
    <div v-if="isLoading" class="items-center flex text-base justify-center">
      <spinner />
      <span>{{ $t('CAMPAIGN.LIST.LOADING_MESSAGE') }}</span>
    </div>
  </section>
</template>

<script>
import { mixin as clickaway } from 'vue-clickaway';
import { VeTable } from 'vue-easytable';
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
    VeTable,
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
      const visibleToAllTable = [
        {
          field: 'title',
          key: 'title',
          title: this.$t('CAMPAIGN.LIST.TABLE_HEADER.TITLE'),
          fixed: 'left',
          align: this.isRTLView ? 'right' : 'left',
          renderBodyCell: ({ row }) => (
            <div class="row--title-block">
              <h6 class="text-sm m-0 capitalize text-slate-900 dark:text-slate-100 overflow-hidden whitespace-nowrap text-ellipsis">
                {row.title}
              </h6>
            </div>
          ),
        },

        {
          field: 'message',
          key: 'message',
          title: this.$t('CAMPAIGN.LIST.TABLE_HEADER.MESSAGE'),
          align: this.isRTLView ? 'right' : 'left',
          width: 350,
          renderBodyCell: ({ row }) => {
            if (row.message) {
              return (
                <div class="overflow-hidden whitespace-nowrap text-ellipsis">
                  <span
                    domPropsInnerHTML={this.formatMessage(row.message)}
                  ></span>
                </div>
              );
            }
            return '';
          },
        },
        {
          field: 'inbox',
          key: 'inbox',
          title: this.$t('CAMPAIGN.LIST.TABLE_HEADER.INBOX'),
          align: this.isRTLView ? 'right' : 'left',
          renderBodyCell: ({ row }) => {
            return <InboxName inbox={row.inbox} />;
          },
        },
      ];
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
            field: 'sender',
            key: 'sender',
            title: this.$t('CAMPAIGN.LIST.TABLE_HEADER.SENDER'),
            align: this.isRTLView ? 'right' : 'left',
            renderBodyCell: ({ row }) => {
              if (row.sender) return <UserAvatarWithName user={row.sender} />;
              return this.$t('CAMPAIGN.LIST.SENDER.BOT');
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

          {
            field: 'buttons',
            key: 'buttons',
            title: '',
            align: this.isRTLView ? 'right' : 'left',
            renderBodyCell: row => (
              <div class="justify-evenly flex flex-row min-w-[12.5rem]">
                <WootButton
                  variant="clear"
                  icon="edit"
                  color-scheme="secondary"
                  classNames="grey-btn"
                  onClick={() => this.$emit('on-edit-click', row)}
                >
                  {this.$t('CAMPAIGN.LIST.BUTTONS.EDIT')}
                </WootButton>
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

<style lang="scss" scoped>
.campaigns-table-wrap::v-deep {
  .ve-table {
    @apply pb-12;

    thead.ve-table-header .ve-table-header-tr .ve-table-header-th {
      @apply text-xs py-2 px-5;
    }
    tbody.ve-table-body .ve-table-body-tr .ve-table-body-td {
      @apply py-3 px-5;

      .inbox--name {
        @apply m-0;
      }
    }
  }

  .row--title-block {
    @apply items-center flex text-left;
  }
  .label {
    @apply py-1 px-2;
  }
}
</style>
