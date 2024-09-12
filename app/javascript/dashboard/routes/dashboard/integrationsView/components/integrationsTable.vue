<template>
  <section
    class="flex-1 h-full -mt-1 overflow-hidden bg-white contacts-table-wrap dark:bg-slate-900"
  >
    <ve-table
      :fixed-header="true"
      max-height="calc(100vh - 7.125rem)"
      scroll-width="187rem"
      :columns="columns"
      :table-data="tableData"
      :border-around="false"
      :sort-option="sortOption"
    />

    <empty-state
      v-if="showSearchEmptyState"
      :title="$t('ORDERS_PAGE.LIST.404')"
    />
    <empty-state
      v-else-if="!isLoading && !orders.length"
      :title="$t('ORDERS_PAGE.LIST.NO_ORDERS')"
    />
    <div v-if="isLoading" class="flex items-center justify-center text-base">
      <spinner />
      <span>{{ $t('ORDERS_PAGE.LIST.LOADING_MESSAGE') }}</span>
    </div>
  </section>
</template>

<script>
import { VeTable } from 'vue-easytable';

import Spinner from 'shared/components/Spinner.vue';
import EmptyState from 'dashboard/components/widgets/EmptyState.vue';
import { dynamicTime } from 'shared/helpers/timeHelper';
import rtlMixin from 'shared/mixins/rtlMixin';

export default {
  components: {
    EmptyState,
    Spinner,
    VeTable,
  },
  mixins: [rtlMixin],
  props: {
    orders: {
      type: Array,
      default: () => [],
    },
    showSearchEmptyState: {
      type: Boolean,
      default: false,
    },
    onClickOrder: {
      type: Function,
      default: () => {},
    },
    isLoading: {
      type: Boolean,
      default: false,
    },
    activeOrdertId: {
      type: [String, Number],
      default: '',
    },
    sortParam: {
      type: String,
      default: 'last_activity_at',
    },
    sortOrder: {
      type: String,
      default: 'desc',
    },
  },
  data() {
    return {
      sortConfig: {},
      sortOption: {
        sortAlways: true,
        sortChange: params => this.$emit('on-sort-change', params),
      },
    };
  },
  computed: {
    tableData() {
      if (this.isLoading) {
        return [];
      }

      const dateToTimestamp = date => {
        const timestampDate = new Date(date);
        const timestamp = Math.floor(timestampDate.getTime() / 1000);
        return timestamp;
      };

      return this.orders.map(item => {
        // Note: The attributes used here is in snake case
        // as it simplier the sort attribute calculation
        const { date_modified, date_created } = item;
        const new_date_modified = dateToTimestamp(date_modified);
        const new_date_created = dateToTimestamp(date_created);
        return {
          ...item,
          order_number: item.order_number || '---',
          contact: item.contact || {},
          status: item.status || '---',
          total: item.total || '---',
          items: item.order_items || [],
          payment_status: item.payment_status || '---',
          date_modified: new_date_modified
            ? dynamicTime(new_date_modified)
            : '---',
          date_created: new_date_created
            ? dynamicTime(new_date_created)
            : '---',
        };
      });
    },

    columns() {
      return [
        {
          field: 'order_number',
          key: 'order_number',
          title: this.$t('ORDERS_PAGE.LIST.TABLE_HEADER.ORDER_NUMBER'),
          fixed: 'left',
          align: this.isRTLView ? 'right' : 'left',
          sortBy: this.sortConfig.order_number || '',
          width: 300,
          renderBodyCell: ({ row }) => (
            <woot-button
              variant="clear"
              onClick={() => this.onClickOrder(row.id)}
            >
              <div class="row--user-block">
                <div class="user-block">
                  <h6 class="overflow-hidden text-base whitespace-nowrap text-ellipsis">
                    {row.order_number}
                  </h6>
                  <button class="button clear small link view-details--button">
                    <router-link
                      to={`/app/accounts/${this.$route.params.accountId}/integrations-view/${row.id}`}
                      class="user-name"
                    >
                      {this.$t('ORDERS_PAGE.LIST.VIEW_DETAILS')}
                    </router-link>
                  </button>
                </div>
              </div>
            </woot-button>
          ),
        },
        {
          field: 'customer',
          key: 'customer',
          title: this.$t('ORDERS_PAGE.LIST.TABLE_HEADER.CUSTOMER'),
          align: this.isRTLView ? 'right' : 'left',
          sortBy: this.sortConfig.contact?.name || '',
          width: 240,
          renderBodyCell: ({ row }) => {
            if (row.contact?.active)
              return (
                <div class="overflow-hidden whitespace-nowrap text-ellipsis text-woot-500 dark:text-woot-500">
                  <a
                    rel="noopener noreferrer nofollow"
                    href={`/app/accounts/${this.$route.params.accountId}/contacts/${row.contact.id}`}
                  >
                    {row.contact?.name}
                  </a>
                </div>
              );
            return '---';
          },
        },
        {
          field: 'status',
          key: 'status',
          sortBy: this.sortConfig.status || '',
          title: this.$t('ORDERS_PAGE.LIST.TABLE_HEADER.STATUS'),
          align: this.isRTLView ? 'right' : 'left',
        },

        {
          field: 'items',
          key: 'items_qtd',
          sortBy: this.sortConfig.items || '',
          title: this.$t('ORDERS_PAGE.LIST.TABLE_HEADER.ITEMS'),
          align: this.isRTLView ? 'right' : 'left',
          renderBodyCell: ({ row }) => {
            if (row.items)
              return (
                <div class="overflow-hidden whitespace-nowrap text-ellipsis text-woot-500 dark:text-woot-500">
                  {row.items.length}
                </div>
              );
            return '---';
          },
        },
        {
          field: 'total',
          key: 'total',
          sortBy: this.sortConfig.total || '',
          title: this.$t('ORDERS_PAGE.LIST.TABLE_HEADER.TOTAL'),
          align: this.isRTLView ? 'right' : 'left',
          renderBodyCell: ({ row }) => {
            if (row.total) return <div>R$ {row.total}</div>;
            return '---';
          },
        },
        {
          field: 'payment_status',
          key: 'payment_status',
          title: this.$t('ORDERS_PAGE.LIST.TABLE_HEADER.PAYMENT_STATUS'),
          align: this.isRTLView ? 'right' : 'left',
          sortBy: this.sortConfig.payment_status || '',
        },
        {
          field: 'shipping_address',
          key: 'shipping_address',
          title: this.$t('ORDERS_PAGE.LIST.TABLE_HEADER.SHIPPING'),
          align: this.isRTLView ? 'right' : 'left',
          sortBy:
            this.sortConfig.contact?.custom_attributes?.shipping_address || '',
          renderBodyCell: ({ row }) => {
            if (row.contact?.custom_attributes?.shipping_address)
              return (
                <div class="cell_address">
                  <a target="_blank" rel="noopener noreferrer nofollow">
                    {row.contact?.custom_attributes?.shipping_address}
                  </a>
                </div>
              );
            return '---';
          },
        },
        {
          field: 'platform',
          key: 'platform',
          sortBy: this.sortConfig.platform || '',
          title: this.$t('ORDERS_PAGE.LIST.TABLE_HEADER.PLATFORM'),
          align: this.isRTLView ? 'right' : 'left',
        },
        {
          field: 'date_modified',
          key: 'date_modified',
          sortBy: this.sortConfig.date_modified || '',
          title: this.$t('ORDERS_PAGE.LIST.TABLE_HEADER.LAST_ACTIVITY'),
          align: this.isRTLView ? 'right' : 'left',
        },
        {
          field: 'date_created',
          key: 'date_created',
          sortBy: this.sortConfig.date_created || '',
          title: this.$t('ORDERS_PAGE.LIST.TABLE_HEADER.CREATED_AT'),
          align: this.isRTLView ? 'right' : 'left',
        },
      ];
    },
  },
  watch: {
    sortOrder() {
      this.setSortConfig();
    },
    sortParam() {
      this.setSortConfig();
    },
  },
  mounted() {
    this.setSortConfig();
  },
  methods: {
    setSortConfig() {
      this.sortConfig = { [this.sortParam]: this.sortOrder };
    },
  },
};
</script>

<style lang="scss" scoped>
.contacts-table-wrap::v-deep {
  .ve-table {
    @apply pb-8;
  }
  .row--user-block {
    @apply items-center flex text-left;

    .user-block {
      @apply items-start flex flex-col my-0 mx-2;
    }

    .user-name {
      @apply text-sm font-medium m-0 capitalize;
    }

    .view-details--button {
      @apply text-slate-600 dark:text-slate-200;
    }

    .user-email {
      @apply m-0;
    }
  }

  .ve-table-header-th {
    padding: var(--space-small) var(--space-two) !important;
  }

  .ve-table-body-td {
    padding: var(--space-small) var(--space-two) !important;
  }

  .ve-table-header-th {
    font-size: var(--font-size-mini) !important;
  }
  .ve-table-sort {
    @apply -top-1;
  }
}

.cell_address {
  a {
    @apply text-slate-300 dark:text-slate-400 text-sm;
  }
}
</style>
