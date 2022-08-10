<template>
  <div class="agent-table-container">
    <ve-table
      max-height="calc(100vh - 35rem)"
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
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';

export default {
  name: 'AgentTable',
  components: {
    EmptyState,
    Spinner,
    VeTable,
    VePagination,
  },
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
      return this.agentMetrics.map(agent => {
        const agentInformation = this.getAgentInformation(agent.id);
        return {
          agent: agentInformation.name,
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
          align: 'left',
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
                <h6 class="title text-truncate">{row.agent}</h6>
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
          align: 'left',
          width: 10,
        },
        {
          field: 'unattended',
          key: 'unattended',
          title: this.$t(
            'OVERVIEW_REPORTS.AGENT_CONVERSATIONS.TABLE_HEADER.UNATTENDED'
          ),
          align: 'left',
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
      return this.agents.find(agent => agent.id === Number(id));
    },
  },
};
</script>

<style lang="scss" scoped>
.agent-table-container {
  display: flex;
  flex-direction: column;
  flex: 1;

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
    background-color: transparent;
  }

  &::v-deep .ve-pagination-select {
    display: none;
  }

  .row-user-block {
    align-items: center;
    display: flex;
    text-align: left;

    .user-block {
      display: flex;
      flex-direction: column;
      min-width: 0;
      .title {
        font-size: var(--font-size-small);
        margin: var(--zero);
        line-height: 1;
      }
      .sub-title {
        font-size: var(--font-size-mini);
      }
    }

    .user-thumbnail-box {
      margin-right: var(--space-small);
    }
  }

  .table-pagination {
    margin-top: var(--space-normal);
    text-align: right;
  }
}

.agents-loader {
  align-items: center;
  display: flex;
  font-size: var(--font-size-default);
  justify-content: center;
  padding: var(--space-large);
}
</style>
