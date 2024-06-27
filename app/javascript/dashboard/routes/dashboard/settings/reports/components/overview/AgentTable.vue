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
        $t('OVERVIEW_REPORTS.AGENT_CONVERSATIONS.LOADING_MESSAGE')
      }}</span>
    </div>
    <empty-state
      v-else-if="!isLoading && !agentMetrics.length"
      :title="$t('OVERVIEW_REPORTS.AGENT_CONVERSATIONS.NO_AGENTS')"
    />
    <div v-if="agentMetrics.length > 0" class="table-pagination">
      <ve-pagination
        :total="agents.length"
        :page-index="pageIndex"
        :page-size="25"
        :page-size-option="[25]"
        @on-page-number-change="onPageNumberChange"
      />
    </div>
  </div>
</template>

<script>
import { VeTable, VePagination } from 'vue-easytable';
import Spinner from 'shared/components/Spinner.vue';
import EmptyState from 'dashboard/components/widgets/EmptyState.vue';
import rtlMixin from 'shared/mixins/rtlMixin';
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';

export default {
  name: 'AgentTable',
  components: {
    EmptyState,
    Spinner,
    VeTable,
    VePagination,
  },
  mixins: [rtlMixin],
  props: {
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
  },
  computed: {
    tableData() {
      return this.agentMetrics
        .filter(agentMetric => this.getAgentInformation(agentMetric.id))
        .map(agent => {
          const agentInformation = this.getAgentInformation(agent.id);
          return {
            agent: agentInformation.name || agentInformation.available_name,
            email: agentInformation.email,
            thumbnail: agentInformation.thumbnail,
            open: agent.metric.open || 0,
            unattended: agent.metric.unattended || 0,
            status: agentInformation.availability_status,
          };
        });
    },
    columns() {
      return [
        {
          field: 'agent',
          key: 'agent',
          title: this.$t(
            'OVERVIEW_REPORTS.AGENT_CONVERSATIONS.TABLE_HEADER.AGENT'
          ),
          fixed: 'left',
          align: this.isRTLView ? 'right' : 'left',
          width: 25,
          renderBodyCell: ({ row }) => (
            <div class="row-user-block">
              <Thumbnail
                src={row.thumbnail}
                size="32px"
                username={row.agent}
                status={row.status}
              />
              <div class="user-block">
                <h6 class="title overflow-hidden whitespace-nowrap text-ellipsis">
                  {row.agent}
                </h6>
                <span class="sub-title">{row.email}</span>
              </div>
            </div>
          ),
        },
        {
          field: 'open',
          key: 'open',
          title: this.$t(
            'OVERVIEW_REPORTS.AGENT_CONVERSATIONS.TABLE_HEADER.OPEN'
          ),
          align: this.isRTLView ? 'right' : 'left',
          width: 10,
        },
        {
          field: 'unattended',
          key: 'unattended',
          title: this.$t(
            'OVERVIEW_REPORTS.AGENT_CONVERSATIONS.TABLE_HEADER.UNATTENDED'
          ),
          align: this.isRTLView ? 'right' : 'left',
          width: 10,
        },
      ];
    },
  },
  methods: {
    onPageNumberChange(pageIndex) {
      this.$emit('page-change', pageIndex);
    },
    getAgentInformation(id) {
      return this.agents?.find(agent => agent.id === Number(id));
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
