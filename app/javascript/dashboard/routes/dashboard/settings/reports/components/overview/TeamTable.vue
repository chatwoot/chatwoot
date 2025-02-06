<script setup>
import { computed, h } from 'vue';
import {
  useVueTable,
  createColumnHelper,
  getCoreRowModel,
  getPaginationRowModel,
} from '@tanstack/vue-table';
import { useI18n } from 'vue-i18n';

import Spinner from 'shared/components/Spinner.vue';
import EmptyState from 'dashboard/components/widgets/EmptyState.vue';
import Table from 'dashboard/components/table/Table.vue';
import Pagination from 'dashboard/components/table/Pagination.vue';

const { teams, teamMetrics } = defineProps({
  teams: {
    type: Array,
    default: () => [],
  },
  teamMetrics: {
    type: Array,
    default: () => [],
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
});

const { t } = useI18n();

const getTeamMetrics = id =>
  teamMetrics.find(metrics => metrics.team_id === Number(id)) || {};

const tableData = computed(() =>
  teams
    .map(team => {
      const metric = getTeamMetrics(team.id);
      return {
        agent: team.name,
        open: metric.open || 0,
        unattended: metric.unattended || 0,
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
    header: t('OVERVIEW_REPORTS.TEAM_CONVERSATIONS.TABLE_HEADER.TEAM'),
    cell: defaulSpanRender,
    size: 250,
  }),
  columnHelper.accessor('open', {
    header: t('OVERVIEW_REPORTS.TEAM_CONVERSATIONS.TABLE_HEADER.OPEN'),
    cell: defaulSpanRender,
    size: 100,
  }),
  columnHelper.accessor('unattended', {
    header: t('OVERVIEW_REPORTS.TEAM_CONVERSATIONS.TABLE_HEADER.UNATTENDED'),
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
});
</script>

<template>
  <div class="flex flex-col flex-1">
    <Table :table="table" class="max-h-[calc(100vh-21.875rem)]" />
    <Pagination class="mt-2" :table="table" />
    <div
      v-if="isLoading"
      class="items-center flex text-base justify-center p-8"
    >
      <Spinner />
      <span>
        {{ $t('OVERVIEW_REPORTS.TEAM_CONVERSATIONS.LOADING_MESSAGE') }}
      </span>
    </div>
    <EmptyState
      v-else-if="!isLoading && !teams.length"
      :title="$t('OVERVIEW_REPORTS.TEAM_CONVERSATIONS.NO_TEAMS')"
    />
  </div>
</template>
