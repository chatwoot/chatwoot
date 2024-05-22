<template>
  <div class="w-full flex flex-col">
    <header
      class="bg-white dark:bg-slate-900 border-b border-slate-50 dark:border-slate-800"
    >
      <div class="flex justify-between w-full py-2 px-4">
        <div
          class="flex items-center justify-center max-w-full min-w-[6.25rem]"
        >
          <woot-sidemenu-icon />
          <h1
            class="m-0 text-xl text-slate-900 dark:text-slate-100 overflow-hidden whitespace-nowrap text-ellipsis my-0 mx-2"
          >
            Bảng điều khiển
          </h1>
        </div>
      </div>
    </header>
    <div class="flex-1 overflow-auto">
      <div class="flex flex-col md:flex-row items-center">
        <div class="flex-1 w-full max-w-full md:w-[35%] md:max-w-[35%]">
          <metric-card
            :header="$t('CONTACT_REPORTS.CONVERSION_RATE.HEADER')"
            :is-loading="uiFlags.isFetchingAgentContactMetric"
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
            :is-loading="uiFlags.isFetchingAgentContactMetric"
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
      <div class="flex flex-col md:flex-row items-center">
        <div
          class="flex-1 w-full max-w-full md:w-[65%] md:max-w-[65%] conversation-metric"
        >
          <metric-card
            :header="$t('OVERVIEW_REPORTS.ACCOUNT_CONVERSATIONS.HEADER')"
            :is-loading="uiFlags.isFetchingAgentConversationMetric"
            :loading-message="
              $t('OVERVIEW_REPORTS.ACCOUNT_CONVERSATIONS.LOADING_MESSAGE')
            "
          >
            <div
              v-for="(metric, name, index) in conversationMetrics"
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
        <div class="flex-1 w-full max-w-full md:w-[35%] md:max-w-[35%]">
          <metric-card :header="$t('OVERVIEW_REPORTS.AGENT_PLAN.HEADER')">
            <div
              v-for="(metric, name, index) in plannedMetrics"
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
    </div>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import { OVERVIEW_METRICS, AGENT_PLAN } from './constants';
import MetricCard from './components/overview/MetricCard.vue';

export default {
  name: 'AgentDashboard',
  components: {
    MetricCard,
  },
  data() {
    return {
      showDate: new Date(),
    };
  },
  computed: {
    ...mapGetters({
      agents: 'agents/getAgents',
      stages: 'stages/getStages',
      agentContactMetric: 'getAgentDashboardContactMetric',
      agentConversationMetric: 'getAgentDashboardConversationMetric',
      agentPlannedMetric: 'getAgentDashboardPlannedMetric',
      agentCalendarItems: 'getAgentDashboardCalendarItems',
      uiFlags: 'getAgentDashboardUIFlags',
    }),
    contactMetrics() {
      let metric = {};
      Object.keys(this.agentContactMetric).forEach(key => {
        const stage = this.stages.find(item => item.code === key);
        if (!stage.allow_disabled) {
          const metricName = stage.name;
          metric[metricName] = this.agentContactMetric[key];
        }
      });
      return metric;
    },
    conversationMetrics() {
      let metric = {};
      Object.keys(this.agentConversationMetric).forEach(key => {
        const metricName = this.$t(
          `OVERVIEW_REPORTS.ACCOUNT_CONVERSATIONS.${OVERVIEW_METRICS[key]}`
        );
        metric[metricName] = this.agentConversationMetric[key];
      });
      return metric;
    },
    plannedMetrics() {
      let metric = {};
      Object.keys(this.agentPlannedMetric).forEach(key => {
        const metricName = this.$t(
          `OVERVIEW_REPORTS.AGENT_PLAN.${AGENT_PLAN[key]}`
        );
        metric[metricName] = this.agentPlannedMetric[key];
      });
      return metric;
    },
    conversionMetrics() {
      if (!this.stages || this.stages.length === 0) return null;

      let metric = {};
      let total = 0;
      let qualifiedToWon = 0;

      const qualified = this.stages.find(i => i.code === 'Qualified');
      Object.keys(this.agentContactMetric).forEach(key => {
        total += this.agentContactMetric[key];
        const stage = this.stages.find(i => i.code === key);
        if (stage.id >= qualified.id)
          qualifiedToWon += this.agentContactMetric[key];
      });

      const newToWonName = `${this.stages.find(i => i.code === 'New').name} ->
        ${this.stages.find(i => i.code === 'Won').name}`;
      metric[newToWonName] =
        total === 0
          ? 0
          : Math.round((this.agentContactMetric.Won / total) * 100);

      const qualifiedToWonName = `${
        this.stages.find(i => i.code === 'Qualified').name
      } ->
        ${this.stages.find(i => i.code === 'Won').name}`;
      metric[qualifiedToWonName] =
        qualifiedToWon === 0
          ? 0
          : Math.round((this.agentContactMetric.Won / qualifiedToWon) * 100);

      return metric;
    },
  },
  mounted() {
    this.$store.dispatch('agents/get');
    this.$store.dispatch('stages/get');
    this.fetchAllData();

    bus.$on('fetch_overview_reports', () => {
      this.fetchAllData();
    });
  },
  methods: {
    setShowDate(d) {
      this.showDate = d;
    },
    fetchAllData() {
      this.fetchAgentContactMetric();
      this.fetchAgentConversationMetric();
      this.fetchAgentPlannedMetric();
      this.fetchAgentPlannedConversation();
    },
    fetchAgentContactMetric() {
      this.$store.dispatch('fetchAgentDashboardContactMetric');
    },
    fetchAgentPlannedMetric() {
      this.$store.dispatch('fetchAgentDashboardPlannedMetric');
    },
    fetchAgentConversationMetric() {
      this.$store.dispatch('fetchAgentDashboardConversationMetric');
    },
    fetchAgentPlannedConversation() {
      this.$store.dispatch('fetchAgentDashboardPlannedConversations');
    },
  },
};
</script>
