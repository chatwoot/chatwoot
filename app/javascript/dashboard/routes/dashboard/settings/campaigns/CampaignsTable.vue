<template>
  <section class="campaigns-table-wrap">
    <empty-state v-if="showEmptyResult" :title="emptyMessage" />
    <ve-table
      v-else
      :columns="columns"
      scroll-width="155rem"
      :table-data="tableData"
      :border-around="true"
    />
    <div v-if="isLoading" class="campaign--loader">
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
import InboxIconWithName from 'dashboard/components/widgets/InboxIconWithName';
import campaignMixin from 'shared/mixins/campaignMixin';
import timeMixin from 'dashboard/mixins/time';

export default {
  components: {
    EmptyState,
    Spinner,
    VeTable,
  },

  mixins: [clickaway, timeMixin, campaignMixin, messageFormatterMixin],

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
          align: 'left',
          renderBodyCell: ({ row }) => (
            <div class="row--title-block">
              <h6 class="sub-block-title title text-truncate">{row.title}</h6>
            </div>
          ),
        },

        {
          field: 'message',
          key: 'message',
          title: this.$t('CAMPAIGN.LIST.TABLE_HEADER.MESSAGE'),
          align: 'left',
          width: 350,
          renderBodyCell: ({ row }) => {
            if (row.message) {
              return (
                <div class="text-truncate">
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
          align: 'left',
          renderBodyCell: ({ row }) => {
            return <InboxIconWithName inbox={row.inbox} />;
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
            align: 'left',
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
            align: 'left',
            renderBodyCell: ({ row }) => {
              if (row.sender) return <UserAvatarWithName user={row.sender} />;
              return this.$t('CAMPAIGN.LIST.SENDER.BOT');
            },
          },
          {
            field: 'url',
            key: 'url',
            title: this.$t('CAMPAIGN.LIST.TABLE_HEADER.URL'),
            align: 'left',
            renderBodyCell: ({ row }) => (
              <div class="text-truncate">
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
            align: 'left',
          },

          {
            field: 'buttons',
            key: 'buttons',
            title: '',
            align: 'left',
            renderBodyCell: row => (
              <div class="button-wrapper">
                <WootButton
                  variant="clear"
                  icon="ion-edit"
                  color-scheme="secondary"
                  classNames="grey-btn"
                  onClick={() => this.$emit('on-edit-click', row)}
                >
                  {this.$t('CAMPAIGN.LIST.BUTTONS.EDIT')}
                </WootButton>
                <WootButton
                  variant="link"
                  icon="ion-close-circled"
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
          align: 'left',
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
          align: 'left',
        },
        {
          field: 'buttons',
          key: 'buttons',
          title: '',
          align: 'left',
          renderBodyCell: row => (
            <div class="button-wrapper">
              <WootButton
                variant="link"
                icon="ion-close-circled"
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
    padding-bottom: var(--space-large);
    thead.ve-table-header .ve-table-header-tr .ve-table-header-th {
      font-size: var(--font-size-mini);
      padding: var(--space-small) var(--space-two);
    }
    tbody.ve-table-body .ve-table-body-tr .ve-table-body-td {
      padding: var(--space-slab) var(--space-two);
    }
  }

  .row--title-block {
    align-items: center;
    display: flex;
    text-align: left;

    .title {
      font-size: var(--font-size-small);
      margin: 0;
      text-transform: capitalize;
    }
  }
  .label {
    padding: var(--space-smaller) var(--space-small);
  }
}

.campaign--loader {
  align-items: center;
  display: flex;
  font-size: var(--font-size-default);
  justify-content: center;
  padding: var(--space-big);
}

.button-wrapper {
  justify-content: space-evenly;
  display: flex;
  flex-direction: row;
  min-width: 20rem;
}
</style>
