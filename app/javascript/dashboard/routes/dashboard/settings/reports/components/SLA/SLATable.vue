<template>
  <div>
    <div
      class="min-w-full border rounded-xl border-slate-75 dark:border-slate-700/50"
    >
      <!-- Header -->
      <div
        class="grid content-center h-12 grid-cols-12 gap-4 px-6 py-0 border-b bg-slate-25 border-slate-75 dark:border-slate-800 rounded-t-xl dark:bg-slate-900"
      >
        <div
          class="flex items-center col-span-6 px-0 py-2 text-xs font-medium text-left uppercase text-slate-700 dark:text-slate-100 rtl:text-right"
        >
          {{ $t('SLA_REPORTS.TABLE.HEADER.CONVERSATION') }}
        </div>
        <div
          class="flex items-center font-medium text-xs py-2 px-0 tracking-[10%] text-slate-700 dark:text-slate-100 text-left rtl:text-right uppercase col-span-2"
        >
          {{ $t('SLA_REPORTS.TABLE.HEADER.POLICY_BREACHED') }}
        </div>
        <div
          class="flex items-center px-0 text-xs font-medium text-left uppercase col-span-2py-2 text-slate-700 dark:text-slate-100 rtl:text-right"
        >
          {{ $t('SLA_REPORTS.TABLE.HEADER.AGENT') }}
        </div>
        <div
          class="col-span-2 px-0 py-2 text-xs font-medium text-left uppercase text-slate-700 dark:text-slate-100 rtl:text-right"
        />
      </div>

      <div
        v-if="isLoading"
        class="flex items-center justify-center h-32 bg-white dark:bg-slate-900"
      >
        <spinner />
        <span>{{ $t('SLA_REPORTS.LOADING') }}</span>
      </div>
      <div v-else-if="slaReports.length > 0">
        <SLA-report-item
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
        class="flex items-center justify-center h-32 bg-white dark:bg-slate-900"
      >
        {{ $t('SLA_REPORTS.NO_RECORDS') }}
      </div>
    </div>
    <table-footer
      v-if="shouldShowFooter"
      :current-page="currentPage"
      :total-count="totalCount"
      :page-size="pageSize"
      class="bg-slate-25 dark:bg-slate-900 sticky bottom-0 border-none mt-4"
      @page-change="onPageChange"
    />
  </div>
</template>

<script>
import TableFooter from 'dashboard/components/widgets/TableFooter.vue';
import SLAReportItem from './SLAReportItem.vue';
import Spinner from 'shared/components/Spinner.vue';
export default {
  name: 'SLATable',
  components: {
    SLAReportItem,
    TableFooter,
    Spinner,
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
      this.$emit('page-change', page);
    },
  },
};
</script>
