<template>
  <div class="flex-1 overflow-auto p-4">
    <woot-button
      color-scheme="success"
      class-names="button--fixed-top"
      icon="arrow-download"
      @click="downloadReports"
    >
      {{ downloadButtonLabel }}
    </woot-button>
    <report-filter-selector
      :show-agents-filter="false"
      :show-group-by-filter="false"
      @filter-change="onFilterChange"
    />
    <ve-table
      max-height="calc(100vh - 21.875rem)"
      :fixed-header="true"
      :columns="columns"
      :table-data="tableData"
    />
  </div>
</template>

<script>
import ReportFilterSelector from './FilterSelector.vue';
import { formatTime } from '@chatwoot/utils';

import reportMixin from '../../../../../mixins/reportMixin';
import { generateFileName } from '../../../../../helper/downloadHelper';
import { VeTable } from 'vue-easytable';

export default {
  components: {
    VeTable,
    ReportFilterSelector,
  },
  mixins: [reportMixin],
  props: {
    type: {
      type: String,
      default: 'account',
    },
    getterKey: {
      type: String,
      default: '',
    },
    actionKey: {
      type: String,
      default: '',
    },
    summaryKey: {
      type: String,
      default: '',
    },
    downloadButtonLabel: {
      type: String,
      default: 'Download Reports',
    },
  },
  data() {
    return {
      from: 0,
      to: 0,
      selectedFilter: null,
      businessHours: false,
    };
  },
  computed: {
    columns() {
      return [
        {
          field: 'agent',
          key: 'agent',
          title: this.type,
          fixed: 'left',
          align: this.isRTLView ? 'right' : 'left',
          width: 25,
          renderBodyCell: ({ row }) => (
            <div class="row-user-block">
              <div class="user-block">
                <h6 class="title overflow-hidden whitespace-nowrap text-ellipsis text-sm capitalize">
                  {row.name}
                </h6>
              </div>
            </div>
          ),
        },
        {
          field: 'conversationsCount',
          key: 'conversationsCount',
          title: 'Assigned',
          align: this.isRTLView ? 'right' : 'left',
          width: 20,
        },
        {
          field: 'resolutionsCount',
          key: 'resolutionsCount',
          title: 'Resolved',
          align: this.isRTLView ? 'right' : 'left',
          width: 20,
        },
        {
          field: 'avgFirstResponseTime',
          key: 'avgFirstResponseTime',
          title: 'Avg. first response time',
          align: this.isRTLView ? 'right' : 'left',
          width: 20,
        },
        {
          field: 'avgResolutionTime',
          key: 'avgResolutionTime',
          title: 'Avg. resolution time',
          align: this.isRTLView ? 'right' : 'left',
          width: 20,
        },
      ];
    },
    tableData() {
      return this.filterItemsList.map(team => {
        const typeMetrics = this.getMetrics(team.id);
        return {
          name: team.name,
          conversationsCount: typeMetrics.conversations_count || '--',
          avgFirstResponseTime:
            this.renderContent(typeMetrics.avg_first_response_time) || '--',
          avgResolutionTime:
            this.renderContent(typeMetrics.avg_resolution_time) || '--',
          resolutionsCount: typeMetrics.resolved_conversations_count || '--',
        };
      });
    },
    filterItemsList() {
      return this.$store.getters[this.getterKey] || [];
    },
    typeMetrics() {
      return this.$store.getters[this.summaryKey] || [];
    },
  },
  mounted() {
    this.fetchAllData();
  },
  methods: {
    renderContent(value) {
      return value ? formatTime(value) : '--';
    },
    getMetrics(id) {
      return this.typeMetrics.find(metrics => metrics.id === Number(id)) || {};
    },
    fetchAllData() {
      const { from, to, businessHours } = this;
      this.$store.dispatch(this.actionKey, {
        since: from,
        until: to,
        businessHours,
      });
    },
    downloadReports() {
      const { from, to, type, businessHours } = this;
      const dispatchMethods = {
        agent: 'downloadAgentReports',
        label: 'downloadLabelReports',
        inbox: 'downloadInboxReports',
        team: 'downloadTeamReports',
      };
      if (dispatchMethods[type]) {
        const fileName = generateFileName({ type, to, businessHours });
        const params = { from, to, fileName, businessHours };
        this.$store.dispatch(dispatchMethods[type], params);
      }
    },
    onFilterChange({ from, to, businessHours }) {
      this.from = from;
      this.to = to;
      this.businessHours = businessHours;
      this.fetchAllData();
    },
  },
};
</script>
