<template>
  <section class="campaigns-table-wrap">
    <ve-table
      :columns="columns"
      scroll-width="155rem"
      :table-data="tableData"
      :border-around="true"
    />

    <empty-state v-if="showEmptyResult" :title="$t('CAMPAIGN.LIST.404')" />
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
import CampaignSender from './CampaignSender';

export default {
  components: {
    EmptyState,
    Spinner,
    VeTable,
  },
  mixins: [clickaway],
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
    onEditClick: {
      type: Function,
      default: () => {},
    },
  },

  data() {
    return {
      columns: [
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
            return (
              <div class="text-truncate">
                <span title={row.message}>{row.message}</span>
              </div>
            );
          },
        },
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
            if (row.sender) return <CampaignSender sender={row.sender} />;
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
          renderBodyCell: (row) => (
            <div class="button-wrapper">
              <WootButton
                variant="clear"
                icon="ion-edit"
                color-scheme="secondary"
                classNames="hollow grey-btn"
                onClick={() => this.onEditClick(row)}
              >
                {this.$t('CAMPAIGN.LIST.BUTTONS.EDIT')}
              </WootButton>
            </div>
          ),
        },
      ],
    };
  },
  computed: {
    tableData() {
      if (this.isLoading) {
        return [];
      }
      return this.campaigns.map((item) => {
        return {
          ...item,
          url: item.trigger_rules.url,
          timeOnPage: item.trigger_rules.time_on_page,
        };
      });
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
