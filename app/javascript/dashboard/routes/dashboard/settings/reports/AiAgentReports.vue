<script>
import { useAlert, useTrack } from 'dashboard/composables';
import AiAgentMetrics from './components/AiAgentMetrics.vue';
import ReportFilterSelector from './components/FilterSelector.vue';
import { GROUP_BY_FILTER } from './constants';
import ReportContainer from './ReportContainer.vue';
import { REPORTS_EVENTS } from '../../../../helper/AnalyticsHelper/events';
import ReportHeader from './components/ReportHeader.vue';
import LineChart from '../../../../../shared/components/charts/LineChart.vue';
import ReportLineContainer from './ReportLineContainer.vue';
import ReportsAPI from 'dashboard/api/reports';

export default {
  name: 'AIAgentReports',
  components: {
    AiAgentMetrics,
    ReportHeader,
    ReportFilterSelector,
    ReportContainer,
    LineChart,
    ReportLineContainer,
  },
  data() {
    return {
      from: 0,
      to: 0,
      groupBy: GROUP_BY_FILTER[1],
      reportKeys: {
        AI_MESSAGE_USAGE: 'ai_agent_credit_usage',
        AI_MESSAGE_SEND_COUNT: 'ai_agent_message_send_count',
        AI_AGENT_HANDOFF_RATE: 'ai_agent_handoff_count',
        AGENT_HANDOFF_RATE: 'agent_handoff_count',
      },
      metrics: {
        aiAgentCreditUsage: 0,
        aiAgentMessageSendCount: 0,
        aiAgentHandoffCount: 0,
        handoffRate: 0,
      },
      businessHours: false,
      dropdownOpen: false,
      showWordCloud: false,
      botPageIndex: 0,
      selectedBot: null,
      wordCloudData: [
      ['Billing Issues', 45], ['Account Access', 38], ['Product Support', 32], ['Technical Issues', 28], ['Order Status', 24], ['Refund Requests', 18], ['Feature Requests', 15], ['Payment Issues', 12], ['Login Problems', 10], ['API Questions', 8], ['Integration Help', 7], ['Documentation', 6], ['Bug Reports', 5], ['Security Concerns', 4], ['Performance Issues', 3],
    ]
    };
  },
  computed: {
    requestPayload() {
      return {
        from: this.from,
        to: this.to,
      };
    },
  },
  watch: {
    requestPayload(value) {
      this.fetchMetrics(value);
    },
  },
  methods: {
    fetchAllData() {
      this.fetchBotSummary();
      this.fetchChartData();
    },
    fetchBotSummary() {
      try {
        this.$store.dispatch('fetchBotSummary', this.getRequestPayload());
      } catch {
        useAlert(this.$t('REPORT.SUMMARY_FETCHING_FAILED'));
      }
    },
    fetchMetrics(filters) {
      if (!filters.to || !filters.from) {
        return;
      }
      ReportsAPI.getAiAgentMetrics(filters).then(response => {
        this.$data.metrics = {
          aiAgentCreditUsage: response.data.ai_agent_credit_usage,
          aiAgentMessageSendCount: response.data.ai_agent_message_send_count,
          aiAgentHandoffCount: response.data.ai_agent_handoff_count,
          handoffRate: response.data.handoff_rate,
        };
      });
    },
    fetchChartData() {
      Object.keys(this.reportKeys).forEach(async key => {
        try {
          await this.$store.dispatch('fetchAccountReport', {
            metric: this.reportKeys[key],
            ...this.getRequestPayload(),
          });
        } catch {
          useAlert(this.$t('REPORT.DATA_FETCHING_FAILED'));
        }
      });
    },
    getRequestPayload() {
      const { from, to, groupBy, businessHours, selectedBot } = this;

      return {
        from,
        to,
        groupBy: groupBy?.period,
        businessHours,
        botId: selectedBot?.id !== 'all' ? selectedBot?.id : null,
      };
    },
    onFilterChange({ from, to, groupBy, businessHours, selectedBot }) {
      this.from = from;
      this.to = to;
      this.groupBy = groupBy;
      this.businessHours = businessHours;
      this.selectedBot = selectedBot;
      this.fetchAllData();

      useTrack(REPORTS_EVENTS.FILTER_REPORT, {
        filterValue: { from, to, groupBy, businessHours, selectedBot },
        reportType: 'bots',
      });
    },
  },
};
</script>

<template>
  <div class="flex flex-col gap-4 pb-6">
    <ReportHeader :header-title="$t('AI_AGENT_REPORTS.HEADER')" class="sticky">
      <div class="flex items-center gap-4">
        <!-- Filter on the left -->
        <div class="flex-grow">
          <ReportFilterSelector
            :show-agents-filter="false"
            show-group-by-filter
            :show-business-hours-switch="false"
            :show-bot-filter="true"
            @filter-change="onFilterChange"
          />
        </div>
        
        <!-- Export dropdown on the right -->
        <div v-if="userTier === 'pertamax' || userTier === 'pertamax_turbo'" class="relative inline-block text-left" ref="dropdownContainer">
          <button
            @click="toggleDropdown"
            class="inline-flex justify-center w-full rounded-md border border-gray-300 dark:border-gray-600 shadow-sm px-4 py-2 text-white hover:opacity-90 transition-opacity"
            style="background-color: #389947"
          >
            {{ $t('OVERVIEW_REPORTS.DOWNLOAD') }}
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="-mr-1 ml-2 h-5 w-5"
              viewBox="0 0 20 20"
              fill="currentColor"
            >
              <path
                fill-rule="evenodd"
                d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z"
                clip-rule="evenodd"
              />
            </svg>
          </button>
            <div
              v-if="dropdownOpen"
              class="origin-top-right absolute right-0 mt-2 w-56 rounded-md shadow-lg bg-n-solid-2 ring-1 ring-black dark:ring-gray-600 ring-opacity-5 focus:outline-none"
            >
              <div class="py-1">
              <a
                v-for="option in availableExportOptions"
                :key="option.key"
                href="#"
                class="block px-4 py-2 text-sm text-gray-700 dark:text-gray-200 hover:bg-green-100 dark:hover:bg-gray-700"
                @click="exportData(option.key)"
              >
                {{ $t(option.label) }}
              </a>
              
            </div>
          </div>
        </div>
        <!-- <div v-else-if="userTier && userTier !== 'pertamax_turbo' && userTier !== 'pertamax'" 
             class="text-sm text-gray-500 dark:text-gray-400">
          {{ $t('OVERVIEW_REPORTS.UPGRADE_FOR_EXPORT') }}
        </div> -->
      </div>
    </ReportHeader>

    <ReportLineContainer :metrics="metrics" />
  </div>
</template>
