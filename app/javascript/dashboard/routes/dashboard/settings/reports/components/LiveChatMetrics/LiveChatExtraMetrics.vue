<script>
import { mapGetters } from 'vuex';
import MetricCard from '../overview/MetricCard.vue';
import ReportFilterSelector from './../FilterSelector.vue';
import Spinner from 'shared/components/Spinner.vue';
import LiveChatCsatMetrics from './LiveChatCsatMetrics.vue';
import CircularProgressMetrics from './CircularProgressMetrics.vue';

const NONE_TEAM = Object.freeze({ team_id: 0, name: 'All teams' });

// Metric configuration constants
const METRIC_NAMES = Object.freeze({
  live_chat_impressions: 'Impression',
  live_chat_widget_opened: 'Widget Opened',
  live_chat_intent_match: 'Intent Match Percentage',
  live_chat_fall_back: 'Fall back Percentage',
  total_conversations: 'Total Conversations',
});

const ENGAGEMENT_METRICS = Object.freeze([
  'live_chat_impressions',
  'live_chat_widget_opened',
  'total_conversations',
]);

const CONVERSATION_METRICS = Object.freeze([
  'live_chat_intent_match',
  'live_chat_fall_back',
]);

const EXCLUDED_KEYS = Object.freeze(['grouped_data', 'live_chat_csat_metrics']);

export default {
  name: 'LiveChatMetrics',

  components: {
    ReportFilterSelector,
    MetricCard,
    Spinner,
    LiveChatCsatMetrics,
    CircularProgressMetrics,
  },

  data() {
    return {
      selectedTeam: NONE_TEAM,
      isFetchingData: false,
      from: 0,
      to: 0,
      METRIC_ICON_MAP: {
        Impression: 'eye-show',
        'Widget Opened': 'chat',
        'Total Conversations': 'chat-multiple',
      },
    };
  },

  computed: {
    ...mapGetters({
      teams: 'teams/getTeams',
      uiFlags: 'getOverviewUIFlags',
      liveChatOtherMetric: 'getLiveChatOtherMetric',
    }),
    otherMetrics() {
      return this.processMetrics(ENGAGEMENT_METRICS);
    },
    otherConversationMetrics() {
      return this.processMetrics(CONVERSATION_METRICS);
    },
    isLoadingMetrics() {
      return this.uiFlags.isFetchingLiveChatOtherMetric;
    },
    csatMetrics() {
      return this.liveChatOtherMetric?.live_chat_csat_metrics || {};
    },
  },
  beforeDestroy() {
    // Clean up timeout on component destruction
    if (this.fetchTimeout) {
      clearTimeout(this.fetchTimeout);
    }
  },
  methods: {
    onFilterChange({ from, to }) {
      if (this.from === from && this.to === to) return;

      this.from = from;
      this.to = to;
      this.debouncedFetchData();
    },
    debouncedFetchData() {
      clearTimeout(this.fetchTimeout);
      this.fetchTimeout = setTimeout(() => {
        this.fetchAllData();
      }, 300);
    },
    async fetchAllData() {
      if (this.isFetchingData) return;

      this.isFetchingData = true;
      try {
        await this.$store.dispatch('fetchLiveChatOtherMetric', {
          since: this.from,
          until: this.to,
        });
      } finally {
        this.isFetchingData = false;
      }
    },
    processMetrics(allowedKeys) {
      const metrics = {};

      if (
        !this.liveChatOtherMetric ||
        typeof this.liveChatOtherMetric !== 'object'
      ) {
        return metrics;
      }

      Object.entries(this.liveChatOtherMetric).forEach(([key, value]) => {
        // Skip excluded keys and keys not in allowedKeys
        if (EXCLUDED_KEYS.includes(key) || !allowedKeys.includes(key)) {
          return;
        }

        const metricName = METRIC_NAMES[key];
        if (!metricName) return;

        // Format percentage metrics
        metrics[metricName] = value || 0;
      });

      return metrics;
    },
    formatNumber(num) {
      if (num >= 1000000) {
        return (num / 1000000).toFixed(1) + 'M';
      }
      if (num >= 1000) {
        return (num / 1000).toFixed(1) + 'K';
      }
      return num.toString();
    },
    getMetricClass(idx) {
      if (idx === 0) {
        return 'bg-[#3B82F6] w-full';
      }
      if (idx === 1) {
        return 'bg-[#A855F7] w-4/5';
      }
      if (idx === 2) {
        return 'bg-[#6366F1] w-3/5';
      }
      return 'bg-[#3B82F6] w-full';
    },
  },
};
</script>

<template>
  <div class="column small-12 medium-8 conversation-metric">
    <metric-card
      class="overflow-visible min-h-[150px]"
      :header="'Engagement Analytics'"
      :is-live="false"
    >
      <div class="flex-1 overflow-auto w-full">
        <report-filter-selector
          :key="'filter-selector-overview'"
          :show-agents-filter="false"
          :show-labels-filter="false"
          :show-inbox-filter="false"
          :show-business-hours-switch="false"
          @filter-change="onFilterChange"
        />
        <div
          v-if="!isLoadingMetrics"
          class="grid grid-cols-1 gap-6 lg:grid-cols-3"
        >
          <div
            class="flex flex-col w-full justify-between border border-[#eaecf0] dark:border-[#4C5155] rounded-lg lg:col-span-1"
          >
            <div class="flex flex-col space-y-1.5 p-6">
              <div class="tracking-tight font-semibold text-base">
                Engagement Funnel
              </div>
            </div>
            <div class="p-6 pt-0">
              <div class="flex flex-col items-start space-y-3 py-4">
                <div
                  v-for="(metric, name, idx) in otherMetrics"
                  :key="name"
                  class="relative flex h-12 items-center justify-center rounded-full text-white"
                  :class="getMetricClass(idx)"
                >
                  <div class="flex w-full items-center justify-between px-4">
                    <div class="flex items-center gap-2">
                      <fluent-icon
                        size="1.16em"
                        :icon="METRIC_ICON_MAP[name]"
                        class="flex-shrink-0"
                      />
                      <span class="text-sm font-medium">{{ name }}</span>
                    </div>
                    <span class="text-base font-bold">{{ metric }}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div
            v-for="(metric, name) in otherConversationMetrics"
            :key="name"
            class="flex flex-col w-full justify-between border border-[#eaecf0] dark:border-[#4C5155] rounded-lg lg:col-span-1"
          >
            <div class="flex flex-col space-y-1.5 p-6">
              <div class="flex items-center gap-2">
                <div class="tracking-tight font-semibold text-base">
                  {{ name }}
                </div>
              </div>
              <div class="text-sm text-muted">
                {{
                  name === 'Intent Match Percentage'
                    ? `${metric}% of conversations matched an intent.`
                    : `${metric}% of conversations resulted in a fallback.`
                }}
              </div>
            </div>
            <div class="p-6 pt-0 flex flex-col items-center gap-4">
              <circular-progress-metrics
                :value="metric"
                :label="
                  name === 'Intent Match Percentage'
                    ? 'Intent Match'
                    : 'Fall back'
                "
                :size="150"
                :color="
                  name === 'Intent Match Percentage' ? '#3b82f6' : '#ef4444'
                "
              />
            </div>
          </div>
        </div>
        <div
          v-else
          class="flex items-center justify-center text-base px-12 py-6"
        >
          <spinner />
          <span class="loading-text">Loading metrics</span>
        </div>

        <!-- CSAT Metrics -->
        <template v-if="!isLoadingMetrics">
          <live-chat-csat-metrics :metrics="csatMetrics" />
        </template>

        <!-- Loading State for CSAT Metrics -->
        <div
          v-else
          class="flex items-center justify-center text-base px-12 py-6 mt-4"
        >
          <spinner />
          <span class="loading-text">Loading metrics</span>
        </div>
      </div>
    </metric-card>
  </div>
</template>

<style scoped>
.metric-content {
  text-align: center;
  padding: 0 8px;
}

.heading {
  font-size: 12px;
  color: #6b7280;
  margin-bottom: 4px;
  font-weight: 500;
}

.metric {
  font-size: 18px;
  font-weight: 600;
  color: #1f2937;
  margin: 0;
}

.dark .metric {
  color: #f9fafb;
}
</style>
