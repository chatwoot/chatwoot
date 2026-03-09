<script>
import V4Button from 'dashboard/components-next/button/Button.vue';
import { useAlert } from 'dashboard/composables';
import ReportFilters from './ReportFilters.vue';
import ReportContainer from '../ReportContainer.vue';
import { GROUP_BY_FILTER } from '../constants';
import { generateFileName } from '../../../../../helper/downloadHelper';
import ReportHeader from './ReportHeader.vue';

export default {
  components: {
    ReportHeader,
    V4Button,
    ReportFilters,
    ReportContainer,
  },
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
    downloadButtonLabel: {
      type: String,
      default: 'Download Reports',
    },
    reportTitle: {
      type: String,
      default: 'Download Reports',
    },
    hasBackButton: {
      type: Boolean,
      default: false,
    },
    selectedItem: {
      type: Object,
      default: null,
    },
  },
  data() {
    return {
      from: 0,
      to: 0,
      selectedFilter: this.selectedItem,
      groupBy: GROUP_BY_FILTER[1],
      businessHours: false,
    };
  },
  computed: {
    filterType() {
      const pluralMap = {
        agent: 'agents',
        team: 'teams',
        inbox: 'inboxes',
        label: 'labels',
      };
      return pluralMap[this.type] || this.type;
    },
    filterItemsList() {
      return this.$store.getters[this.getterKey] || [];
    },
    isAgentType() {
      return this.type === 'agent';
    },
    reportKeys() {
      return {
        CONVERSATIONS: 'conversations_count',
        ...(!this.isAgentType && {
          INCOMING_MESSAGES: 'incoming_messages_count',
        }),
        OUTGOING_MESSAGES: 'outgoing_messages_count',
        FIRST_RESPONSE_TIME: 'avg_first_response_time',
        RESOLUTION_TIME: 'avg_resolution_time',
        RESOLUTION_COUNT: 'resolutions_count',
        REPLY_TIME: 'reply_time',
      };
    },
  },
  mounted() {
    this.$store.dispatch(this.actionKey);
  },
  methods: {
    fetchAllData() {
      if (this.selectedFilter) {
        const { from, to, groupBy, businessHours } = this;
        this.$store.dispatch('fetchAccountSummary', {
          from,
          to,
          type: this.type,
          id: this.selectedFilter.id,
          groupBy: groupBy.period,
          businessHours,
        });
        this.fetchChartData();
      }
    },
    fetchChartData() {
      Object.keys(this.reportKeys).forEach(async key => {
        try {
          const { from, to, groupBy, businessHours } = this;
          this.$store.dispatch('fetchAccountReport', {
            metric: this.reportKeys[key],
            from,
            to,
            type: this.type,
            id: this.selectedFilter.id,
            groupBy: groupBy.period,
            businessHours,
          });
        } catch {
          useAlert(this.$t('REPORT.DATA_FETCHING_FAILED'));
        }
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
    onFilterChange(payload) {
      const { from, to, businessHours, groupBy } = payload;
      this.from = from;
      this.to = to;
      this.businessHours = businessHours;

      if (groupBy) {
        this.groupBy = groupBy;
      } else {
        this.groupBy = GROUP_BY_FILTER[1];
      }

      // Get filter value directly from filterType key
      const filterValue = payload[this.filterType];
      if (filterValue) {
        this.selectedFilter = Array.isArray(filterValue)
          ? filterValue[0]
          : filterValue;
      } else {
        this.selectedFilter = null;
      }

      this.fetchAllData();
    },
  },
};
</script>

<template>
  <ReportHeader :header-title="reportTitle" :has-back-button="hasBackButton">
    <V4Button
      :label="downloadButtonLabel"
      icon="i-ph-download-simple"
      size="sm"
      @click="downloadReports"
    />
  </ReportHeader>

  <ReportFilters
    v-if="filterItemsList"
    :filter-type="filterType"
    :selected-item="selectedFilter"
    @filter-change="onFilterChange"
  />
  <ReportContainer
    v-if="filterItemsList.length"
    :group-by="groupBy"
    :report-keys="reportKeys"
  />
</template>
