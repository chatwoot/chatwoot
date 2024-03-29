<template>
  <div>
    <div
      class="min-w-full border rounded-xl border-slate-75 dark:border-slate-800/50"
    >
      <!-- Header -->
      <div
        class="grid content-center h-12 grid-cols-12 gap-4 px-6 py-0 border-b bg-slate-25 border-slate-75 dark:border-slate-800 rounded-t-xl dark:bg-slate-900"
      >
        <div
          class="flex items-center font-medium capitalize text-xs py-2 px-0 tracking-[10%] text-slate-700 dark:text-slate-100 text-left rtl:text-right col-span-2"
        >
          POLICY BREACHED
        </div>
        <div
          class="flex items-center col-span-6 px-0 py-2 text-xs font-medium text-left capitalize text-slate-700 dark:text-slate-100 rtl:text-right"
        >
          CONVERSATION
        </div>
        <div
          class="flex items-center px-0 text-xs font-medium text-left capitalize col-span-2py-2 text-slate-700 dark:text-slate-100 rtl:text-right"
        >
          AGENT
        </div>
        <div
          class="col-span-2 px-0 py-2 text-xs font-medium text-left capitalize text-slate-700 dark:text-slate-100 rtl:text-right"
        />
      </div>
      <SLA-report-item
        v-for="sla in slaReports"
        :key="sla.id"
        :sla-name="sla.sla_policy.name"
        :conversation="sla.conversation"
        :conversation-id="sla.conversation_id"
      />
    </div>
    <table-footer
      v-if="shouldShowFooter"
      :current-page="currentPage"
      :total-count="totalCount"
      :page-size="pageSize"
      class="dark:bg-slate-900 sticky bottom-0"
      @page-change="onPageChange"
    />
  </div>
</template>

<script>
import TableFooter from 'dashboard/components/widgets/TableFooter.vue';
import SLAReportItem from './SLAReportItem.vue';
export default {
  name: 'SLATable',
  components: {
    SLAReportItem,
    TableFooter,
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
