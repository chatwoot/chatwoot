<template>
  <div class="flex-1 overflow-auto">
    <div class="p-2">
      <report-filter-selector
        :show-business-hours-switch="false"
        :show-team-filter="true"
        @filter-change="onFilterChange"
      />
    </div>
    <div class="flex flex-col md:flex-row items-center">
      <div class="flex-1 w-full max-w-full md:w-[35%] md:max-w-[35%]">
        <metric-card
          :header="$t('CONTACT_REPORTS.CONVERSION_RATE.HEADER')"
          :is-loading="uiFlags.isFetchingAccountContactMetric"
          :loading-message="
            $t('CONTACT_REPORTS.CONVERSION_RATE.LOADING_MESSAGE')
          "
          :is-live="false"
        >
          <div
            v-for="(metric, name, index) in conversionMetrics"
            :key="index"
            class="metric-content flex-1 min-w-0"
          >
            <h3 class="heading">
              {{ name }}
            </h3>
            <p class="metric">{{ `${metric}%` }}</p>
          </div>
        </metric-card>
      </div>
      <div
        class="flex-1 w-full max-w-full md:w-[65%] md:max-w-[65%] conversation-metric"
      >
        <metric-card
          :header="$t('CONTACT_REPORTS.ACCOUNT_CONTACTS.HEADER')"
          :is-loading="uiFlags.isFetchingAccountContactMetric"
          :loading-message="
            $t('CONTACT_REPORTS.ACCOUNT_CONTACTS.LOADING_MESSAGE')
          "
          :is-live="false"
        >
          <div
            v-for="(metric, name, index) in contactMetrics"
            :key="index"
            class="metric-content flex-1 min-w-0"
          >
            <h3 class="heading">
              {{ name }}
            </h3>
            <p class="metric">{{ metric }}</p>
          </div>
        </metric-card>
      </div>
    </div>
    <div class="max-w-full flex flex-wrap flex-row ml-auto mr-auto">
      <metric-card
        :header="$t('CONTACT_REPORTS.AGENT_CONTACTS.HEADER')"
        :is-live="false"
      >
        <agent-table
          :agents="tableAgents"
          :stages="stages"
          :agent-metrics="tableAgentContactMetric"
          :page-index="pageIndex"
          :is-loading="uiFlags.isFetchingAgentContactMetric"
          @page-change="onPageNumberChange"
        />
      </metric-card>
    </div>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import AgentTable from './components/contact/AgentTable.vue';
import MetricCard from './components/overview/MetricCard.vue';
import ReportFilterSelector from './components/FilterSelector.vue';
import { REPORTS_EVENTS } from '../../../../helper/AnalyticsHelper/events';

export default {
  name: 'ContactReports',
  components: {
    ReportFilterSelector,
    AgentTable,
    MetricCard,
  },
  data() {
    return {
      pageIndex: 1,
      from: 0,
      to: 0,
      team: null,
    };
  },
  computed: {
    ...mapGetters({
      agents: 'agents/getAgents',
      stages: 'stages/getStages',
      accountContactMetric: 'getAccountContactMetric',
      agentContactMetric: 'getAgentContactMetric',
      uiFlags: 'getContactUIFlags',
    }),
    tableAgentContactMetric() {
      // Compact records
      return this.agentContactMetric.filter(
        rowData =>
          rowData.metric && !Object.values(rowData.metric).every(v => v === 0)
      );
    },
    tableAgents() {
      const displayAgentIds = this.tableAgentContactMetric.map(
        rowData => rowData.id
      );
      // Compact records
      return this.agents.filter(agent => displayAgentIds.includes(agent.id));
    },
    contactMetrics() {
      let metric = {};
      Object.keys(this.accountContactMetric).forEach(key => {
        const stage = this.stages.find(item => item.code === key);
        if (stage && !stage?.allow_disabled) {
          const metricName = stage.name;
          metric[metricName] = this.accountContactMetric[key];
        }
      });
      return metric;
    },
    conversionMetrics() {
      if (!this.stages || this.stages.length === 0) return null;

      let metric = {};

      const { wonFromNew, wonFromCare, totalFromNew, totalFromCare } =
        this.accountContactMetric;

      const newToWonName = `${this.stages.find(i => i.code === 'New').name} ->
        ${this.stages.find(i => i.code === 'Won').name}`;
      metric[newToWonName] =
        totalFromNew === 0 ? 0 : Math.round((wonFromNew / totalFromNew) * 100);

      const careToWonName = `${
        this.stages.find(i => i.code === 'Care').name
      } -> ${this.stages.find(i => i.code === 'Won').name}`;
      metric[careToWonName] =
        totalFromCare === 0
          ? 0
          : Math.round((wonFromCare / totalFromCare) * 100);

      return metric;
    },
  },
  mounted() {
    this.$store.dispatch('agents/get');
    this.$store.dispatch('stages/get');
    this.fetchAllData();
  },
  methods: {
    fetchAllData() {
      this.fetchAccountContactMetric();
      this.fetchAgentContactMetric();
    },
    fetchAccountContactMetric() {
      this.$store.dispatch('fetchAccountContactMetric', {
        type: 'account',
        from: this.from,
        to: this.to,
        team: this.team,
      });
    },
    fetchAgentContactMetric() {
      this.$store.dispatch('fetchAgentContactMetric', {
        type: 'agent',
        page: this.pageIndex,
        from: this.from,
        to: this.to,
        team: this.team,
      });
    },
    onPageNumberChange(pageIndex) {
      this.pageIndex = pageIndex;
      this.fetchAgentContactMetric();
    },
    onFilterChange({ from, to, selectedTeam }) {
      this.from = from;
      this.to = to;
      this.team = selectedTeam;
      this.fetchAllData();

      this.$track(REPORTS_EVENTS.FILTER_REPORT, {
        filterValue: { from, to, selectedTeam },
        reportType: 'conversion',
      });
    },
  },
};
</script>
