<script setup>
import OverviewReportFilters from './OverviewReportFilters.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import { formatTime } from '@chatwoot/utils';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import Table from 'dashboard/components/table/Table.vue';
import { generateFileName } from 'dashboard/helper/downloadHelper';
import {
  useVueTable,
  createColumnHelper,
  getCoreRowModel,
  getSortedRowModel,
} from '@tanstack/vue-table';
import { computed, onMounted, ref, h } from 'vue';
import { useI18n } from 'vue-i18n';
import SummaryReportLink from './SummaryReportLink.vue';
import ReportHelpLabel from './ReportHelpLabel.vue';
import { useStatusLabel } from 'dashboard/composables/useStatusLabel';
import { useAccount } from 'dashboard/composables/useAccount';

const props = defineProps({
  type: {
    type: String,
    default: 'account',
  },
  getterKey: {
    type: String,
    default: '',
  },
  actionKey: {
    type: String,
    default: '',
  },
  summaryKey: {
    type: String,
    default: '',
  },
  fetchItemsKey: {
    type: String,
    required: true,
  },
});

const store = useStore();

const from = ref(0);
const to = ref(0);
const businessHours = ref(false);
const sorting = ref([{ id: 'conversationsCount', desc: true }]);

const flagMap = {
  agent: 'isFetchingAgentSummaryReports',
  inbox: 'isFetchingInboxSummaryReports',
  team: 'isFetchingTeamSummaryReports',
  label: 'isFetchingLabelSummaryReports',
};

const uiFlags = useMapGetter('summaryReports/getUIFlags');
const isLoading = computed(() => uiFlags.value[flagMap[props.type]] ?? false);

const rowItems = useMapGetter([props.getterKey]) || [];
const reportMetrics = useMapGetter([props.summaryKey]) || [];

const getMetrics = id =>
  reportMetrics.value.find(metrics => metrics.id === Number(id)) || {};
const columnHelper = createColumnHelper();
const { t } = useI18n();
const { getResolutionCountLabel } = useStatusLabel();
const { currentAccount } = useAccount();

const renderAvgTime = value => (value ? formatTime(value) : '--');
const renderCount = value =>
  value || value === 0 ? Number(value).toLocaleString() : '--';

const tableData = computed(() => {
  const rows = rowItems.value.map(row => {
    const rowMetrics = getMetrics(row.id);
    const {
      conversationsCount = 0,
      avgFirstResponseTime = 0,
      avgResolutionTime = 0,
      avgReplyTime = 0,
      resolvedConversationsCount = 0,
    } = rowMetrics;
    return {
      id: row.id,
      name: row.name ?? row.title,
      type: props.type,
      conversationsCount: Number(conversationsCount || 0),
      avgFirstResponseTime: Number(avgFirstResponseTime || 0),
      avgReplyTime: Number(avgReplyTime || 0),
      avgResolutionTime: Number(avgResolutionTime || 0),
      resolutionsCount: Number(resolvedConversationsCount || 0),
      conversationsCountDisplay: renderCount(conversationsCount),
      avgFirstResponseTimeDisplay: renderAvgTime(avgFirstResponseTime),
      avgReplyTimeDisplay: renderAvgTime(avgReplyTime),
      avgResolutionTimeDisplay: renderAvgTime(avgResolutionTime),
      resolutionsCountDisplay: renderCount(resolvedConversationsCount),
    };
  });

  const totalConversations = rows.reduce(
    (sum, row) => sum + row.conversationsCount,
    0
  );

  const withShare = rows.map(row => {
    const share =
      totalConversations > 0
        ? Math.round((row.conversationsCount / totalConversations) * 1000) / 10
        : 0;
    return {
      ...row,
      sharePercent: share,
      sharePercentDisplay: `${share}%`,
    };
  });

  const ranked = [...withShare].sort(
    (a, b) => b.conversationsCount - a.conversationsCount
  );
  const rankById = new Map(ranked.map((row, index) => [row.id, index + 1]));
  const rowCount = withShare.length;

  return withShare.map(row => {
    const rank = rankById.get(row.id) || 0;
    return {
      ...row,
      rank,
      isTop: rank > 0 && rank <= 3,
      isBottom: rank > 0 && rowCount > 6 && rank > rowCount - 3,
    };
  });
});

const displayCell = (value, className = '') =>
  h(
    'span',
    {
      class: [value === '--' ? 'text-n-slate-11' : '', className]
        .filter(Boolean)
        .join(' '),
    },
    value
  );

const headerWithHelp = (labelKey, helpKey) => () =>
  h(ReportHelpLabel, {
    label: t(labelKey),
    help: helpKey ? t(helpKey) : '',
  });

const columns = computed(() => [
  columnHelper.accessor('rank', {
    header: headerWithHelp('SUMMARY_REPORTS.RANK', 'SUMMARY_REPORTS.HELP.RANK'),
    size: 88,
    minSize: 88,
    meta: { stickyLeft: '0px' },
    cell: info => displayCell(info.getValue()),
  }),
  columnHelper.accessor('name', {
    header: t(`SUMMARY_REPORTS.${props.type.toUpperCase()}`),
    size: 200,
    minSize: 180,
    meta: { stickyLeft: '88px' },
    cell: cellProps => h(SummaryReportLink, cellProps),
  }),
  columnHelper.accessor('conversationsCount', {
    header: headerWithHelp(
      'SUMMARY_REPORTS.CONVERSATIONS',
      'SUMMARY_REPORTS.HELP.CONVERSATIONS'
    ),
    size: 150,
    minSize: 140,
    cell: info => displayCell(info.row.original.conversationsCountDisplay),
  }),
  columnHelper.accessor('sharePercent', {
    header: headerWithHelp(
      'SUMMARY_REPORTS.SHARE',
      'SUMMARY_REPORTS.HELP.SHARE'
    ),
    size: 140,
    minSize: 130,
    cell: info =>
      displayCell(
        info.row.original.sharePercentDisplay,
        [
          info.row.original.isTop ? 'text-n-teal-11 font-medium' : '',
          info.row.original.isBottom ? 'text-n-slate-10' : '',
        ]
          .filter(Boolean)
          .join(' ')
      ),
  }),
  columnHelper.accessor('avgFirstResponseTime', {
    header: headerWithHelp(
      'SUMMARY_REPORTS.AVG_FIRST_RESPONSE_TIME',
      'SUMMARY_REPORTS.HELP.AVG_FIRST_RESPONSE_TIME'
    ),
    size: 150,
    minSize: 140,
    cell: info => displayCell(info.row.original.avgFirstResponseTimeDisplay),
  }),
  columnHelper.accessor('avgResolutionTime', {
    header: headerWithHelp(
      'SUMMARY_REPORTS.AVG_RESOLUTION_TIME',
      'SUMMARY_REPORTS.HELP.AVG_RESOLUTION_TIME'
    ),
    size: 140,
    minSize: 130,
    cell: info => displayCell(info.row.original.avgResolutionTimeDisplay),
  }),
  columnHelper.accessor('avgReplyTime', {
    header: headerWithHelp(
      'SUMMARY_REPORTS.AVG_REPLY_TIME',
      'SUMMARY_REPORTS.HELP.AVG_REPLY_TIME'
    ),
    size: 150,
    minSize: 140,
    cell: info => displayCell(info.row.original.avgReplyTimeDisplay),
  }),
  columnHelper.accessor('resolutionsCount', {
    header: () =>
      h(ReportHelpLabel, {
        label: getResolutionCountLabel(),
        help: t('SUMMARY_REPORTS.HELP.RESOLUTION_COUNT'),
      }),
    size: 150,
    minSize: 140,
    cell: info => displayCell(info.row.original.resolutionsCountDisplay),
  }),
]);

const fetchReportsWithRetry = async () => {
  const params = {
    since: from.value,
    until: to.value,
    businessHours: businessHours.value,
  };
  try {
    await store.dispatch(props.actionKey, params);
  } catch {
    try {
      await store.dispatch(props.actionKey, params);
    } catch {
      useAlert(t('REPORT.SUMMARY_FETCHING_FAILED'));
    }
  }
};

const fetchAllData = () => {
  store.dispatch(props.fetchItemsKey);
  fetchReportsWithRetry();
};

onMounted(() => fetchAllData());

const onFilterChange = updatedFilter => {
  from.value = updatedFilter.from;
  to.value = updatedFilter.to;
  businessHours.value = updatedFilter.businessHours;
  fetchAllData();
};

const table = useVueTable({
  get data() {
    return tableData.value;
  },
  get columns() {
    return columns.value;
  },
  state: {
    get sorting() {
      return sorting.value;
    },
  },
  onSortingChange: updater => {
    sorting.value =
      typeof updater === 'function' ? updater(sorting.value) : updater;
  },
  enableSorting: true,
  getCoreRowModel: getCoreRowModel(),
  getSortedRowModel: getSortedRowModel(),
});

const downloadReports = (exportFormat = 'csv') => {
  const dispatchMethods = {
    agent: 'downloadAgentReports',
    label: 'downloadLabelReports',
    inbox: 'downloadInboxReports',
    team: 'downloadTeamReports',
  };
  if (dispatchMethods[props.type]) {
    const fileName = generateFileName({
      type: props.type,
      to: to.value,
      businessHours: businessHours.value,
      format: exportFormat,
      accountName: currentAccount.value?.name,
    });
    const params = {
      from: from.value,
      to: to.value,
      fileName,
      businessHours: businessHours.value,
      exportFormat,
    };
    store.dispatch(dispatchMethods[props.type], params);
  }
};

defineExpose({ downloadReports });
</script>

<template>
  <OverviewReportFilters
    :disabled="isLoading"
    @filter-change="onFilterChange"
  />
  <div
    class="relative flex-1 overflow-x-auto overflow-y-auto mt-5 shadow outline-1 outline outline-n-container rounded-xl bg-n-solid-2"
  >
    <Table :table="table" type="relaxed" />
    <Transition
      enter-active-class="transition-opacity duration-300 ease-out"
      leave-active-class="transition-opacity duration-200 ease-in"
      enter-from-class="opacity-0"
      leave-to-class="opacity-0"
    >
      <div
        v-if="isLoading"
        class="absolute inset-0 z-10 flex items-center justify-center bg-n-alpha-black1/40"
      >
        <Spinner />
      </div>
    </Transition>
  </div>
</template>
