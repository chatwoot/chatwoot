<script setup>
import { computed, h } from 'vue';
import {
  useVueTable,
  createColumnHelper,
  getCoreRowModel,
  getPaginationRowModel,
} from '@tanstack/vue-table';
import { useI18n } from 'vue-i18n';
import { useUISettings } from 'dashboard/composables/useUISettings';

import Spinner from 'shared/components/Spinner.vue';
import EmptyState from 'dashboard/components/widgets/EmptyState.vue';
import Table from 'dashboard/components/table/Table.vue';
import Pagination from 'dashboard/components/table/Pagination.vue';
import AgentCell from './AgentCell.vue';

const { agents, agentMetrics } = defineProps({
  agents: {
    type: Array,
    default: () => [],
  },
  agentMetrics: {
    type: Array,
    default: () => [],
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
});

const { t } = useI18n();
const { uiSettings, updateUISettings } = useUISettings();

// UI Settings key for agent table page size
const AGENT_TABLE_PAGE_SIZE_KEY = 'report_overview_agent_table_page_size';

// Get the saved page size from UI settings or default to 10
const getPageSize = () => {
  return uiSettings.value[AGENT_TABLE_PAGE_SIZE_KEY] || 10;
};

const handlePageSizeChange = pageSize => {
  updateUISettings({ [AGENT_TABLE_PAGE_SIZE_KEY]: pageSize });
};

const getAgentMetrics = id =>
  agentMetrics.find(metrics => metrics.assignee_id === Number(id)) || {};

const tableData = computed(() =>
  agents
    .map(agent => {
      const metric = getAgentMetrics(agent.id);
      return {
        agent: agent.available_name || agent.name,
        email: agent.email,
        thumbnail: agent.thumbnail,
        open: metric.open || 0,
        unattended: metric.unattended || 0,
        status: agent.availability_status,
      };
    })
    .sort((a, b) => {
      // First sort by open tickets (descending)
      const openDiff = b.open - a.open;
      // If open tickets are equal, sort by name (ascending)
      if (openDiff === 0) {
        return a.agent.localeCompare(b.agent);
      }
      return openDiff;
    })
);

const defaulSpanRender = cellProps =>
  h(
    'span',

    {
      class: cellProps.getValue()
        ? 'capitalize text-n-slate-12'
        : 'capitalize text-n-slate-11',
    },
    cellProps.getValue() ? cellProps.getValue() : '---'
  );

const columnHelper = createColumnHelper();
const columns = [
  columnHelper.accessor('agent', {
    header: t('OVERVIEW_REPORTS.AGENT_CONVERSATIONS.TABLE_HEADER.AGENT'),
    cell: cellProps => h(AgentCell, cellProps),

    size: 250,
  }),
  columnHelper.accessor('open', {
    header: t('OVERVIEW_REPORTS.AGENT_CONVERSATIONS.TABLE_HEADER.OPEN'),
    cell: defaulSpanRender,
    size: 100,
  }),
  columnHelper.accessor('unattended', {
    header: t('OVERVIEW_REPORTS.AGENT_CONVERSATIONS.TABLE_HEADER.UNATTENDED'),
    cell: defaulSpanRender,
    size: 100,
  }),
];

const table = useVueTable({
  get data() {
    return tableData.value;
  },
  columns,
  enableSorting: false,
  getCoreRowModel: getCoreRowModel(),
  getPaginationRowModel: getPaginationRowModel(),
  initialState: {
    pagination: {
      pageSize: getPageSize(),
    },
  },
});
</script>

<template>
  <div class="flex flex-col flex-1">
    <Table :table="table" class="max-h-[calc(100vh-21.875rem)]" />
    <Pagination
      class="mt-2"
      :table="table"
      show-page-size-selector
      :default-page-size="getPageSize()"
      @page-size-change="handlePageSizeChange"
    />
    <div
      v-if="isLoading"
      class="items-center flex text-base justify-center p-8"
    >
      <Spinner />
      <span>
        {{ $t('OVERVIEW_REPORTS.AGENT_CONVERSATIONS.LOADING_MESSAGE') }}
      </span>
    </div>
    <EmptyState
      v-else-if="!isLoading && !agents.length"
      :title="$t('OVERVIEW_REPORTS.AGENT_CONVERSATIONS.NO_AGENTS')"
    />
  </div>
</template>
