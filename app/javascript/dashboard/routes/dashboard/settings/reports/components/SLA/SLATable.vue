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
  <div class="w-full">
    <div class="rounded-xl overflow-hidden border border-n-weak bg-n-solid-2 w-full">
      <!-- HEADER (APENAS UMA VEZ) -->
      <div
        class="grid grid-cols-[2fr_1.5fr_1.5fr_1.8fr_2fr_2fr_2fr_1fr] gap-x-6 px-10 h-16 items-center text-xs font-medium text-n-slate-11 bg-n-slate-2 border-b border-n-weak"
      >
        <div>{{ $t('SLA_REPORTS.TABLE.HEADER.CONVERSATION') }}</div>
        <div>{{ $t('SLA_REPORTS.TABLE.HEADER.POLICY') }}</div>
        <div>{{ $t('SLA_REPORTS.TABLE.HEADER.AGENT') }}</div>
        <div>{{ $t('SLA_REPORTS.TABLE.HEADER.SLA_START') }}</div>
        <div>{{ $t('SLA_REPORTS.TABLE.HEADER.FRT') }}</div>
        <div>{{ $t('SLA_REPORTS.TABLE.HEADER.NRT') }}</div>
        <div>{{ $t('SLA_REPORTS.TABLE.HEADER.RT') }}</div>
        <div></div>
      </div>

      <!-- LOADING STATE -->
      <div v-if="isLoading" class="flex items-center justify-center h-32 gap-2">
        <Spinner />
        <span>{{ $t('SLA_REPORTS.LOADING') }}</span>
      </div>

      <!-- ROWS -->
      <SLAReportItem
        v-else-if="slaReports.length > 0"
        v-for="slaReport in slaReports"
        :key="slaReport.applied_sla.id"
        :sla-name="slaReport.applied_sla.sla_name"
        :conversation="slaReport.conversation"
        :conversation-id="slaReport.conversation.id"
        :sla-events="slaReport.sla_events"
        :applied-sla="slaReport.applied_sla"
      />

      <!-- EMPTY STATE -->
      <div v-else class="flex items-center justify-center h-32">
        {{ $t('SLA_REPORTS.NO_RECORDS') }}
      </div>
    </div>

    <!-- FOOTER -->
    <TableFooter
      v-if="shouldShowFooter"
      :current-page="currentPage"
      :total-count="totalCount"
      :page-size="pageSize"
      @page-change="onPageChange"
    />
  </div>
</template>
