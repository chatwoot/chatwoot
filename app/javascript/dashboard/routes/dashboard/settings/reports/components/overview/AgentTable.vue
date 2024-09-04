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
  // pageIndex: {
  //   type: Number,
  //   default: 1,
  // },
});

// const emit = defineEmits(['pageChange']);
const { t } = useI18n();

// function onPageNumberChange(pageIndex) {
//   emit('pageChange', pageIndex);
// }

function getAgentInformation(id) {
  return agents?.find(agent => agent.id === Number(id));
}

const tableData = computed(() => {
  return agentMetrics
    .filter(agentMetric => getAgentInformation(agentMetric.id))
    .map(agent => {
      const agentInformation = getAgentInformation(agent.id);
      return {
        agent: agentInformation.name || agentInformation.available_name,
        email: agentInformation.email,
        thumbnail: agentInformation.thumbnail,
        open: agent.metric.open || 0,
        unattended: agent.metric.unattended || 0,
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

const table = useVueTable({
  get data() {
    return tableData.value;
  },
  columns,
  enableSorting: false,
  getCoreRowModel: getCoreRowModel(),
});

// export default {
//     columns() {
//       return [
//         {
//           field: 'agent',
//           key: 'agent',
//           title: this.$t(
//             'OVERVIEW_REPORTS.AGENT_CONVERSATIONS.TABLE_HEADER.AGENT'
//           ),
//           fixed: 'left',
//           align: this.isRTL ? 'right' : 'left',
//           width: 25,
//           // renderBodyCell: ({ row }) => (
//           //   <div class="row-user-block">
//           //     <Thumbnail
//           //       src={row.thumbnail}
//           //       size="32px"
//           //       username={row.agent}
//           //       status={row.status}
//           //     />
//           //     <div class="user-block">
//           //       <h6 class="overflow-hidden title whitespace-nowrap text-ellipsis">
//           //         {row.agent}
//           //       </h6>
//           //       <span class="sub-title">{row.email}</span>
//           //     </div>
//           //   </div>
//           // ),
//         },
//         {
//           field: 'open',
//           key: 'open',
//           title: this.$t(
//             'OVERVIEW_REPORTS.AGENT_CONVERSATIONS.TABLE_HEADER.OPEN'
//           ),
//           align: this.isRTL ? 'right' : 'left',
//           width: 10,
//         },
//         {
//           field: 'unattended',
//           key: 'unattended',
//           title: this.$t(
//             'OVERVIEW_REPORTS.AGENT_CONVERSATIONS.TABLE_HEADER.UNATTENDED'
//           ),
//           align: this.isRTL ? 'right' : 'left',
//           width: 10,
//         },
//       ];
//     },
//   },
// };
</script>

<template>
  <div
    class="agent-table-container border border-t-0 border-slate-50 overflow-hidden"
  >
    <Table :table="table" class="max-h-[calc(100vh-21.875rem)]" />
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
    <!-- <div v-if="agentMetrics.length > 0" class="table-pagination">
      <VePagination
        :total="agents.length"
        :page-index="pageIndex"
        :page-size="25"
        :page-size-option="[25]"
        @on-page-number-change="onPageNumberChange"
      />
    </div> -->
  </div>
</template>

<style lang="scss" scoped>
.agent-table-container {
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

.agents-loader {
  @apply items-center flex text-base justify-center p-8;
}
</style>
