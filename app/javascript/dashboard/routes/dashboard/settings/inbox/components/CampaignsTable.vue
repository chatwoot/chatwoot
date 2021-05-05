<template>
  <section class="campaigns-table-wrap">
    <ve-table
      :fixed-header="true"
      max-height="calc(100vh - 11.4rem)"
      scroll-width="150rem"
      :columns="columns"
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
          width: 100,
          title: this.$t('CAMPAIGN.LIST.TABLE_HEADER.STATUS'),
          align: 'left',
          renderBodyCell: ({ row }) => {
            return (
              <div>
                <span class={`status status__${row.enabled}`}>
                  {row.enabled
                    ? this.$t('CAMPAIGN.LIST.STATUS.ENABLED')
                    : this.$t('CAMPAIGN.LIST.STATUS.DISABLED')}
                </span>
              </div>
            );
          },
        },

        {
          field: 'sender',
          key: 'sender',
          title: this.$t('CAMPAIGN.LIST.TABLE_HEADER.SENDER'),
          align: 'left',
          width: 200,
          renderBodyCell: ({ row }) => {
            if (row.sender) return <CampaignSender sender={row.sender} />;
            return '---';
          },
        },
        {
          field: 'url',
          key: 'url',
          width: 250,
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
          width: 150,
          title: this.$t('CAMPAIGN.LIST.TABLE_HEADER.TIME_ON_PAGE'),
          align: 'left',
        },

        {
          field: 'buttons',
          key: 'buttons',
          title: '',
          align: 'left',
          renderBodyCell: () => (
            <div class="button-wrapper">
              <WootButton
                variant="clear"
                icon="ion-edit"
                color-scheme="secondary"
                classNames="hollow grey-btn"
                click="openEditPopup(label)"
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
@import '~dashboard/assets/scss/mixins';

.campaigns-table-wrap {
  flex: 1 1;
  height: 100%;
  overflow: hidden;
}

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
.status {
  padding: var(--space-smaller) var(--space-small);
  display: inline-block;
  font-size: var(--font-size-mini);
  font-weight: var(--font-weight-bold);
  border-radius: var(--border-radius-small);
  color: var(--white);
  &__true {
    background-color: var(--g-400);
  }
  &__false {
    background-color: var(--b-600);
  }
}
</style>
