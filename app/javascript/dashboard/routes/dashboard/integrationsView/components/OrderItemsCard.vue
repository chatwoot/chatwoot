<template>
  <info-card
    class="flex-1 h-full -mt-1 overflow-hidden bg-white contacts-table-wrap dark:bg-slate-900"
    :header="$t('ORDER_PANEL.LABELS.ITEMS.TITLE')"
  >
    <ve-table
      v-if="items.length > 0"
      :style="{ 'word-break': 'normal' }"
      :fixed-header="true"
      scroll-width="60rem"
      max-height="calc(100vh - 21.875rem)"
      :columns="columns"
      :table-data="tableData"
      :border-around="false"
    />

    <empty-state
      v-if="items.length === 0"
      :title="$t('ORDERS_PAGE.LIST.NO_ITEMS')"
    />
  </info-card>
</template>

<script>
import InfoCard from '../../../../../shared/components/InfoCard.vue';
import { VeTable } from 'vue-easytable';
import EmptyState from 'dashboard/components/widgets/EmptyState.vue';

import OrderInfoDisplay from './OrderInfoDisplay.vue';
import rtlMixin from 'shared/mixins/rtlMixin';

export default {
  components: {
    InfoCard,
    OrderInfoDisplay,
    VeTable,
    EmptyState,
  },

  mixins: [rtlMixin],
  props: {
    items: {
      type: Array,
      default: () => [],
    },
  },

  computed: {
    tableData() {
      return this.items?.map(item => {
        return {
          ...item,
          name: item.name || '---',
          product_id: item.product_id || '---',
          quantity: item.quantity || '---',
          sku: item.sku || '---',
          variation_id: item.variation_id || '---',
        };
      });
    },

    columns() {
      return [
        {
          field: 'name',
          key: 'name',
          title: this.$t('ORDER_PANEL.LABELS.ITEMS.NAME'),
          align: this.isRTLView ? 'right' : 'left',
          width: 400,
          renderBodyCell: ({ row }) => (
            <div class="row--user-block">
              <div class="user-block">
                <h6 class="overflow-hidden text-base text-ellipsis">
                  {row.name}
                </h6>
              </div>
            </div>
          ),
        },

        {
          field: 'price',
          key: 'price',
          title: this.$t('ORDER_PANEL.LABELS.ITEMS.PRICE'),
          align: 'center',

          renderBodyCell: ({ row }) => {
            if (row.price) return <div>R$ {row.price}</div>;
            return '---';
          },
        },
        {
          field: 'quantity',
          key: 'quantity',
          title: this.$t('ORDER_PANEL.LABELS.ITEMS.QUANTITY'),
          align: 'center',
        },
        {
          field: 'sku',
          key: 'sku',
          title: this.$t('ORDER_PANEL.LABELS.ITEMS.SKU'),
          align: 'center',
        },
        {
          field: 'subtotal',
          key: 'subtotal',
          title: this.$t('ORDER_PANEL.LABELS.ITEMS.SUBTOTAL'),
          align: 'center',
          renderBodyCell: ({ row }) => {
            if (row.subtotal) return <div>R$ {row.subtotal}</div>;
            return '---';
          },
        },
        {
          field: 'variation_id',
          key: 'variation_id',
          title: this.$t('ORDER_PANEL.LABELS.ITEMS.VARIANT'),
          align: 'center',
        },
      ];
    },
  },

  methods: {},
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
</style>
