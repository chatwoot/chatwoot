<template>
  <div class="ticket-agents-table-container">
    <ve-table
      max-height="calc(100vh - 21.875rem)"
      :fixed-header="true"
      :columns="columns"
      :table-data="tableData"
    />
    <div
      v-if="ticketsUIFlags.isFetching"
      class="flex flex-col items-center justify-center p-8 gap-4"
    >
      <spinner color-scheme="primary" size="large" />
      <span>{{
        $t('TICKETS_REPORTS.AGENT_CONVERSATIONS.LOADING_MESSAGE')
      }}</span>
    </div>
    <empty-state
      v-else-if="!ticketsUIFlags.isFetching && tableData.length === 0"
      :title="$t('TICKETS_REPORTS.EMPTY_STATE')"
      :message="$t('TICKETS_REPORTS.AGENT_CONVERSATIONS.NO_AGENTS')"
    />
    <div v-if="tableData.length > 0" class="table-pagination">
      <ve-pagination
        :total="tableData.length"
        :page-index="pageIndex"
        :page-size="25"
        :page-size-option="[25]"
        @on-page-number-change="onPageNumberChange"
      />
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import { VeTable, VePagination } from 'vue-easytable';
import Spinner from 'shared/components/Spinner.vue';
import EmptyState from 'dashboard/components/widgets/EmptyState.vue';
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import rtlMixin from 'shared/mixins/rtlMixin';

export default {
  name: 'TicketAgentsTableComponent',
  components: {
    VeTable,
    VePagination,
    Spinner,
    EmptyState,
  },
  mixins: [rtlMixin],
  props: {
    accountId: {
      type: Number,
      required: true,
    },
    from: {
      type: Number,
      required: true,
    },
    to: {
      type: Number,
      required: true,
    },
  },
  data: () => ({
    isLoading: false,
    pageIndex: 1,
  }),
  computed: {
    ...mapGetters({
      ticketAgents: 'ticketsReport/getTicketsAgentsReport',
      ticketsUIFlags: 'ticketsReport/getUIFlags',
    }),
    tableData() {
      return this.ticketAgents;
    },
    columns() {
      return [
        {
          field: 'agent',
          key: 'agent',
          title: this.$t(
            'TICKETS_REPORTS.AGENT_CONVERSATIONS.TABLE_HEADER.AGENT'
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
          field: 'resolved',
          key: 'resolved',
          title: this.$t(
            'TICKETS_REPORTS.AGENT_CONVERSATIONS.TABLE_HEADER.OPEN'
          ),
          align: this.isRTLView ? 'right' : 'left',
          width: 10,
        },
        {
          field: 'unresolved',
          key: 'unresolved',
          title: this.$t(
            'TICKETS_REPORTS.AGENT_CONVERSATIONS.TABLE_HEADER.UNATTENDED'
          ),
          align: this.isRTLView ? 'right' : 'left',
          width: 10,
        },
      ];
    },
  },
  mounted() {
    this.fetchAllData();
  },
  methods: {
    onPageNumberChange(pageIndex) {
      this.pageIndex = pageIndex;
    },
    async fetchAllData() {
      const { from, to } = this;
      const payload = { from, to };

      await this.$store.dispatch('ticketsReport/getAll', payload);
    },
  },
};
</script>

<style lang="scss" scoped>
.ticket-agents-table-container {
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
</style>
