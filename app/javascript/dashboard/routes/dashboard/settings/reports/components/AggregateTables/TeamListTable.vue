<template>
  <div class="agent-table-container">
    <ve-table
      max-height="calc(100vh - 21.875rem)"
      :fixed-header="true"
      :columns="columns"
      :table-data="tableData"
    />
  </div>
</template>

<script>
import { VeTable } from 'vue-easytable';
import rtlMixin from 'shared/mixins/rtlMixin';
import { mapGetters } from 'vuex';

export default {
  name: 'TeamTable',
  components: {
    VeTable,
  },
  mixins: [rtlMixin],
  computed: {
    ...mapGetters({
      teams: 'teams/getTeams',
      teamMetrics: 'summaryReports/getTeamSummaryReports',
    }),

    columns() {
      return [
        {
          field: 'agent',
          key: 'agent',
          title: 'Team',
          fixed: 'left',
          align: this.isRTLView ? 'right' : 'left',
          width: 25,
          renderBodyCell: ({ row }) => (
            <div class="row-user-block">
              <div class="user-block">
                <h6 class="title overflow-hidden whitespace-nowrap text-ellipsis">
                  {row.name}
                </h6>
              </div>
            </div>
          ),
        },
        {
          field: 'conversationsCount',
          key: 'conversationsCount',
          title: 'No. of conversations',
          align: this.isRTLView ? 'right' : 'left',
          width: 20,
        },
        {
          field: 'resolutionsCount',
          key: 'resolutionsCount',
          title: 'No. of resolved conversations',
          align: this.isRTLView ? 'right' : 'left',
          width: 20,
        },
        {
          field: 'avgFirstResponseTime',
          key: 'avgFirstResponseTime',
          title: 'Average first response time',
          align: this.isRTLView ? 'right' : 'left',
          width: 20,
        },
        {
          field: 'avgResolutionTime',
          key: 'avgResolutionTime',
          title: 'Average resolution time',
          align: this.isRTLView ? 'right' : 'left',
          width: 20,
        },
      ];
    },
  },
  mounted() {
    this.$store.dispatch('summaryReports/fetchTeamSummaryReports');
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
