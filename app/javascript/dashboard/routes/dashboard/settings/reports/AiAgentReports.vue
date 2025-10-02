<script>
import { mapState } from 'vuex';
import { useAlert, useTrack } from 'dashboard/composables';
import AiAgentMetrics from './components/AiAgentMetrics.vue';
import ReportFilterSelector from './components/FilterSelector.vue';
import { GROUP_BY_FILTER } from './constants';
import ReportContainer from './ReportContainer.vue';
import { REPORTS_EVENTS } from '../../../../helper/AnalyticsHelper/events';
import ReportHeader from './components/ReportHeader.vue';
import LineChart from '../../../../../shared/components/charts/LineChart.vue';
import BarChart from '../../../../../shared/components/charts/BarChart.vue';
import DonutChart from '../../../../../shared/components/charts/DonutChart.vue';
import ReportLineContainer from './ReportLineContainer.vue';
import ReportsAPI from 'dashboard/api/reports';
import MetricCard from './components/overview/MetricCard.vue';
import MetricCardFull from './components/overview/MetricCardFull.vue';
import BotTable from './components/overview/BotTable.vue';
import VueWordCloud from 'vuewordcloud';

export default {
  name: 'AIAgentReports',
  components: {
    [VueWordCloud.name]: VueWordCloud,
    AiAgentMetrics,
    ReportHeader,
    ReportFilterSelector,
    ReportContainer,
    LineChart,
    BarChart,
    DonutChart,
    ReportLineContainer,
    MetricCard,
    MetricCardFull,
    BotTable,
    VueWordCloud,
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
        resolvedByAI: 0,
        totalConversations: 0,
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
    // Get user tier from route meta (passed from routes.js)
    userTier() {
      return this.$route.meta?.userTier || 'free';
    },
    // Get available export options based on tier
    availableExportOptions() {
      if (this.userTier === 'pertamax_turbo') {
        return [
          { key: 'csv', label: 'OVERVIEW_REPORTS.EXPORT_TO_CSV' },
          { key: 'pdf', label: 'OVERVIEW_REPORTS.EXPORT_TO_PDF' },
          { key: 'excel', label: 'OVERVIEW_REPORTS.EXPORT_TO_EXCEL' }
        ];
      } else if (this.userTier === 'pertamax') {
        return [
          { key: 'csv', label: 'OVERVIEW_REPORTS.EXPORT_TO_CSV' }
        ];
      }
      return [];
    },


    requestPayload() {
      return {
        from: this.from,
        to: this.to,
      };
    },
    donutChartData() {
      const resolved = this.metrics.resolvedByAI || 0;
      const handovered = this.metrics.aiAgentHandoffCount || 0;
      const total = resolved + handovered;
      
      if (total === 0) {
        return {
          data: [],
          labels: []
        };
      }
      
      return {
        data: [resolved, handovered],
        labels: ['Resolved by AI', 'Handovered to Agent']
      };
    },
    barChartData() {
      // Dummy data for demonstration - replace with real data from store
      const labels = [];
      const resolvedData = [];
      const handoveredData = [];
      
      // Use filter dates if available, otherwise default to last 7 days
      const endDate = this.to ? new Date(this.to * 1000) : new Date();
      const startDate = this.from ? new Date(this.from * 1000) : new Date(Date.now() - 6 * 24 * 60 * 60 * 1000);
      
      // Calculate number of days between start and end date
      const daysDiff = Math.ceil((endDate - startDate) / (1000 * 60 * 60 * 24));
      const numDays = Math.max(1, Math.min(daysDiff, 30)); // Limit to 30 days max
      
      // Generate dummy data for the date range
      for (let i = numDays - 1; i >= 0; i--) {
        const date = new Date(endDate);
        date.setDate(date.getDate() - i);
        // Format date for display (MM/DD)
        const label = `${(date.getMonth() + 1).toString().padStart(2, '0')}/${date.getDate().toString().padStart(2, '0')}`;
        labels.push(label);
        
        const resolved = Math.floor(Math.random() * 50) + 20;
        const handovered = Math.floor(Math.random() * 20) + 5;
        
        resolvedData.push(resolved);
        handoveredData.push(handovered);
      }
      
      return {
        labels: labels,
        datasets: [
          {
            label: 'Resolved by AI',
            data: resolvedData,
            backgroundColor: '#10B981',
            borderColor: '#059669',
            borderWidth: 1,
          },
          {
            label: 'Handovered to Agent',
            data: handoveredData,
            backgroundColor: '#F59E0B',
            borderColor: '#D97706',
            borderWidth: 1,
          }
        ]
      };
    },
    topicsBarChartData() {
      // Dummy data for most popular topics
      const topics = [
        { topic: 'Billing Issues', count: 45 },
        { topic: 'Account Access', count: 38 },
        { topic: 'Product Support', count: 32 },
        { topic: 'Technical Issues', count: 28 },
        { topic: 'Order Status', count: 24 },
        { topic: 'Refund Requests', count: 18 },
        { topic: 'Feature Requests', count: 15 },
        { topic: 'Payment Issues', count: 12 },
      ];

      return {
        labels: topics.map(t => t.topic),
        datasets: [
          {
            label: 'Topic Frequency',
            data: topics.map(t => t.count),
            backgroundColor: '#3B82F6',
            borderColor: '#2563EB',
            borderWidth: 1,
          }
        ]
      };
    },
    topicsBarChartOptions() {
      return {
        indexAxis: 'y', // This makes it horizontal
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            display: false,
          },
        },
        scales: {
          x: {
            beginAtZero: true,
            ticks: {
              stepSize: 5,
            },
            grid: {
              display: true,
            },
          },
          y: {
            grid: {
              display: false,
            },
          },
        },
      };
    },
    // Dummy bot data - replace with real data from API
    botData() {
      return [
        {
          id: 1,
          name: 'Sales Assistant Bot',
          type: 'single',
          template_type: 'sales',
          status: 'active'
        },
        {
          id: 2,
          name: 'Customer Service Bot',
          type: 'multi',
          template_type: 'cs',
          status: 'active'
        },
        {
          id: 3,
          name: 'Restaurant Bot',
          type: 'single',
          template_type: 'resto',
          status: 'active'
        },
        {
          id: 4,
          name: 'Booking Bot',
          type: 'single',
          template_type: 'booking',
          status: 'active'
        },
        {
          id: 5,
          name: 'Custom Workflow Bot',
          type: 'custom',
          template_type: null,
          status: 'active'
        }
      ];
    },
    botMetrics() {
      return [
        {
          id: 1,
          metric: {
            handover_count: 25,
            chat_responded: 150
          }
        },
        {
          id: 2,
          metric: {
            handover_count: 45,
            chat_responded: 220
          }
        },
        {
          id: 3,
          metric: {
            handover_count: 12,
            chat_responded: 95
          }
        },
        {
          id: 4,
          metric: {
            handover_count: 8,
            chat_responded: 75
          }
        },
        {
          id: 5,
          metric: {
            handover_count: 18,
            chat_responded: 120
          }
        }
      ];
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
          resolvedByAI: response.data.resolved_by_ai || Math.floor(Math.random() * 100) + 50, // Dummy data
          totalConversations: response.data.total_conversations || Math.floor(Math.random() * 200) + 100, // Dummy data
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
    toggleDropdown() {
      this.dropdownOpen = !this.dropdownOpen;
    },
    closeDropdown() {
      this.dropdownOpen = false;
    },
    exportData(format) {
      // Check if user has permission for this export type
      const hasPermission = this.availableExportOptions.some(option => option.key === format);
      if (!hasPermission) {
        this.$bus.$emit('newToastMessage', {
          message: this.$t('OVERVIEW_REPORTS.EXPORT_NOT_ALLOWED'),
          type: 'error'
        });
        this.closeDropdown();
        return;
      }
      
      console.log(`Exporting data to ${format}`);
      // TODO: Implement actual export functionality
      this.closeDropdown();
    },
    toggleWordCloud() {
      this.showWordCloud = !this.showWordCloud;
    },
    onBotPageNumberChange(pageIndex) {
      this.botPageIndex = pageIndex;
      // this.fetchBotMetrics();
    },
    closeDropdownOnOutsideClick(event) {
      if (!this.dropdownOpen) return;
      const dropdownContainer = this.$refs.dropdownContainer;
      if (dropdownContainer && !dropdownContainer.contains(event.target)) {
        this.closeDropdown();
      }
    },
  },
  mounted() {
    window.addEventListener('click', this.closeDropdownOnOutsideClick);
  },
  beforeUnmount() {
    window.removeEventListener('click', this.closeDropdownOnOutsideClick);
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

    <!-- Laporan Bot AI Charts Section -->
    <div class="flex flex-row flex-wrap max-w-full">
      <MetricCardFull class="w-full max-w-full">
        <!-- KPIs and Donut Chart Row -->
        <div class="flex flex-col lg:flex-row gap-6 p-4">
          <!-- KPIs Section -->
          <div class="flex-1 grid grid-cols-1 md:grid-cols-2 gap-4">
            <!-- Jumlah Percakapan AI KPI -->
            <div class=" rounded-lg p-6">
              <div class="flex items-center justify-between">
                <div>
                  <p class="text-sm text-gray-600 dark:text-gray-400">
                    {{ $t('AI_AGENT_REPORTS.KPI.TOTAL_AI_CONVERSATIONS') }}
                  </p>
                  <p class="text-3xl font-bold text-gray-900 dark:text-white mt-2">
                    {{ metrics.totalConversations || 0 }}
                  </p>
                </div>
              </div>
            </div>

            <!-- Resolved by AI KPI -->
            <div class=" rounded-lg p-6 ">
              <div class="flex items-center justify-between">
                <div>
                  <p class="text-sm text-gray-600 dark:text-gray-400">
                    {{ $t('AI_AGENT_REPORTS.KPI.RESOLVED_BY_AI') }}
                  </p>
                  <div class="flex flex-row gap-2 items-center">
                    <p class="text-3xl font-bold text-gray-900 dark:text-white mt-2">
                      {{ metrics.resolvedByAI || 0 }}
                    </p>
                    <p class="text-sm text-green-600 items-center my-auto dark:text-green-400 mt-1">
                      ({{ metrics.totalConversations > 0 ? Math.round((metrics.resolvedByAI / metrics.totalConversations) * 100) : 0 }}%)
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Donut Chart Section -->
          <div v-if="userTier === 'pertalite' || userTier === 'pertamax' || userTier === 'pertamax_turbo'" class="flex-1 max-w-sm">
            <div class=" rounded-lg p-6 h-full">
              <div class="h-48 flex items-center justify-center">
                <DonutChart
                  v-if="donutChartData.data?.length"
                  :data="donutChartData.data"
                  :labels="donutChartData.labels"
                  :class="'text-sm text-gray-600 dark:text-gray-400'"
                />
                <div v-else class="text-sm text-gray-600 dark:text-gray-400">
                  {{ $t('REPORT.NO_ENOUGH_DATA') }}
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Bar Chart Section -->
        <div v-if="userTier === 'pertamax' || userTier === 'pertamax_turbo'" class="p-4 pt-0">
          <div class=" rounded-lg p-6">
            <div class="flex justify-between items-center mb-4">
              <h6 class="text-lg font-semibold text-gray-900 dark:text-white">
                {{ $t('AI_AGENT_REPORTS.CHARTS.DAILY_RESOLUTION_TREND') }}
              </h6>
            </div>
            <div class="h-80">
              <BarChart
                v-if="barChartData.labels?.length"
                :collection="barChartData"
              />
              <div v-else class="flex items-center justify-center h-full">
                <span class="text-sm text-gray-600 dark:text-gray-400">
                  {{ $t('REPORT.NO_ENOUGH_DATA') }}
                </span>
              </div>
            </div>
          </div>
        </div>
      </MetricCardFull>
    </div>
    
    <!-- Topics Analysis Section -->
    <div v-if="userTier === 'pertalite' || userTier === 'pertamax' || userTier === 'pertamax_turbo'" class="flex flex-row flex-wrap max-w-full">
      <MetricCardFull>
          <div class="p-4 pt-0">
            <div class=" rounded-lg p-6">
              <div class="flex justify-between items-center mb-4">
                <h6 class="text-lg font-semibold text-gray-900 dark:text-white">
                  {{ showWordCloud ? $t('AI_AGENT_REPORTS.TOPICS_ANALYSIS.HEADER_CLOUD') : $t('AI_AGENT_REPORTS.TOPICS_ANALYSIS.HEADER_CHART') }}
                </h6>
                <button v-if="userTier === 'pertamax_turbo'"
                  @click="toggleWordCloud"
                  class="inline-flex items-center px-3 py-2 border border-green-700 dark:border-gray-600 shadow-sm text-sm leading-4 font-medium rounded-md text-green-700 dark:text-green-200 dark:bg-green-800 hover:bg-green-50 dark:hover:bg-green-700 transition-colors"
                >
                  <svg 
                    xmlns="http://www.w3.org/2000/svg" 
                    class="h-4 w-4 mr-2" 
                    fill="none" 
                    viewBox="0 0 24 24" 
                    stroke="currentColor"
                  >
                    <path 
                      stroke-linecap="round" 
                      stroke-linejoin="round" 
                      stroke-width="2" 
                      d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4" 
                    />
                  </svg>
                  {{ showWordCloud ? $t('AI_AGENT_REPORTS.TOPICS_ANALYSIS.SHOW_CHART') : $t('AI_AGENT_REPORTS.TOPICS_ANALYSIS.SHOW_WORD_CLOUD') }}
                </button>
              </div>
              
              <!-- Bar Chart View -->
              <div v-if="!showWordCloud" class="h-80">
                <BarChart
                  v-if="topicsBarChartData.labels?.length"
                  :collection="topicsBarChartData"
                  :chart-options="topicsBarChartOptions"
                />
                <div v-else class="flex items-center justify-center h-full">
                  <span class="text-sm text-gray-600 dark:text-gray-400">
                  {{ $t('REPORT.NO_ENOUGH_DATA') }}
                  </span>
                </div>
              </div>

              <!-- Word Cloud View -->
              <div v-else class="h-80 flex items-center justify-center">
                <vue-word-cloud
                  style="
                    height: 480px;
                    width: 640px;
                  "
                  :words="wordCloudData"
                  :color="([, weight]) => weight > 10 ? 'Green' : weight > 5 ? 'RoyalBlue' : 'Indigo'"
                  font-family="Roboto"
                />
              </div>
            </div>
          </div>
      </MetricCardFull>
    </div>

    <!-- Bot Summary Table -->
    <div v-if="userTier === 'pertamax_turbo'" class="flex flex-row flex-wrap max-w-full">
      <MetricCard :header="$t('AI_AGENT_REPORTS.BOT_SUMMARY.HEADER')">
        <BotTable
          :bots="botData"
          :bot-metrics="botMetrics"
          :page-index="botPageIndex"
          :is-loading="false"
          @page-change="onBotPageNumberChange"
        />
      </MetricCard>
    </div>
  </div>
</template>