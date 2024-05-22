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
      <span>{{ $t('CONTACT_REPORTS.AGENT_CONTACTS.LOADING_MESSAGE') }}</span>
    </div>
    <empty-state
      v-else-if="!isLoading && !agentMetrics.length"
      :title="$t('CONTACT_REPORTS.AGENT_CONTACTS.NO_AGENTS')"
    />
    <div v-if="agentMetrics.length > 0" class="table-pagination">
      <ve-pagination
        :total="agents.length"
        :page-index="pageIndex"
        :page-size="10"
        :page-size-option="[10]"
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
    stages: {
      type: Array,
      default: () => [],
    },
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
        const data = {
          agent: agentInformation.name,
          email: agentInformation.email,
          thumbnail: agentInformation.thumbnail,
          status: agentInformation.availability_status,
        };
        let total = 0;
        this.stages.forEach(stage => {
          data[stage.code] = agent.metric[stage.code] || 0;
          total += data[stage.code];
        });
        data.conversionRate = Math.round((data.Won / total) * 100);
        return data;
      });
    },
    columns() {
      const columns = [
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
      ];
      this.stages.forEach(stage => {
        if (!stage.allow_disabled)
          columns.push({
            field: stage.code,
            key: stage.code,
            title: stage.name,
            align: this.isRTLView ? 'right' : 'left',
            width: 10,
          });
      });
      columns.push({
        field: 'conversionRate',
        key: 'conversionRate',
        title: this.$t(
          'OVERVIEW_REPORTS.AGENT_CONVERSATIONS.TABLE_HEADER.CONVERSATION'
        ),
        align: this.isRTLView ? 'right' : 'left',
        width: 10,
      });
      return columns;
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
