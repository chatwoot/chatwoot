<template>
  <div class="conversion-table-container">
    <ve-table
      max-height="calc(100vh - 21.875rem)"
      :fixed-header="true"
      :columns="columns"
      :table-data="tableData"
    />
    <div v-if="isLoading" class="conversions-loader">
      <spinner />
      <span>{{
        $t(
          `CONVERSION_REPORTS.${criteriaKey.toUpperCase()}_CONVERSIONS.LOADING_MESSAGE`
        )
      }}</span>
    </div>
    <empty-state
      v-else-if="!isLoading && !conversionMetrics.length"
      :title="
        $t(
          `CONVERSION_REPORTS.${criteriaKey.toUpperCase()}_CONVERSIONS.NO_RESULTS`
        )
      "
    />
    <div v-if="conversionMetrics.length > 0" class="table-pagination">
      <ve-pagination
        :total="resources.length"
        :page-index="pageIndex"
        :page-size="10"
        :page-size-option="[10]"
        @on-page-number-change="onPageNumberChange"
      />
    </div>
  </div>
</template>

<script>
import { VeTable, VePagination } from 'vue-easytable';
import Spinner from 'shared/components/Spinner.vue';
import EmptyState from 'dashboard/components/widgets/EmptyState.vue';
import rtlMixin from 'shared/mixins/rtlMixin';
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';

export default {
  name: 'ConversionTable',
  components: {
    EmptyState,
    Spinner,
    VeTable,
    VePagination,
  },
  mixins: [rtlMixin],
  props: {
    criteriaKey: {
      type: String,
      required: true,
    },
    resources: {
      type: Array,
      default: () => [],
    },
    conversionMetrics: {
      type: Array,
      default: () => [],
    },
    isLoading: {
      type: Boolean,
      default: false,
    },
    pageIndex: {
      type: Number,
      default: 1,
    },
  },
  computed: {
    tableData() {
      return this.conversionMetrics.map(metric => {
        const {
          name,
          email,
          thumbnail,
          availability,
          inbox_type,
          metric: { won, qualified, ratio },
        } = metric;
        return {
          resource: name,
          email,
          thumbnail,
          status: availability,
          inboxType: inbox_type,
          qualified,
          won,
          ratio,
        };
      });
    },
    columns() {
      return [
        {
          field: 'resource',
          key: 'resource',
          title: this.$t('CONVERSION_REPORTS.TABLE_HEADER.RESOURCE'),
          fixed: 'left',
          align: this.isRTLView ? 'right' : 'left',
          width: 25,
          ...this.additionalAttributes,
        },
        {
          field: 'qualified',
          key: 'qualified',
          title: this.$t('CONVERSION_REPORTS.TABLE_HEADER.QUALIFIED_COUNT'),
          align: this.isRTLView ? 'right' : 'left',
          width: 10,
        },
        {
          field: 'won',
          key: 'won',
          title: this.$t('CONVERSION_REPORTS.TABLE_HEADER.WON_COUNT'),
          align: this.isRTLView ? 'right' : 'left',
          width: 10,
        },
        {
          field: 'ratio',
          key: 'ratio',
          title: this.$t('CONVERSION_REPORTS.TABLE_HEADER.CONVERSION_RATIO'),
          align: this.isRTLView ? 'right' : 'left',
          width: 10,
        },
      ];
    },
    additionalAttributes() {
      switch (this.criteriaKey) {
        case 'agent':
          return {
            renderBodyCell: ({ row }) => (
              <div class="row-user-block">
                <Thumbnail
                  src={row.thumbnail}
                  size="32px"
                  username={row.resource}
                  status={row.status}
                />
                <div class="user-block ">
                  <h6 class="title overflow-hidden whitespace-nowrap text-ellipsis">
                    {row.resource}
                  </h6>
                  <span class="sub-title">{row.email}</span>
                </div>
              </div>
            ),
          };
        case 'inbox':
          return {
            renderBodyCell: ({ row }) => (
              <div class="row-user-block">
                <Thumbnail
                  src={row.thumbnail}
                  size="32px"
                  username={row.resource}
                />
                <div class="user-block">
                  <h6 class="title overflow-hidden whitespace-nowrap text-ellipsis">
                    {row.resource}
                  </h6>
                  <span class="sub-title">{row.inboxType}</span>
                </div>
              </div>
            ),
          };
        default:
          return {};
      }
    },
  },
  methods: {
    onPageNumberChange(pageIndex) {
      this.$emit('page-change', pageIndex);
    },
  },
};
</script>

<style lang="scss" scoped>
.conversion-table-container {
  @apply flex flex-col flex-1;

  .ve-table {
    &::v-deep {
      th.ve-table-header-th {
        font-size: var(--font-size-mini) !important;
        padding: var(--space-small) var(--space-two) !important;
      }

      td.ve-table-body-td {
        padding: var(--space-one) var(--space-two) !important;
      }
    }
  }

  &::v-deep .ve-pagination {
    @apply bg-transparent dark:bg-transparent;
  }

  &::v-deep .ve-pagination-select {
    @apply hidden;
  }

  .row-user-block {
    @apply items-center flex text-left;

    .user-block {
      @apply items-start flex flex-col min-w-0 my-0 mx-2;

      .title {
        @apply text-sm m-0 leading-[1.2] text-slate-800 dark:text-slate-100;
      }
      .sub-title {
        @apply text-xs text-slate-600 dark:text-slate-200;
      }
    }
  }

  .table-pagination {
    @apply mt-4 text-right;
  }
}

.conversions-loader {
  @apply items-center flex text-base justify-center p-8;
}
</style>
