<template>
  <div class="flex-1 overflow-auto">
    <div class="p-2">
      <report-filter-selector
        :show-agents-filter="false"
        :show-group-by-filter="false"
        :show-business-hours-switch="false"
        @filter-change="onFilterChange"
      />
    </div>

    <div class="max-w-full flex flex-wrap flex-row ml-auto mr-auto">
      <div class="w-full max-w-full md:w-[50%] md:max-w-[50%]">
        <conversion-metric-card
          :header="$t('CONVERSION_REPORTS.TEAM_CONVERSIONS.HEADER')"
          :is-loading="uiFlags.isFetchingAccountConversationMetric"
          :loading-message="
            $t('CONVERSION_REPORTS.TEAM_CONVERSIONS.LOADING_MESSAGE')
          "
        >
          <conversion-table
            :resources="teams"
            :conversion-metrics="teamConversionMetric"
            criteria-key="team"
            :page-index="teamPageIndex"
            :is-loading="uiFlags.isFetchingTeamConversionMetric"
            @page-change="onTeamPageNumberChange"
          />
        </conversion-metric-card>
      </div>

      <div class="w-full max-w-full md:w-[50%] md:max-w-[50%]">
        <conversion-metric-card
          :header="$t('CONVERSION_REPORTS.DATA_SOURCE_CONVERSIONS.HEADER')"
          :is-loading="uiFlags.isFetchingAccountConversationMetric"
          :loading-message="
            $t('CONVERSION_REPORTS.DATA_SOURCE_CONVERSIONS.LOADING_MESSAGE')
          "
        >
          <conversion-table
            :resources="dataSources"
            :conversion-metrics="dataSourceConversionMetric"
            criteria-key="data_source"
            :page-index="dataSourcePageIndex"
            :is-loading="uiFlags.isFetchingDataSourceConversionMetric"
            @page-change="onDataSourcePageNumberChange"
          />
        </conversion-metric-card>
      </div>

      <div class="w-full max-w-full md:w-[50%] md:max-w-[50%]">
        <conversion-metric-card
          :header="$t('CONVERSION_REPORTS.AGENT_CONVERSIONS.HEADER')"
          :is-loading="uiFlags.isFetchingAccountConversationMetric"
          :loading-message="
            $t('CONVERSION_REPORTS.AGENT_CONVERSIONS.LOADING_MESSAGE')
          "
        >
          <conversion-table
            :resources="agents"
            :conversion-metrics="agentConversionMetric"
            criteria-key="agent"
            :page-index="agentPageIndex"
            :is-loading="uiFlags.isFetchingAgentConversionMetric"
            @page-change="onAgentPageNumberChange"
          />
        </conversion-metric-card>
      </div>

      <div class="w-full max-w-full md:w-[50%] md:max-w-[50%]">
        <conversion-metric-card
          :header="$t('CONVERSION_REPORTS.INBOX_CONVERSIONS.HEADER')"
          :is-loading="uiFlags.isFetchingAccountConversationMetric"
          :loading-message="
            $t('CONVERSION_REPORTS.INBOX_CONVERSIONS.LOADING_MESSAGE')
          "
        >
          <conversion-table
            :resources="inboxes"
            :conversion-metrics="inboxConversionMetric"
            criteria-key="inbox"
            :page-index="inboxPageIndex"
            :is-loading="uiFlags.isFetchingInboxConversionMetric"
            @page-change="onInboxPageNumberChange"
          />
        </conversion-metric-card>
      </div>
    </div>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import ReportFilterSelector from './components/FilterSelector.vue';
import { REPORTS_EVENTS } from '../../../../helper/AnalyticsHelper/events';
import alertMixin from 'shared/mixins/alertMixin';
import ConversionMetricCard from './components/conversion/ConversionMetricCard.vue';
import camelCase from 'camelcase';
import ConversionTable from './components/conversion/ConversionTable.vue';

export default {
  name: 'ConversionReports',
  components: {
    ConversionTable,
    ConversionMetricCard,
    ReportFilterSelector,
  },
  mixins: [alertMixin],
  data() {
    return {
      teamPageIndex: 1,
      dataSourcePageIndex: 1,
      agentPageIndex: 1,
      inboxPageIndex: 1,
      from: 0,
      to: 0,
    };
  },
  computed: {
    ...mapGetters({
      teams: 'teams/getTeams',
      inboxes: 'inboxes/getInboxes',
      agents: 'agents/getAgents',
      dataSources: 'attributes/getAttributeValuesForDataSource',
      teamConversionMetric: 'getTeamConversionMetric',
      dataSourceConversionMetric: 'getDataSourceConversionMetric',
      agentConversionMetric: 'getAgentConversionMetric',
      inboxConversionMetric: 'getInboxConversionMetric',
      uiFlags: 'getConversionUIFlags',
    }),
  },
  mounted() {
    this.$store.dispatch('teams/get');
    this.$store.dispatch('attributes/get');
    this.$store.dispatch('agents/get');
    this.$store.dispatch('inboxes/get');
    this.$store.dispatch('attributes/getDataSourceValues');
    this.fetchTablesData();
  },
  methods: {
    fetchTablesData(criteriaKeys = ['TEAM', 'DATA_SOURCE', 'AGENT', 'INBOX']) {
      criteriaKeys.forEach(async key => {
        try {
          const pascalKey = camelCase(key, { pascalCase: true });
          await this.$store.dispatch(`fetch${pascalKey}ConversionReport`, {
            criteria_type: key.toLowerCase(),
            ...this.getRequestPayload(key),
          });
        } catch {
          this.showAlert(this.$t('REPORT.DATA_FETCHING_FAILED'));
        }
      });
    },
    getRequestPayload(criteriaKey) {
      const { from, to } = this;
      const getPageIndex = key => {
        switch (key) {
          case 'TEAM':
            return this.teamPageIndex;
          case 'DATA_SOURCE':
            return this.dataSourcePageIndex;
          case 'AGENT':
            return this.agentPageIndex;
          case 'INBOX':
            return this.inboxPageIndex;
          default:
            return 1;
        }
      };
      return {
        from,
        to,
        page: getPageIndex(criteriaKey),
      };
    },
    onTeamPageNumberChange(pageIndex) {
      this.teamPageIndex = pageIndex;
      this.fetchTablesData(['TEAM']);
    },
    onDataSourcePageNumberChange(pageIndex) {
      this.dataSourcePageIndex = pageIndex;
      this.fetchTablesData(['DATA_SOURCE']);
    },
    onAgentPageNumberChange(pageIndex) {
      this.agentPageIndex = pageIndex;
      this.fetchTablesData(['AGENT']);
    },
    onInboxPageNumberChange(pageIndex) {
      this.inboxPageIndex = pageIndex;
      this.fetchTablesData(['INBOX']);
    },
    onFilterChange({ from, to }) {
      this.from = from;
      this.to = to;
      this.fetchTablesData();

      this.$track(REPORTS_EVENTS.FILTER_REPORT, {
        filterValue: { from, to },
        reportType: 'conversion',
      });
    },
  },
};
</script>
