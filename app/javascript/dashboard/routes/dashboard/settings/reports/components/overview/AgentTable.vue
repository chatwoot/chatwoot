<script setup>
import { computed, h } from 'vue';
import {
  useVueTable,
  createColumnHelper,
  getCoreRowModel,
} from '@tanstack/vue-table';
import { useI18n } from 'vue-i18n';

import Spinner from 'shared/components/Spinner.vue';
import EmptyState from 'dashboard/components/widgets/EmptyState.vue';
import Table from 'dashboard/components/table/Table.vue';
import Pagination from 'dashboard/components/table/Pagination.vue';
import AgentCell from './AgentCell.vue';

const { agents, agentMetrics, pageIndex } = defineProps({
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
  pageIndex: {
    type: Number,
    default: 1,
  },
});

const emit = defineEmits(['pageChange']);
const { t } = useI18n();

function getAgentInformation(id) {
  return agents?.find(agent => agent.id === Number(id));
}

// use for debuggin
function stringToFloat(inputString) {
  if (!inputString) {
    return 0.0;
  }

  // Sum the Unicode values of all characters
  const unicodeSum = Array.from(inputString).reduce(
    (sum, char) => sum + char.charCodeAt(0),
    0
  );

  // Use a large prime number to create more variance
  const prime = 2147483647; // Mersenne prime (2^31 - 1)

  // Generate a hash-like value
  const hashValue = unicodeSum * prime;

  // Normalize to [0, 1] range
  return (hashValue % 1000000) / 1000000.0;
}

const totalCount = computed(() => agents.length);

const tableData = computed(() => {
  return agentMetrics
    .filter(agentMetric => getAgentInformation(agentMetric.id))
    .map(agent => {
      const agentInformation = getAgentInformation(agent.id);
      return {
        agent: agentInformation.name || agentInformation.available_name,
        email: agentInformation.email,
        thumbnail: agentInformation.thumbnail,
        open:
          agent.metric.open ||
          Math.floor(stringToFloat(agentInformation.email) * 50),
        unattended:
          agent.metric.unattended ||
          Math.floor(stringToFloat(agentInformation.email) * 30),
        status: agentInformation.availability_status,
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
  columns,
  manualPagination: true,
  enableSorting: false,
  getCoreRowModel: getCoreRowModel(),
  get rowCount() {
    return totalCount.value;
  },
  state: {
    get pagination() {
      return paginationParams.value;
    },
  },
  onPaginationChange: updater => {
    const newPagintaion = updater(paginationParams.value);
    emit('pageChange', newPagintaion.pageIndex);
  },
});
</script>

<template>
  <div class="agent-table-container">
    <Table :table="table" class="max-h-[calc(100vh-21.875rem)]" />
    <Pagination class="mt-2" :table="table" />
    <div v-if="isLoading" class="agents-loader">
      <Spinner />
      <span>{{
        $t('OVERVIEW_REPORTS.AGENT_CONVERSATIONS.LOADING_MESSAGE')
      }}</span>
    </div>
    <EmptyState
      v-else-if="!isLoading && !agentMetrics.length"
      :title="$t('OVERVIEW_REPORTS.AGENT_CONVERSATIONS.NO_AGENTS')"
    />
  </div>
</template>

<style lang="scss" scoped>
.agent-table-container {
  @apply flex flex-col flex-1;

  .ve-table {
    &::v-deep {
      th.ve-table-header-th {
        @apply text-sm rounded-xl;
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

.agents-loader {
  @apply items-center flex text-base justify-center p-8;
}
</style>
