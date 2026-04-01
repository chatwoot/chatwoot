<script>
import TableFooter from 'dashboard/components/widgets/TableFooter.vue';
import TableHeaderCell from 'dashboard/components/widgets/TableHeaderCell.vue';
import SLAReportItem from './SLAReportItem.vue';
import Spinner from 'shared/components/Spinner.vue';
export default {
  name: 'SLATable',
  components: {
    SLAReportItem,
    TableFooter,
    Spinner,
    TableHeaderCell,
  },
  props: {
    slaReports: {
      type: Array,
      default: () => [],
    },
    totalCount: {
      type: Number,
      default: 0,
    },
    currentPage: {
      type: Number,
      default: 1,
    },
    pageSize: {
      type: Number,
      default: 25,
    },
    isLoading: {
      type: Boolean,
      default: false,
    },
  },
  emits: ['pageChange'],
  data() {
    return {
      pageNo: 1,
    };
  },
  computed: {
    shouldShowFooter() {
      return this.currentPage === 1
        ? this.totalCount > this.pageSize
        : this.slaReports.length > 0;
    },
  },
  methods: {
    onPageChange(page) {
      this.$emit('pageChange', page);
    },
  },
};
</script>

<template>
  <div>
    <div
      class="min-w-full rounded-xl border border-outline-variant/10 bg-surface-container p-6 shadow-lg"
    >
      <div
        class="grid h-12 grid-cols-12 content-center gap-4 rounded-lg border-b border-outline-variant/15 bg-surface-container px-6 py-0"
      >
        <TableHeaderCell
          :span="6"
          :label="$t('SLA_REPORTS.TABLE.HEADER.CONVERSATION')"
        />
        <TableHeaderCell
          :span="2"
          :label="$t('SLA_REPORTS.TABLE.HEADER.POLICY')"
        />
        <TableHeaderCell
          :span="2"
          :label="$t('SLA_REPORTS.TABLE.HEADER.AGENT')"
        />
        <TableHeaderCell :span="1" label="" />
      </div>

      <div
        v-if="isLoading"
        class="flex h-32 items-center justify-center gap-2 text-on-surface-variant"
      >
        <Spinner />
        <span>{{ $t('SLA_REPORTS.LOADING') }}</span>
      </div>
      <div v-else-if="slaReports.length > 0">
        <SLAReportItem
          v-for="slaReport in slaReports"
          :key="slaReport.applied_sla.id"
          :sla-name="slaReport.applied_sla.sla_name"
          :conversation="slaReport.conversation"
          :conversation-id="slaReport.conversation.id"
          :sla-events="slaReport.sla_events"
        />
      </div>
      <div
        v-else
        class="flex h-32 items-center justify-center text-sm text-on-surface-variant"
      >
        {{ $t('SLA_REPORTS.NO_RECORDS') }}
      </div>
    </div>
    <TableFooter
      v-if="shouldShowFooter"
      :current-page="currentPage"
      :total-count="totalCount"
      :page-size="pageSize"
      @page-change="onPageChange"
    />
  </div>
</template>
