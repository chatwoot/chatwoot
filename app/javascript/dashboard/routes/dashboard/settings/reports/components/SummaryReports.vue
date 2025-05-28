<script setup>
import ReportFilterSelector from './FilterSelector.vue';
import { formatTime } from '@chatwoot/utils';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import Table from 'dashboard/components/table/Table.vue';
import { generateFileName } from 'dashboard/helper/downloadHelper';
import {
  useVueTable,
  createColumnHelper,
  getCoreRowModel,
} from '@tanstack/vue-table';
import { computed, onMounted, ref, h } from 'vue';

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
import { useI18n } from 'vue-i18n';
import SummaryReportLink from './SummaryReportLink.vue';

const rowItems = useMapGetter([props.getterKey]) || [];
const reportMetrics = useMapGetter([props.summaryKey]) || [];

const getMetrics = id =>
  reportMetrics.value.find(metrics => metrics.id === Number(id)) || {};
const columnHelper = createColumnHelper();
const { t } = useI18n();

const defaulSpanRender = cellProps =>
  h(
    'span',
    {
      class: cellProps.getValue() ? '' : 'text-n-slate-12',
    },
    cellProps.getValue()
  );

const columns = [
  columnHelper.accessor('name', {
    header: t(`SUMMARY_REPORTS.${props.type.toUpperCase()}`),
    width: 300,
    cell: cellProps => h(SummaryReportLink, cellProps),
  }),
  columnHelper.accessor('conversationsCount', {
    header: t('SUMMARY_REPORTS.CONVERSATIONS'),
    width: 200,
    cell: defaulSpanRender,
  }),
  columnHelper.accessor('avgFirstResponseTime', {
    header: t('SUMMARY_REPORTS.AVG_FIRST_RESPONSE_TIME'),
    width: 200,
    cell: defaulSpanRender,
  }),
  columnHelper.accessor('avgResolutionTime', {
    header: t('SUMMARY_REPORTS.AVG_RESOLUTION_TIME'),
    width: 200,
    cell: defaulSpanRender,
  }),
  columnHelper.accessor('avgReplyTime', {
    header: t('SUMMARY_REPORTS.AVG_REPLY_TIME'),
    width: 200,
    cell: defaulSpanRender,
  }),
  columnHelper.accessor('resolutionsCount', {
    header: t('SUMMARY_REPORTS.RESOLUTION_COUNT'),
    width: 200,
    cell: defaulSpanRender,
  }),
];

const renderAvgTime = value => (value ? formatTime(value) : '--');

const renderCount = value => (value ? value.toLocaleString() : '--');

const tableData = computed(() =>
  rowItems.value.map(row => {
    const rowMetrics = getMetrics(row.id);
    const {
      conversationsCount,
      avgFirstResponseTime,
      avgResolutionTime,
      avgReplyTime,
      resolvedConversationsCount,
    } = rowMetrics;
    return {
      id: row.id,
      name: row.name,
      type: props.type,
      conversationsCount: renderCount(conversationsCount),
      avgFirstResponseTime: renderAvgTime(avgFirstResponseTime),
      avgReplyTime: renderAvgTime(avgReplyTime),
      avgResolutionTime: renderAvgTime(avgResolutionTime),
      resolutionsCount: renderCount(resolvedConversationsCount),
    };
  })
);

const fetchAllData = () => {
  store.dispatch(props.fetchItemsKey);
  store.dispatch(props.actionKey, {
    since: from.value,
    until: to.value,
    businessHours: businessHours.value,
  });
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
  columns,
  enableSorting: false,
  getCoreRowModel: getCoreRowModel(),
});

// downloadReports method is not used in this component
// but it is exposed to be used in the parent component
const downloadReports = () => {
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
    });
    const params = {
      from: from.value,
      to: to.value,
      fileName,
      businessHours: businessHours.value,
    };
    store.dispatch(dispatchMethods[props.type], params);
  }
};

defineExpose({ downloadReports });
</script>

<template>
  <ReportFilterSelector @filter-change="onFilterChange" />
  <div
    class="flex-1 overflow-auto px-5 py-6 mt-5 shadow outline-1 outline outline-n-container rounded-xl bg-n-solid-2"
  >
    <Table :table="table" />
  </div>
</template>
