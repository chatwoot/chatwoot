<script>
import { mapGetters } from 'vuex';
import { OVERVIEW_METRICS } from '../../constants';
import MetricCard from '../overview/MetricCard.vue';
// import MultiselectDropdown from 'shared/components/ui/MultiselectDropdown.vue';
const noneTeam = { team_id: 0, name: 'All teams' };

export default {
  components: {
    // MultiselectDropdown,
    MetricCard,
  },
  data() {
    return {
      selectedTeam: noneTeam,
    };
  },
  computed: {
    ...mapGetters({
      teams: 'teams/getTeams',
      accountConversationMetric: 'getAccountConversationMetric',
      uiFlags: 'getOverviewUIFlags',
    }),
    conversationMetrics() {
      let metric = {};
      Object.keys(this.accountConversationMetric).forEach(key => {
        const metricName = this.$t(
          `OVERVIEW_REPORTS.ACCOUNT_CONVERSATIONS.${OVERVIEW_METRICS[key]}`
        );
        metric[metricName] = this.accountConversationMetric[key];
      });
      return metric;
    },
    teamsList() {
      return [noneTeam, ...this.teams];
    },
  },
  mounted() {
    this.$store.dispatch('fetchLiveConversationMetric');
  },
  methods: {
    onSelectTeam(team) {
      this.$store.dispatch('fetchLiveConversationMetric', {
        team_id: !team.id ? null : team.id,
      });
      this.selectedTeam = team;
    },
  },
};
</script>

<template>
  <div class="column small-12 medium-8 conversation-metric">
    <metric-card
      class="overflow-visible min-h-[150px]"
      :header="$t('OVERVIEW_REPORTS.ACCOUNT_CONVERSATIONS.HEADER')"
      :is-loading="uiFlags.isFetchingAccountConversationMetric"
      loading-message="Loading metrics"
    >
      <!-- <template #control>
        <multiselect-dropdown
          class="!mb-0 !w-1/2"
          :options="teamsList"
          :selected-item="selectedTeam"
          multiselector-title=""
          multiselector-placeholder="All teams"
          no-search-result="No teams found"
          input-placeholder="Search for a team"
          :is-filter="true"
          @click="onSelectTeam"
        />
      </template> -->
      <div
        v-for="(metric, name, index) in conversationMetrics"
        :key="index"
        class="metric-content column"
      >
        <h3 class="heading">
          {{ name }}
        </h3>
        <p class="metric">{{ metric }}</p>
      </div>
    </metric-card>
  </div>
</template>
