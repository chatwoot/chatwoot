<script>
import { mapState } from 'vuex';
import { useAlert, useTrack } from 'dashboard/composables';
import ReportHeader from './components/ReportHeader.vue';
import BarChart from '../../../../../shared/components/charts/BarChart.vue';
import DonutChart from '../../../../../shared/components/charts/DonutChart.vue';
import LineChart2 from '../../../../../shared/components/charts/LineChart2.vue';
import MetricCard from './components/overview/MetricCard.vue';
import MetricCardFull from './components/overview/MetricCardFull.vue';
import ReportsFiltersLabels from './components/Filters/Labels.vue';
import ReportsFiltersDateRange from './components/Filters/DateRange.vue';
import { GROUP_BY_FILTER, DATE_RANGE_OPTIONS } from './constants';
import { REPORTS_EVENTS } from '../../../../helper/AnalyticsHelper/events';
import ReportsAPI from 'dashboard/api/reports';
import { getUnixStartOfDay, getUnixEndOfDay } from 'helpers/DateHelper';
import subDays from 'date-fns/subDays';
import VueWordCloud from 'vuewordcloud';

export default {
  name: 'LabelReports',
  components: {
    [VueWordCloud.name]: VueWordCloud,
    ReportHeader,
    BarChart,
    DonutChart,
    LineChart2,
    MetricCard,
    MetricCardFull,
    ReportsFiltersLabels,
    ReportsFiltersDateRange,
    VueWordCloud,
  },
  data() {
    return {
      from: 0,
      to: 0,
      selectedDateRange: DATE_RANGE_OPTIONS.LAST_7_DAYS,
      selectedLabels: [],
      customDateRange: [new Date(), new Date()],
      groupBy: GROUP_BY_FILTER[1],
      dropdownOpen: false,
      showWordCloud: false,
      metrics: {
        totalTopics: 0,
        mostPopularTopic: '',
        averageTopicsPerConversation: 0,
      },
      sentimentMetrics: {
        positive: 0,
        negative: 0,
        neutral: 0,
      },
      questionCategories: {
        harga: 0,
        stok: 0,
        pengiriman: 0,
        komplain: 0,
        informasi: 0,
        lainnya: 0,
      },
      sentimentTrendData: [],
      topicsTrendData: [],
      reportKeys: {
        LABEL_USAGE: 'label_usage_count',
        POPULAR_TOPICS: 'popular_topics',
      },
      // Dummy data for word cloud
      wordCloudData: [
        ['Billing Issues', 45], 
        ['Account Access', 38], 
        ['Product Support', 32], 
        ['Technical Issues', 28], 
        ['Order Status', 24], 
        ['Refund Requests', 18], 
        ['Feature Requests', 15], 
        ['Payment Issues', 12], 
        ['Login Problems', 10], 
        ['API Questions', 8], 
        ['Integration Help', 7], 
        ['Documentation', 6], 
        ['Bug Reports', 5], 
        ['Security Concerns', 4], 
        ['Performance Issues', 3],
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

    isDateRangeSelected() {
      return (
        this.selectedDateRange.id === DATE_RANGE_OPTIONS.CUSTOM_DATE_RANGE.id
      );
    },
    requestPayload() {
      return {
        from: this.from,
        to: this.to,
        selectedLabels: this.selectedLabels,
        groupBy: this.groupBy?.period,
      };
    },
    topicsBarChartData() {
      // Generate dummy data for most popular topics
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
    sentimentChartData() {
      const data = [
        this.sentimentMetrics.positive,
        this.sentimentMetrics.neutral,
        this.sentimentMetrics.negative
      ];
      const labels = [
        this.$t('LABEL_REPORTS.SENTIMENT.POSITIVE'),
        this.$t('LABEL_REPORTS.SENTIMENT.NEUTRAL'),
        this.$t('LABEL_REPORTS.SENTIMENT.NEGATIVE')
      ];
      return { data, labels };
    },
    questionSegmentationChartData() {
      const data = [
        this.questionCategories.harga,
        this.questionCategories.stok,
        this.questionCategories.pengiriman,
        this.questionCategories.komplain,
        this.questionCategories.informasi,
        this.questionCategories.lainnya
      ];
      const labels = [
        this.$t('LABEL_REPORTS.QUESTION_CATEGORIES.HARGA'),
        this.$t('LABEL_REPORTS.QUESTION_CATEGORIES.STOK'),
        this.$t('LABEL_REPORTS.QUESTION_CATEGORIES.PENGIRIMAN'),
        this.$t('LABEL_REPORTS.QUESTION_CATEGORIES.KOMPLAIN'),
        this.$t('LABEL_REPORTS.QUESTION_CATEGORIES.INFORMASI'),
        this.$t('LABEL_REPORTS.QUESTION_CATEGORIES.LAINNYA')
      ];
      return { data, labels };
    },
    sentimentTrendChartData() {
      return this.sentimentTrendData;
    },
    topicsTrendChartData() {
      return this.topicsTrendData;
    },
  },
  watch: {
    requestPayload(value) {
      this.fetchMetrics(value);
    },
  },
  methods: {
    fetchAllData() {
      this.fetchMetrics(this.requestPayload);
      this.fetchChartData();
      this.fetchSentimentAnalysis(this.requestPayload);
      this.fetchQuestionSegmentation(this.requestPayload);
      this.fetchSentimentTrend(this.requestPayload);
      this.fetchTopicsTrend(this.requestPayload);
    },
    fetchMetrics(filters) {
      if (!filters.to || !filters.from) {
        return;
      }
      
      // TODO: Implement real API call for label metrics
      // 
      // const labelIds = filters.selectedLabels.map(label => label.id);
      // if (labelIds.length === 0) {
      //   // If no labels selected, fetch metrics for all labels
      //   labelIds = null; // or fetch all labels data
      // }
      //
      // ReportsAPI.getLabelMetrics({
      //   ...filters,
      //   labelIds: labelIds
      // }).then(response => {
      //   this.metrics = {
      //     totalTopics: response.data.total_topics,
      //     mostPopularTopic: response.data.most_popular_topic,
      //     averageTopicsPerConversation: response.data.avg_topics_per_conversation,
      //   };
      // }).catch(error => {
      //   console.error('Failed to fetch label metrics:', error);
      //   useAlert(this.$t('REPORT.DATA_FETCHING_FAILED'));
      // });
      
      // Dummy data for now
      const numLabels = this.selectedLabels.length || 8;
      this.metrics = {
        totalTopics: Math.floor(Math.random() * 50 * numLabels) + 20,
        mostPopularTopic: 'Billing Issues',
        averageTopicsPerConversation: (Math.random() * 3 + 1).toFixed(1),
      };
      
      // Dummy sentiment data
      const totalConversations = this.metrics.totalTopics;
      this.sentimentMetrics = {
        positive: Math.floor(totalConversations * (0.4 + Math.random() * 0.2)), // 40-60%
        neutral: Math.floor(totalConversations * (0.2 + Math.random() * 0.2)),  // 20-40%
        negative: Math.floor(totalConversations * (0.1 + Math.random() * 0.2)), // 10-30%
      };
      
      // Dummy question categories data
      this.questionCategories = {
        harga: Math.floor(totalConversations * (0.15 + Math.random() * 0.1)),      // 15-25%
        stok: Math.floor(totalConversations * (0.1 + Math.random() * 0.1)),       // 10-20%
        pengiriman: Math.floor(totalConversations * (0.2 + Math.random() * 0.1)), // 20-30%
        komplain: Math.floor(totalConversations * (0.15 + Math.random() * 0.1)),  // 15-25%
        informasi: Math.floor(totalConversations * (0.1 + Math.random() * 0.1)),  // 10-20%
        lainnya: Math.floor(totalConversations * (0.05 + Math.random() * 0.1)),   // 5-15%
      };
      
      console.log('Fetching metrics for labels:', this.selectedLabels);
    },
    fetchSentimentAnalysis(filters) {
      // TODO: Implement real API call for sentiment analysis
      // 
      // const labelIds = filters.selectedLabels.map(label => label.id);
      // ReportsAPI.getSentimentAnalysis({
      //   ...filters,
      //   labelIds: labelIds
      // }).then(response => {
      //   this.sentimentMetrics = {
      //     positive: response.data.positive_count,
      //     negative: response.data.negative_count,
      //     neutral: response.data.neutral_count,
      //   };
      // }).catch(error => {
      //   console.error('Failed to fetch sentiment analysis:', error);
      //   useAlert(this.$t('REPORT.DATA_FETCHING_FAILED'));
      // });
      
      console.log('Fetching sentiment analysis for labels:', this.selectedLabels);
    },
    fetchQuestionSegmentation(filters) {
      // TODO: Implement real API call for question segmentation
      // 
      // const labelIds = filters.selectedLabels.map(label => label.id);
      // ReportsAPI.getQuestionSegmentation({
      //   ...filters,
      //   labelIds: labelIds
      // }).then(response => {
      //   this.questionCategories = {
      //     harga: response.data.price_questions,
      //     stok: response.data.stock_questions,
      //     pengiriman: response.data.shipping_questions,
      //     komplain: response.data.complaint_questions,
      //     informasi: response.data.info_questions,
      //     lainnya: response.data.other_questions,
      //   };
      // }).catch(error => {
      //   console.error('Failed to fetch question segmentation:', error);
      //   useAlert(this.$t('REPORT.DATA_FETCHING_FAILED'));
      // });
      
      console.log('Fetching question segmentation for labels:', this.selectedLabels);
    },
    fetchSentimentTrend(filters) {
      // TODO: Implement real API call for sentiment trend over time
      // 
      // const labelIds = filters.selectedLabels.map(label => label.id);
      // ReportsAPI.getSentimentTrend({
      //   ...filters,
      //   labelIds: labelIds
      // }).then(response => {
      //   this.sentimentTrendData = [
      //     {
      //       label: 'LABEL_REPORTS.SENTIMENT.POSITIVE',
      //       data: response.data.positive_trend
      //     },
      //     {
      //       label: 'LABEL_REPORTS.SENTIMENT.NEUTRAL', 
      //       data: response.data.neutral_trend
      //     },
      //     {
      //       label: 'LABEL_REPORTS.SENTIMENT.NEGATIVE',
      //       data: response.data.negative_trend
      //     }
      //   ];
      // }).catch(error => {
      //   console.error('Failed to fetch sentiment trend:', error);
      //   useAlert(this.$t('REPORT.DATA_FETCHING_FAILED'));
      // });
      
      // Generate dummy trend data
      const days = Math.ceil((filters.to - filters.from) / (24 * 60 * 60));
      const trendData = [];
      
      for (let i = 0; i < days; i++) {
        const timestamp = filters.from + (i * 24 * 60 * 60);
        trendData.push({
          timestamp: timestamp,
          positive: Math.floor(Math.random() * 20) + 5,
          neutral: Math.floor(Math.random() * 15) + 3,
          negative: Math.floor(Math.random() * 10) + 1,
        });
      }
      
      this.sentimentTrendData = [
        {
          label: 'LABEL_REPORTS.SENTIMENT.POSITIVE',
          data: trendData.map(d => ({ timestamp: d.timestamp, value: d.positive }))
        },
        {
          label: 'LABEL_REPORTS.SENTIMENT.NEUTRAL',
          data: trendData.map(d => ({ timestamp: d.timestamp, value: d.neutral }))
        },
        {
          label: 'LABEL_REPORTS.SENTIMENT.NEGATIVE',
          data: trendData.map(d => ({ timestamp: d.timestamp, value: d.negative }))
        }
      ];
      
      console.log('Fetching sentiment trend for labels:', this.selectedLabels);
    },
    fetchTopicsTrend(filters) {
      // TODO: Implement real API call for topics trend over time
      // 
      // const labelIds = filters.selectedLabels.map(label => label.id);
      // ReportsAPI.getTopicsTrend({
      //   ...filters,
      //   labelIds: labelIds
      // }).then(response => {
      //   this.topicsTrendData = [
      //     {
      //       label: 'LABEL_REPORTS.TOPICS.BILLING',
      //       data: response.data.billing_trend
      //     },
      //     {
      //       label: 'LABEL_REPORTS.TOPICS.SUPPORT',
      //       data: response.data.support_trend
      //     },
      //     {
      //       label: 'LABEL_REPORTS.TOPICS.TECHNICAL',
      //       data: response.data.technical_trend
      //     }
      //   ];
      // }).catch(error => {
      //   console.error('Failed to fetch topics trend:', error);
      //   useAlert(this.$t('REPORT.DATA_FETCHING_FAILED'));
      // });
      
      // Generate dummy trend data for top 3 topics
      const days = Math.ceil((filters.to - filters.from) / (24 * 60 * 60));
      const trendData = [];
      
      for (let i = 0; i < days; i++) {
        const timestamp = filters.from + (i * 24 * 60 * 60);
        trendData.push({
          timestamp: timestamp,
          billing: Math.floor(Math.random() * 15) + 2,
          support: Math.floor(Math.random() * 12) + 1,
          technical: Math.floor(Math.random() * 10) + 1,
        });
      }
      
      this.topicsTrendData = [
        {
          label: 'Billing Issues',
          data: trendData.map(d => ({ timestamp: d.timestamp, value: d.billing }))
        },
        {
          label: 'Product Support',
          data: trendData.map(d => ({ timestamp: d.timestamp, value: d.support }))
        },
        {
          label: 'Technical Issues',
          data: trendData.map(d => ({ timestamp: d.timestamp, value: d.technical }))
        }
      ];
      
      console.log('Fetching topics trend for labels:', this.selectedLabels);
    },
    fetchChartData() {
      // TODO: Implement real API calls for label-specific chart data
      // For multiple labels, we need to fetch data for each selected label
      
      // Example of how to fetch data for multiple labels:
      // const labelIds = this.selectedLabels.map(label => label.id);
      // 
      // if (labelIds.length === 0) {
      //   // If no labels selected, fetch data for all labels or default set
      //   labelIds = [1, 2, 3, 4, 5, 6, 7, 8]; // default label IDs
      // }
      //
      // labelIds.forEach(async labelId => {
      //   Object.keys(this.reportKeys).forEach(async key => {
      //     try {
      //       await this.$store.dispatch('fetchLabelReport', {
      //         metric: this.reportKeys[key],
      //         labelId: labelId,
      //         ...this.getRequestPayload(),
      //       });
      //     } catch {
      //       useAlert(this.$t('REPORT.DATA_FETCHING_FAILED'));
      //     }
      //   });
      // });
      
      console.log('Fetching chart data for labels:', this.selectedLabels);
    },
    getRequestPayload() {
      const { from, to, groupBy, selectedLabels } = this;
      return {
        from,
        to,
        groupBy: groupBy?.period,
        selectedLabels: selectedLabels.map(label => label.id),
        type: 'label',
      };
    },
    onDateRangeChange(selectedRange) {
      this.selectedDateRange = selectedRange;
      this.calculateDateRange();
      this.fetchAllData();
    },
    onCustomDateRangeChange(value) {
      this.customDateRange = value;
      this.calculateDateRange();
      this.fetchAllData();
    },
    onLabelsFilterSelection(selectedLabels) {
      this.selectedLabels = selectedLabels;
      this.fetchAllData();
      
      useTrack(REPORTS_EVENTS.FILTER_REPORT, {
        filterValue: selectedLabels,
        reportType: 'label',
      });
    },
    calculateDateRange() {
      if (this.isDateRangeSelected) {
        this.to = getUnixEndOfDay(this.customDateRange[1]);
        this.from = getUnixStartOfDay(this.customDateRange[0]);
      } else {
        this.to = getUnixEndOfDay(new Date());
        const { offset } = this.selectedDateRange;
        const fromDate = subDays(new Date(), offset);
        this.from = getUnixStartOfDay(fromDate);
      }
    },
    toggleDropdown() {
      this.dropdownOpen = !this.dropdownOpen;
    },
    closeDropdown() {
      this.dropdownOpen = false;
    },
    exportData(format) {
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
    closeDropdownOnOutsideClick(event) {
      if (!this.dropdownOpen) return;
      const dropdownContainer = this.$refs.dropdownContainer;
      if (dropdownContainer && !dropdownContainer.contains(event.target)) {
        this.closeDropdown();
      }
    },
  },
  mounted() {
    this.calculateDateRange();
    this.fetchAllData();
    console.log('Word cloud data:', this.wordCloudData);
    window.addEventListener('click', this.closeDropdownOnOutsideClick);
  },
  beforeUnmount() {
    window.removeEventListener('click', this.closeDropdownOnOutsideClick);
  },
};
</script>

<template>
  <div class="flex flex-col gap-4 pb-6">
    <ReportHeader :header-title="$t('LABEL_REPORTS.HEADER')" class="sticky">
      <div class="flex items-center gap-4">
        <!-- Filters on the left -->
        <div class="flex-grow flex gap-4">
          <ReportsFiltersDateRange @on-range-change="onDateRangeChange" />
          <ReportsFiltersLabels @labels-filter-selection="onLabelsFilterSelection" />
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
              class="-mr-1 ml-2 h-5 w-5"
              xmlns="http://www.w3.org/2000/svg"
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
            class="origin-top-right absolute right-0 mt-2 w-56 rounded-md shadow-lg bg-n-solid-2 dark:bg-gray-800 ring-1 ring-black dark:ring-gray-600 ring-opacity-5 focus:outline-none"
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
    
    <!-- Topics Analysis Section -->
    <div v-if="userTier === 'pertalite' || userTier === 'pertamax' || userTier === 'pertamax_turbo'" class="flex flex-row flex-wrap max-w-full">
      <MetricCardFull>
        <div class="p-4 pt-0">
          <div class="rounded-lg p-6">
            <div class="flex justify-between items-center mb-4">
              <h6 class="text-lg font-semibold text-gray-900 dark:text-white">
                {{ showWordCloud ? $t('AI_AGENT_REPORTS.TOPICS_ANALYSIS.HEADER_CLOUD') : $t('AI_AGENT_REPORTS.TOPICS_ANALYSIS.HEADER_CHART') }}
              </h6>
              
              <!-- Toggle button for word cloud -->
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
                v-if="topicsBarChartData.datasets[0].data.length > 0"
                :data="topicsBarChartData"
                :options="topicsBarChartOptions"
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
    
    <!-- Sentiment Analysis Section -->
    <div v-if="userTier === 'pertamax' || userTier === 'pertamax_turbo'" class="flex flex-row flex-wrap max-w-full">
      <MetricCardFull>
        <div class="p-4 pt-0">
          <div class="rounded-lg p-6">
            <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">
              {{ $t('LABEL_REPORTS.SENTIMENT.HEADER') }}
            </h3>
            <div class="flex flex-col items-center md:flex-row gap-4">
              <!-- Chart Section -->
              <div class="flex-1 w-full max-w-full md:w-[70%] md:max-w-[70%]">
                <div class="h-80">
                  <DonutChart
                    v-if="sentimentChartData.data.some(value => value > 0)"
                    :data="sentimentChartData.data"
                    :labels="sentimentChartData.labels"
                  />
                  <div v-else class="flex items-center justify-center h-full">
                    <span class="text-sm text-gray-600 dark:text-gray-400">
                      {{ $t('REPORT.NO_ENOUGH_DATA') }}
                    </span>
                  </div>
                </div>
              </div>
              
              <!-- Summary Section -->
              <div class=" ml-3 flex-1 w-full max-w-full md:w-[30%] md:max-w-[30%]">
                <div class="space-y-4">
                  <h4 class="text-base font-medium text-gray-900 dark:text-white mb-4">
                    {{ $t('LABEL_REPORTS.SENTIMENT.SUMMARY') }}
                  </h4>

                  <div class="flex flex-row space-x-4">
                    <div class="flex-1 min-w-0 pb-2">
                      <h3 class="text-base text-gray-600 dark:text-gray-400">
                      {{ $t('LABEL_REPORTS.SENTIMENT.POSITIVE') }}
                    </h3>
                    <p class="text-n-slate-12 text-3xl mb-0 mt-1">
                      {{ sentimentMetrics.positive }}
                    </p>
                    </div>

                    <div class="flex-1 min-w-0 pb-2">
                      <h3 class="text-base text-gray-600 dark:text-gray-400">
                        {{ $t('LABEL_REPORTS.SENTIMENT.NEUTRAL') }}
                      </h3>
                      <p class="text-n-slate-12 text-3xl mb-0 mt-1">
                        {{ sentimentMetrics.neutral }}
                      </p>
                    </div>

                    <div class="flex-1 min-w-0 pb-2">
                      <h3 class="text-base text-gray-600 dark:text-gray-400">
                        {{ $t('LABEL_REPORTS.SENTIMENT.NEGATIVE') }}
                      </h3>
                      <p class="text-n-slate-12 text-3xl mb-0 mt-1">
                        {{ sentimentMetrics.negative }}
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </MetricCardFull>
    </div>
    
    <!-- Sentiment Trend Analysis Section -->
    <div v-if="userTier === 'pertamax_turbo'" class="flex flex-row flex-wrap max-w-full">
      <MetricCardFull>
        <div class="p-4 pt-0">
          <div class="rounded-lg p-6">
            <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">
              {{ $t('LABEL_REPORTS.SENTIMENT_TREND.HEADER') }}
            </h3>
            <div class="h-80">
              <LineChart2
                v-if="sentimentTrendData.length > 0 && sentimentTrendData[0].data.length > 0"
                :datasets="sentimentTrendData"
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
    
    <!-- Question Segmentation Section -->
    <div v-if="userTier === 'pertamax' || userTier === 'pertamax_turbo'" class="flex flex-row flex-wrap max-w-full">
      <MetricCardFull>
        <div class="p-4 pt-0">
          <div class="rounded-lg p-6">
            <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">
              {{ $t('LABEL_REPORTS.QUESTION_SEGMENTATION.HEADER') }}
            </h3>
            <div class="h-80">
              <DonutChart
                v-if="questionSegmentationChartData.data.some(value => value > 0)"
                :data="questionSegmentationChartData.data"
                :labels="questionSegmentationChartData.labels"
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
    
    <!-- Topics Trend Analysis Section -->
    <div v-if="userTier === 'pertamax_turbo'" class="flex flex-row flex-wrap max-w-full">
      <MetricCardFull>
        <div class="p-4 pt-0">
          <div class="rounded-lg p-6">
            <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">
              {{ $t('LABEL_REPORTS.TOPICS_TREND.HEADER') }}
            </h3>
            <div class="h-80">
              <LineChart2
                v-if="topicsTrendData.length > 0 && topicsTrendData[0].data.length > 0"
                :datasets="topicsTrendData"
              />
              <div v-else class="flex items-center justify-center h-full">
                <span class="text-sm text-gray-600 dark:text-gray-400">
                  {{ $t('LABEL_REPORTS.NO_ENOUGH_DATA') }}
                </span>
              </div>
            </div>
          </div>
        </div>
      </MetricCardFull>
    </div>
  </div>
</template>