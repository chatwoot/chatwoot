<script setup>
import { formatTime } from '@chatwoot/utils';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import Table from 'dashboard/components/table/Table.vue';
import {
  useVueTable,
  createColumnHelper,
  getCoreRowModel,
  getSortedRowModel,
} from '@tanstack/vue-table';
import { computed, watch, h } from 'vue';
import ReportsAPI from 'dashboard/api/reports';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  from: {
    type: Number,
    default: 0,
  },
  to: {
    type: Number,
    default: 0,
  },
  groupBy: {
    type: Object,
    default: () => ({}),
  },
  businessHours: {
    type: Boolean,
    default: false,
  },
  selectedInbox: {
    type: Array,
    default: () => [],
  },
});

const store = useStore();
const { t } = useI18n();

const bots = useMapGetter('agentBots/getBots');
const reportMetrics = useMapGetter('summaryReports/getBotSummaryReports');

const getMetrics = id => {
  const metrics = reportMetrics.value || [];
  return metrics.find(m => m.id === Number(id)) || {};
};

const columnHelper = createColumnHelper();

const defaulSpanRender = cellProps =>
  h(
    'span',
    {
      class: cellProps.getValue() ? '' : 'text-n-slate-12',
    },
    cellProps.getValue()
  );

const parseFormattedValue = value => {
  if (!value || value === '--') return 0;
  if (typeof value === 'string') {
    return parseFloat(value.replace(/,/g, '')) || 0;
  }
  return value;
};

const columns = computed(() => [
  columnHelper.accessor('name', {
    header: t('BOT_REPORTS.TABLE.BOT_NAME'),
    width: 300,
    cell: defaulSpanRender,
    enableSorting: true,
  }),
  columnHelper.accessor('conversationsCount', {
    header: t('BOT_REPORTS.TABLE.CONVERSATIONS'),
    width: 200,
    cell: defaulSpanRender,
    enableSorting: true,
    sortingFn: (rowA, rowB) => {
      const a = parseFormattedValue(rowA.original.conversationsCount);
      const b = parseFormattedValue(rowB.original.conversationsCount);
      return a - b;
    },
  }),
  columnHelper.accessor('avgFirstResponseTime', {
    header: t('BOT_REPORTS.TABLE.AVG_FIRST_RESPONSE_TIME'),
    width: 200,
    cell: defaulSpanRender,
    enableSorting: true,
    sortingFn: (rowA, rowB) => {
      const a = rowA.original.avgFirstResponseTimeRaw || 0;
      const b = rowB.original.avgFirstResponseTimeRaw || 0;
      return a - b;
    },
  }),
  columnHelper.accessor('avgReplyTime', {
    header: t('BOT_REPORTS.TABLE.AVG_REPLY_TIME'),
    width: 200,
    cell: defaulSpanRender,
    enableSorting: true,
    sortingFn: (rowA, rowB) => {
      const a = rowA.original.avgReplyTimeRaw || 0;
      const b = rowB.original.avgReplyTimeRaw || 0;
      return a - b;
    },
  }),
  columnHelper.accessor('avgResolutionTime', {
    header: t('BOT_REPORTS.TABLE.AVG_RESOLUTION_TIME'),
    width: 220,
    cell: defaulSpanRender,
    enableSorting: true,
    sortingFn: (rowA, rowB) => {
      const a = rowA.original.avgResolutionTimeRaw || 0;
      const b = rowB.original.avgResolutionTimeRaw || 0;
      return a - b;
    },
  }),
]);

const renderAvgTime = value => (value ? formatTime(value) : '--');
const renderCount = value => (value ? value.toLocaleString() : '--');

const tableData = computed(() => {
  const botsArray = bots.value || [];
  return botsArray.map(bot => {
    const botMetrics = getMetrics(bot.id);

    const {
      conversationsCount,
      avgFirstResponseTime,
      avgReplyTime,
      avgResolutionTime,
      resolvedConversationsCount,
      handoffsCount,
    } = botMetrics;

    return {
      id: bot.id,
      name: bot.name,
      conversationsCount: renderCount(conversationsCount),
      avgFirstResponseTime: renderAvgTime(avgFirstResponseTime),
      avgReplyTime: renderAvgTime(avgReplyTime),
      avgResolutionTime: renderAvgTime(avgResolutionTime),
      resolutionsCount: renderCount(resolvedConversationsCount),
      handoffsCount: renderCount(handoffsCount),
      avgFirstResponseTimeRaw: avgFirstResponseTime || 0,
      avgReplyTimeRaw: avgReplyTime || 0,
      avgResolutionTimeRaw: avgResolutionTime || 0,
    };
  });
});

const fetchAllData = () => {
  store.dispatch('agentBots/get');

  const params = {
    since: props.from,
    until: props.to,
    businessHours: props.businessHours,
    groupBy: props.groupBy?.period || 'day',
  };

  if (props.selectedInbox && props.selectedInbox.length > 0) {
    params.inboxId = props.selectedInbox;
  }

  store.dispatch('summaryReports/fetchBotSummaryReports', params);
};

watch(
  () => [
    props.from,
    props.to,
    props.groupBy,
    props.businessHours,
    props.selectedInbox,
  ],
  () => {
    if (props.from && props.to) {
      fetchAllData();
    }
  },
  { immediate: true }
);

const table = useVueTable({
  get data() {
    return tableData.value;
  },
  get columns() {
    return columns.value;
  },
  enableSorting: true,
  getCoreRowModel: getCoreRowModel(),
  getSortedRowModel: getSortedRowModel(),
});

const downloadReports = async (format = 'csv') => {
  const params = {
    from: props.from,
    to: props.to,
    businessHours: props.businessHours,
    groupBy: props.groupBy?.period || 'day',
    format,
  };

  if (props.selectedInbox && props.selectedInbox.length > 0) {
    params.inboxId = props.selectedInbox;
  }

  const response = await ReportsAPI.getBotSummaryReports(params);

  const fileName = `bot_summary_report_${Date.now()}.${format}`;
  const mimeType =
    format === 'xlsx'
      ? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      : 'text/csv';

  const blob = new Blob([response.data], { type: mimeType });
  const url = window.URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = fileName;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  window.URL.revokeObjectURL(url);
};

defineExpose({ downloadReports });
</script>

<template>
  <div
    class="flex-1 overflow-auto px-2 py-2 shadow outline-1 outline outline-n-container rounded-xl bg-n-solid-2"
  >
    <Table :table="table" />
  </div>
</template>
