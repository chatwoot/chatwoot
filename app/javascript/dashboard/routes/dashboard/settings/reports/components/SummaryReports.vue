<script setup>
import OverviewReportFilters from './OverviewReportFilters.vue';
import SummaryDistribution from './SummaryDistribution.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import { formatDuration } from 'shared/helpers/localizedDate';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import Table from 'dashboard/components/table/Table.vue';
import { generateFileName } from 'dashboard/helper/downloadHelper';
import SummaryReportsAPI from 'dashboard/api/summaryReports';
import { useAbortableRequest } from 'dashboard/composables/useAbortableRequest';
import {
  conversationsLabel,
  metricHintKey,
  supportsHandled,
} from '../helpers/conversationMetrics';
import {
  useVueTable,
  createColumnHelper,
  getCoreRowModel,
  getSortedRowModel,
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
  // Second dimension the summary can be narrowed to: 'inboxes' on an agents
  // overview, 'agents' on an inboxes overview.
  crossFilterType: {
    type: String,
    default: '',
  },
});

const store = useStore();

const from = ref(0);
const to = ref(0);
const businessHours = ref(false);
const crossFilterId = ref(null);
import { useI18n } from 'vue-i18n';
import SummaryReportLink from './SummaryReportLink.vue';

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

// The row carries the raw number so sorting compares numbers; the cell is what
// turns it into "28 Min 40 Sec" or "--".
const renderAvgTime = value => (value ? formatDuration(value) : '--');

const renderCount = value => (value ? value.toLocaleString() : '--');

const spanRender = format => cellProps => {
  const value = cellProps.getValue();
  return h('span', { class: value ? '' : 'text-n-slate-12' }, format(value));
};

// Named rather than inferred: TanStack picks the comparator by sampling
// `flatRows.slice(10)`, which is empty on a roster of ten or fewer and lands on
// a lexicographic compare. It happens to read these floats correctly today, and
// would stop the day the API sends `"600.0"` instead of `600`.
const byNumber = (rowA, rowB, columnId) =>
  Number(rowA.getValue(columnId)) - Number(rowB.getValue(columnId));

// A row with nothing to show stays at the bottom either way round: it is the
// absence of a measurement, not a measurement of zero.
const metricColumn = (key, headerKey, format, hintKey) =>
  columnHelper.accessor(key, {
    header: hintKey
      ? () =>
          h(
            'span',
            { class: 'inline-flex items-center gap-1', title: t(hintKey) },
            [
              t(headerKey),
              h('span', { class: 'i-lucide-info size-3.5 text-n-slate-10' }),
            ]
          )
      : t(headerKey),
    width: 200,
    cell: spanRender(format),
    sortDescFirst: true,
    sortUndefined: 'last',
    sortingFn: byNumber,
  });

const columns = computed(() => [
  columnHelper.accessor('name', {
    header: t(`SUMMARY_REPORTS.${props.type.toUpperCase()}`),
    width: 300,
    cell: cellProps => h(SummaryReportLink, cellProps),
    sortDescFirst: false,
    // Without this the comparator is inferred, and 8.20.5 infers it from
    // `flatRows.slice(10)` — empty on a roster of ten or fewer, which falls back
    // to a case-sensitive compare that puts `VIP` above `billing`. Alphanumeric
    // also reads the digits in names like `Suporte 10` as numbers.
    sortingFn: 'alphanumeric',
  }),
  metricColumn(
    'resolutionsCount',
    'SUMMARY_REPORTS.RESOLUTION_COUNT',
    renderCount,
    metricHintKey('resolved', props.type)
  ),
  ...(supportsHandled(props.type)
    ? [
        metricColumn(
          'handledConversationsCount',
          'SUMMARY_REPORTS.HANDLED',
          renderCount,
          metricHintKey('handled', props.type)
        ),
      ]
    : []),
  props.type === 'label'
    ? metricColumn(
        'conversationsCount',
        'SUMMARY_REPORTS.CONVERSATIONS',
        renderCount
      )
    : metricColumn(
        'conversationsCount',
        `SUMMARY_REPORTS.${conversationsLabel(props.type)}`,
        renderCount,
        metricHintKey('conversations', props.type)
      ),
  metricColumn(
    'avgFirstResponseTime',
    'SUMMARY_REPORTS.AVG_FIRST_RESPONSE_TIME',
    renderAvgTime
  ),
  metricColumn(
    'avgResolutionTime',
    'SUMMARY_REPORTS.AVG_RESOLUTION_TIME',
    renderAvgTime
  ),
  metricColumn('avgReplyTime', 'SUMMARY_REPORTS.AVG_REPLY_TIME', renderAvgTime),
]);

// Once the report is narrowed to a single inbox (or agent), the backend only
// returns the rows that took part in it, so the roster is trimmed to match.
const visibleRowItems = computed(() => {
  if (!crossFilterId.value) return rowItems.value;

  const reportedIds = new Set(reportMetrics.value.map(metrics => metrics.id));
  return rowItems.value.filter(row => reportedIds.has(Number(row.id)));
});

const tableData = computed(() =>
  visibleRowItems.value.map(row => {
    const rowMetrics = getMetrics(row.id);
    const {
      conversationsCount,
      avgFirstResponseTime,
      avgResolutionTime,
      avgReplyTime,
      resolvedConversationsCount,
      handledConversationsCount,
    } = rowMetrics;
    return {
      id: row.id,
      // we fallback on title, label for instance does not have a name property
      name: row.name ?? row.title,
      type: props.type,
      conversationsCount: conversationsCount || undefined,
      avgFirstResponseTime: avgFirstResponseTime || undefined,
      avgReplyTime: avgReplyTime || undefined,
      avgResolutionTime: avgResolutionTime || undefined,
      resolutionsCount: resolvedConversationsCount || undefined,
      handledConversationsCount: handledConversationsCount || undefined,
    };
  })
);

// The chart reads the same rows as the table, but needs the numbers unformatted.
// Labels are left out: a conversation carries several of them, so the shares
// would add up past the total.
const distributionType = computed(() =>
  ['agent', 'inbox', 'team'].includes(props.type) ? props.type : ''
);

const distributionRows = computed(() =>
  visibleRowItems.value.map(row => {
    const {
      conversationsCount,
      resolvedConversationsCount,
      handledConversationsCount,
    } = getMetrics(row.id);
    return {
      id: row.id,
      name: row.name ?? row.title,
      conversationsCount: conversationsCount ?? 0,
      resolvedConversationsCount: resolvedConversationsCount ?? 0,
      handledConversationsCount: handledConversationsCount ?? 0,
    };
  })
);

// Names the downloaded file, so the same report filtered two ways lands in two
// files instead of overwriting itself.
const crossFilterName = computed(() => {
  if (!crossFilterId.value) return '';

  const getterKey =
    props.crossFilterType === 'inboxes'
      ? 'inboxes/getInboxes'
      : 'agents/getAgents';
  const items = store.getters[getterKey] ?? [];
  return items.find(item => item.id === crossFilterId.value)?.name ?? '';
});

const crossFilterParams = computed(() => {
  if (!props.crossFilterType || !crossFilterId.value) return {};

  return props.crossFilterType === 'inboxes'
    ? { inboxId: crossFilterId.value }
    : { userId: crossFilterId.value };
});

const fetchReportsWithRetry = async () => {
  const params = {
    since: from.value,
    until: to.value,
    businessHours: businessHours.value,
    ...crossFilterParams.value,
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

// Agents overlap on handled conversations, so the distribution needs the distinct
// count, for the account or the inbox the report is narrowed to. It has an endpoint
// of its own: the account summary would compute every metric twice over to hand
// back this one number. A filter change supersedes the request in flight, so an
// older period's total can never land on the current rows.
const handledTotal = ref(null);
const { run: runHandledTotal } = useAbortableRequest();
const fetchHandledTotal = async () => {
  handledTotal.value = null;
  if (props.type !== 'agent') return;

  const ABORTED = Symbol('aborted');
  try {
    const response = await runHandledTotal(
      signal =>
        SummaryReportsAPI.getHandledConversations({
          since: from.value,
          until: to.value,
          inboxId: crossFilterParams.value.inboxId,
          signal,
        }),
      { onAbort: ABORTED }
    );
    if (response === ABORTED) return;
    handledTotal.value = response.data.count ?? null;
  } catch {
    // Without it the card falls back to the sum of the rows.
  }
};

const fetchAllData = () => {
  store.dispatch(props.fetchItemsKey);
  fetchReportsWithRetry();
  fetchHandledTotal();
};

onMounted(() => fetchAllData());

const onFilterChange = updatedFilter => {
  from.value = updatedFilter.from;
  to.value = updatedFilter.to;
  businessHours.value = updatedFilter.businessHours;
  crossFilterId.value = updatedFilter.inboxId ?? updatedFilter.userId ?? null;
  fetchAllData();
};

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
      filteredBy: crossFilterName.value,
      filterId: crossFilterId.value ?? '',
    });
    const params = {
      from: from.value,
      to: to.value,
      fileName,
      businessHours: businessHours.value,
      ...crossFilterParams.value,
    };
    store.dispatch(dispatchMethods[props.type], params);
  }
};

defineExpose({ downloadReports });
</script>

<template>
  <OverviewReportFilters
    :disabled="isLoading"
    :cross-filter-type="crossFilterType"
    @filter-change="onFilterChange"
  />
  <SummaryDistribution
    v-if="distributionType"
    :type="distributionType"
    :rows="distributionRows"
    :handled-total="handledTotal"
    :is-loading="isLoading"
  />
  <div
    class="relative flex-1 overflow-auto px-2 py-2 mt-5 shadow outline-1 outline outline-n-container rounded-xl bg-n-solid-2"
  >
    <Table :table="table" />
    <p
      v-if="!isLoading && crossFilterId && !tableData.length"
      class="py-8 mb-0 text-sm text-center text-n-slate-11"
    >
      {{ $t('REPORT.CROSS_FILTER.NO_RESULTS') }}
    </p>
    <Transition
      enter-active-class="transition-opacity duration-300 ease-out"
      leave-active-class="transition-opacity duration-200 ease-in"
      enter-from-class="opacity-0"
      enter-to-class="opacity-100"
      leave-from-class="opacity-100"
      leave-to-class="opacity-0"
    >
      <div
        v-if="isLoading"
        class="absolute inset-0 flex justify-center pt-[12.5rem] bg-n-solid-1/70 rounded-xl pointer-events-none"
      >
        <Spinner :size="32" class="text-n-brand" />
      </div>
    </Transition>
  </div>
</template>
