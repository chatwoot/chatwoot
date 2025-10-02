<script setup>
import { computed, h, ref } from 'vue';
import {
  useVueTable,
  createColumnHelper,
  getCoreRowModel,
  getSortedRowModel,
} from '@tanstack/vue-table';
import { useI18n } from 'vue-i18n';
import Spinner from 'shared/components/Spinner.vue';
import EmptyState from 'dashboard/components/widgets/EmptyState.vue';
import Table from 'dashboard/components/table/Table.vue';
import Pagination from 'dashboard/components/table/Pagination.vue';
import BotCell from './BotCell.vue';
const { bots, botMetrics, pageIndex } = defineProps({
  bots: {
    type: Array,
    default: () => [],
  },
  botMetrics: {
    type: Array,
    default: () => [],
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
  pageIndex: {
    type: Number,
    default: 0,
  },
});
const emit = defineEmits(['pageChange']);
const { t } = useI18n();
// Add sorting state
const sorting = ref([]);
function getBotInformation(id) {
  return bots?.find(bot => bot.id === Number(id));
}
const totalCount = computed(() => bots.length);
const tableData = computed(() => {
  return botMetrics
    .filter(botMetric => getBotInformation(botMetric.id))
    .map(bot => {
      const botInformation = getBotInformation(bot.id);
      return {
        botName: botInformation.name,
        botType: botInformation.type || 'single', // single, multi, custom
        templateType: botInformation.template_type, // booking, resto, sales, cs (null for custom)
        handoverCount: bot.metric.handover_count ?? 0,
        chatResponded: bot.metric.chat_responded ?? 0,
        status: botInformation.status || 'active',
      };
    });
});
const defaulSpanRender = cellProps =>
  h(
    'span',
    {
      class: cellProps.getValue() ? '' : 'text-slate-300 dark:text-slate-700',
    },
    cellProps.getValue() ? cellProps.getValue() : '---'
  );
const columnHelper = createColumnHelper();
const columns = computed(() => [
  columnHelper.accessor('botName', {
    header: t('AI_AGENT_REPORTS.BOT_SUMMARY.TABLE_HEADER.BOT'),
    cell: cellProps => h(BotCell, cellProps),
    size: 300,
    sortingFn: (rowA, rowB) => {
      const a = rowA.getValue('botName');
      const b = rowB.getValue('botName');
      return a < b ? -1 : a > b ? 1 : 0;
    },
  }),
  columnHelper.accessor('handoverCount', {
    header: t('AI_AGENT_REPORTS.BOT_SUMMARY.TABLE_HEADER.HANDOVERS'),
    cell: defaulSpanRender,
    size: 120,
    sortingFn: (rowA, rowB) => {
      const a = rowA.getValue('handoverCount');
      const b = rowB.getValue('handoverCount');
      return a - b;
    },
  }),
  columnHelper.accessor('chatResponded', {
    header: t('AI_AGENT_REPORTS.BOT_SUMMARY.TABLE_HEADER.CHAT_RESPONDED'),
    cell: defaulSpanRender,
    size: 150,
    sortingFn: (rowA, rowB) => {
      const a = rowA.getValue('chatResponded');
      const b = rowB.getValue('chatResponded');
      return a - b;
    },
  }),
]);
const paginationParams = computed(() => {
  return {
    pageIndex: pageIndex,
    pageSize: 25,
  };
});
const table = useVueTable({
  get data() {
    return tableData.value;
  },
  get columns() {
    return columns.value;
  },
  manualPagination: true,
  enableSorting: true,
  getCoreRowModel: getCoreRowModel(),
  getSortedRowModel: getSortedRowModel(),
  get rowCount() {
    return totalCount.value;
  },
  state: {
    get pagination() {
      return paginationParams.value;
    },
    get sorting() {
      return sorting.value;
    },
  },
  onPaginationChange: updater => {
    const newPagination = updater(paginationParams.value);
    emit('pageChange', newPagination.pageIndex);
  },
  onSortingChange: updater => {
    sorting.value = updater(sorting.value);
  },
});
</script>
<template>
  <div class="bot-table-container">
    <Table :table="table" class="max-h-[calc(100vh-21.875rem)]" />
    <Pagination class="mt-2" :table="table" />
    <div v-if="isLoading" class="bots-loader">
      <Spinner />
      <span>{{
        $t('AI_AGENT_REPORTS.BOT_SUMMARY.LOADING_MESSAGE')
      }}</span>
    </div>
    <EmptyState
      v-else-if="!isLoading && !botMetrics.length"
      :title="$t('AI_AGENT_REPORTS.BOT_SUMMARY.NO_BOTS')"
    />
  </div>
</template>
<style lang="scss" scoped>
.bot-table-container {
  @apply flex flex-col flex-1;
  .ve-table {
    &::v-deep {
      th.ve-table-header-th {
        @apply text-sm rounded-xl;
        padding: var(--space-small) var(--space-two) !important;
        transition: background-color 0.2s ease;
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
.bots-loader {
  @apply items-center flex text-base justify-center p-8;
}
</style>