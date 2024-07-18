<template>
  <section
    class="products-table-wrap bg-white dark:bg-slate-900 flex-1 h-full overflow-hidden -mt-1"
  >
    <ve-table
      style="width: 100%"
      :fixed-header="true"
      max-height="calc(100vh - 7.125rem)"
      scroll-width="100rem"
      :columns="columns"
      :table-data="tableData"
      :border-around="false"
      :border-x="true"
      :border-y="true"
      :sort-option="sortOption"
    />

    <empty-state
      v-if="showSearchEmptyState"
      :title="$t('PRODUCTS_PAGE.LIST.404')"
    />
    <empty-state
      v-else-if="!isLoading && !products.length"
      :title="$t('PRODUCTS_PAGE.LIST.NO_PRODUCTS')"
    />
    <div v-if="isLoading" class="items-center flex text-base justify-center">
      <spinner />
      <span>{{ $t('PRODUCTS_PAGE.LIST.LOADING_MESSAGE') }}</span>
    </div>
  </section>
</template>

<script>
import Spinner from 'shared/components/Spinner.vue';
import EmptyState from 'dashboard/components/widgets/EmptyState.vue';
import { VeTable } from 'vue-easytable';
import timeMixin from 'dashboard/mixins/time';
import { format } from 'date-fns';

export default {
  components: {
    EmptyState,
    Spinner,
    VeTable,
  },
  mixins: [timeMixin],
  props: {
    products: {
      type: Array,
      default: () => [],
    },
    showSearchEmptyState: {
      type: Boolean,
      default: false,
    },
    onClickProduct: {
      type: Function,
      default: () => {},
    },
    isLoading: {
      type: Boolean,
      default: false,
    },
    activeProductId: {
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
      return this.products.map(item => {
        return {
          ...item,
          ...item.custom_attributes,
        };
      });
    },
    columns() {
      const columns = [
        {
          field: 'name',
          key: 'name',
          width: 300,
          title: this.$t('PRODUCTS_PAGE.LIST.TABLE_HEADER.NAME'),
          fixed: 'left',
          align: this.isRTLView ? 'right' : 'left',
          sortBy: this.sortConfig.name || '',
          renderBodyCell: ({ row }) => (
            <woot-button
              variant="clear"
              onClick={() => this.onClickProduct(row.id)}
            >
              <div class="row--user-block">
                <div class="user-block">
                  <h6 class="text-base overflow-hidden whitespace-nowrap text-ellipsis">
                    {row.name}
                  </h6>
                  <button class="button clear small link view-details--button">
                    {this.$t('PRODUCTS_PAGE.LIST.VIEW_DETAILS')}
                  </button>
                </div>
              </div>
            </woot-button>
          ),
        },
        {
          field: 'short_name',
          key: 'short_name',
          sortBy: this.sortConfig.short_name || '',
          title: this.$t('PRODUCTS_PAGE.LIST.TABLE_HEADER.SHORT_NAME'),
          align: this.isRTLView ? 'right' : 'left',
        },
        {
          field: 'price',
          key: 'price',
          sortBy: this.sortConfig.price || '',
          title: this.$t('PRODUCTS_PAGE.LIST.TABLE_HEADER.PRICE'),
          align: this.isRTLView ? 'right' : 'left',
        },
      ];

      const custom_attribute_definitions =
        this.$store.getters['attributes/getAttributesByModel'](
          'product_attribute'
        );
      custom_attribute_definitions.forEach(item => {
        const column = {
          field: item.attribute_key,
          key: item.attribute_key,
          title: item.attribute_display_name,
          align: this.isRTLView ? 'right' : 'left',
        };
        if (item.attribute_display_type === 'date') {
          column.renderBodyCell = ({ row }) => {
            if (row[item.attribute_key]) {
              return format(new Date(row[item.attribute_key]), 'dd/MM/yyyy');
            }
            return null;
          };
        }
        columns.push(column);
      });

      columns.push({
        field: 'updated_at',
        key: 'updated_at',
        sortBy: this.sortConfig.updated_at || '',
        renderBodyCell: ({ row }) => {
          if (row.updated_at) return this.dynamicTimeFromString(row.updated_at);
          return '-';
        },
        title: this.$t('PRODUCTS_PAGE.LIST.TABLE_HEADER.UPDATED_AT'),
        align: this.isRTLView ? 'right' : 'left',
      });
      columns.push({
        field: 'created_at',
        key: 'created_at',
        sortBy: this.sortConfig.created_at || '',
        renderBodyCell: ({ row }) => {
          if (row.created_at) return this.dynamicTimeFromString(row.created_at);
          return '-';
        },
        title: this.$t('PRODUCTS_PAGE.LIST.TABLE_HEADER.CREATED_AT'),
        align: this.isRTLView ? 'right' : 'left',
      });
      columns.push({
        field: 'disabled',
        key: 'disabled',
        renderBodyCell: ({ row }) => {
          if (row.disabled)
            return this.$t('PRODUCTS_PAGE.LIST.TABLE_HEADER.DISABLED_TEXT');
          return '-';
        },
        title: this.$t('PRODUCTS_PAGE.LIST.TABLE_HEADER.DISABLED'),
        align: this.isRTLView ? 'right' : 'left',
      });
      return columns;
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
.products-table-wrap::v-deep {
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

.cell--social-profiles {
  a {
    @apply text-slate-300 dark:text-slate-400 text-lg min-w-[2rem] text-center;
  }
}
</style>
