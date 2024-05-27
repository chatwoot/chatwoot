<template>
  <div class="agent-table-container">
    <ve-table
      max-height="calc(100vh - 21.875rem)"
      :fixed-header="true"
      :columns="columns"
      :table-data="tableData"
    />
    <div v-if="isLoading" class="agents-loader">
      <spinner />
      <span>{{
        $t('OVERVIEW_REPORTS.TEAM_CONVERSATIONS.LOADING_MESSAGE')
      }}</span>
    </div>
    <div v-if="teams.length > 0" class="table-pagination">
      <ve-pagination
        :total="teams.length"
        :page-index="pageIndex"
        :page-size="25"
        :page-size-option="[25]"
      />
    </div>
  </div>
</template>

<script>
import { VeTable, VePagination } from 'vue-easytable';
import Spinner from 'shared/components/Spinner.vue';
import rtlMixin from 'shared/mixins/rtlMixin';

export default {
  name: 'TeamTable',
  components: {
    Spinner,
    VeTable,
    VePagination,
  },
  mixins: [rtlMixin],
  props: {
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
    pageIndex: {
      type: Number,
      default: 1,
    },
  },
  computed: {
    tableData() {
      return this.teams.map(team => {
        const teamMetrics = this.getTeamMetrics(team.id);
        return {
          agent: team.name,
          open: teamMetrics.open || 0,
          unattended: teamMetrics.unattended || 0,
        };
      });
    },
    columns() {
      return [
        {
          field: 'agent',
          key: 'agent',
          title: this.$t(
            'OVERVIEW_REPORTS.TEAM_CONVERSATIONS.TABLE_HEADER.AGENT'
          ),
          fixed: 'left',
          align: this.isRTLView ? 'right' : 'left',
          width: 25,
          renderBodyCell: ({ row }) => (
            <div class="row-user-block">
              <div class="user-block">
                <h6 class="capitalize title overflow-hidden whitespace-nowrap text-ellipsis">
                  {row.agent}
                </h6>
              </div>
            </div>
          ),
        },
        {
          field: 'open',
          key: 'open',
          title: this.$t(
            'OVERVIEW_REPORTS.TEAM_CONVERSATIONS.TABLE_HEADER.OPEN'
          ),
          align: this.isRTLView ? 'right' : 'left',
          width: 10,
        },
        {
          field: 'unattended',
          key: 'unattended',
          title: this.$t(
            'OVERVIEW_REPORTS.TEAM_CONVERSATIONS.TABLE_HEADER.UNATTENDED'
          ),
          align: this.isRTLView ? 'right' : 'left',
          width: 10,
        },
      ];
    },
  },
  methods: {
    getTeamMetrics(id) {
      return (
        this.teamMetrics.find(metrics => metrics.team_id === Number(id)) || {}
      );
    },
  },
};
</script>

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
