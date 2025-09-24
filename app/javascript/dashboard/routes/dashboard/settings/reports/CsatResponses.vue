<script>
import { mapGetters } from 'vuex';
import { useAlert, useTrack } from 'dashboard/composables';
import CsatMetrics from './components/CsatMetrics.vue';
import CsatTable from './components/CsatTable.vue';
import ReportFilterSelector from './components/FilterSelector.vue';
import { generateFileName } from '../../../../helper/downloadHelper';
import { REPORTS_EVENTS } from '../../../../helper/AnalyticsHelper/events';
import { FEATURE_FLAGS } from '../../../../featureFlags';
import V4Button from 'dashboard/components-next/button/Button.vue';
import ReportHeader from './components/ReportHeader.vue';

export default {
  name: 'CsatResponses',
  components: {
    CsatMetrics,
    CsatTable,
    ReportFilterSelector,
    ReportHeader,
    V4Button,
  },
  data() {
    return {
      pageIndex: 0,
      from: 0,
      to: 0,
      userIds: [],
      inbox: null,
      team: null,
      rating: null,
    };
  },
  computed: {
    // ...mapGetters({
    //   accountId: 'getCurrentAccountId',
    //   isFeatureEnabledOnAccount: 'accounts/isFeatureEnabledonAccount',
    // }),
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
        user_ids: this.userIds,
        inbox_id: this.inbox,
        team_id: this.team,
        rating: this.rating,
      };
    },
    // isTeamsEnabled() {
    //   return this.isFeatureEnabledOnAccount(
    //     this.accountId,
    //     FEATURE_FLAGS.TEAM_MANAGEMENT
    //   );
    // },
    csatTrendData() {
      console.log('Generate CSAT data')
      // Generate dynamic line chart data for CSAT trends over time
      const endDate = this.to ? new Date(this.to * 1000) : new Date();
      const startDate = this.from ? new Date(this.from * 1000) : new Date(Date.now() - 29 * 24 * 60 * 60 * 1000);
      
      // Calculate number of days between start and end date
      const daysDiff = Math.ceil((endDate - startDate) / (1000 * 60 * 60 * 24));
      const numDays = Math.max(1, Math.min(daysDiff, 30)); // Limit to 30 days max
      
      // Generate timestamps
      const timestamps = [];
      for (let i = numDays - 1; i >= 0; i--) {
        const date = new Date(endDate);
        date.setDate(date.getDate() - i);
        timestamps.push(Math.floor(date.getTime() / 1000));
      }
      
      // Influence data based on selected agents and filters
      const agentMultiplier = this.selectedAgents.length > 0 ? this.selectedAgents.length : 1;
      const baseScoreVariation = this.selectedAgents.length > 0 ? 
        (this.selectedAgents.length * 2) : 0; // Better scores with more agents selected
      const ratingInfluence = this.rating ? 5 : 0; // Boost if rating filter applied
      
      // Generate datasets for CSAT metrics
      const datasets = [
        {
          label: 'CSAT_REPORTS.TRENDS.SATISFACTION_SCORE',
          data: timestamps.map(timestamp => ({
            value: Math.min(100, Math.floor(Math.random() * 35) + 65 + baseScoreVariation + ratingInfluence), // 65-100%
            timestamp: timestamp,
          })),
        },
        {
          label: 'CSAT_REPORTS.TRENDS.RESPONSE_RATE',
          data: timestamps.map(timestamp => ({
            value: Math.min(100, Math.floor(Math.random() * 25) + 75 + Math.floor(baseScoreVariation/2)), // 75-100%
            timestamp: timestamp,
          })),
        }
      ];
      console.log('CSAT Trend Datasets:', datasets);
      return datasets;
    },
    csatAnalyticsData() {
      // Dummy data for CSAT analytics by topic & agent
      const topics = ['Billing', 'Technical Support', 'Product Info', 'General Inquiry', 'Bug Report'];
      
      // Adjust data based on selected agents and other filters
      const agentMultiplier = this.selectedAgents.length > 0 ? this.selectedAgents.length : 1;
      const ratingFilter = this.rating ? 1.2 : 1; // Boost scores if specific rating filter applied
      
      return {
        labels: topics,
        data1: {
          label: 'CSAT_REPORTS.ANALYTICS.SATISFACTION_SCORE',
          data: topics.map(() => 
            Math.min(100, Math.floor((Math.random() * 35 + 65) * ratingFilter)) // 65-100%
          )
        },
        data2: {
          label: 'CSAT_REPORTS.ANALYTICS.RESPONSE_COUNT', 
          data: topics.map(() => 
            Math.floor((Math.random() * 40 + 10) * agentMultiplier) // 10-50 responses * agent multiplier
          )
        }
      };
    },
  },
  watch: {
    requestPayload: {
      handler(newValue) {
        this.fetchAllData(newValue);
      },
      deep: true,
    },
  },
  methods: {
    getAllData() {
      try {
        this.$store.dispatch('csat/getMetrics', this.requestPayload);
        this.getResponses();
      } catch {
        useAlert(this.$t('REPORT.DATA_FETCHING_FAILED'));
      }
    },
    getResponses() {
      this.$store.dispatch('csat/get', {
        page: this.pageIndex + 1,
        ...this.requestPayload,
      });
    },
    downloadReports() {
      const type = 'csat';
      try {
        this.$store.dispatch('csat/downloadCSATReports', {
          fileName: generateFileName({ type, to: this.to }),
          ...this.requestPayload,
        });
      } catch (error) {
        useAlert(this.$t('REPORT.CSAT_REPORTS.DOWNLOAD_FAILED'));
      }
    },
    onPageNumberChange(pageIndex) {
      this.pageIndex = pageIndex;
      this.getResponses();
    },
    onFilterChange({
      from,
      to,
      selectedAgents,
      selectedInbox,
      selectedTeam,
      selectedRating,
    }) {
      // do not track filter change on inital load
      if (this.from !== 0 && this.to !== 0) {
        useTrack(REPORTS_EVENTS.FILTER_REPORT, {
          filterType: 'date',
          reportType: 'csat',
        });
      }

      this.from = from;
      this.to = to;
      this.userIds = selectedAgents.map(el => el.id);
      this.inbox = selectedInbox?.id;
      this.team = selectedTeam?.id;
      this.rating = selectedRating?.value;

      this.getAllData();
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
    // Initialize with default data
    // this.fetchAllData();
  },
  beforeUnmount() {
    window.removeEventListener('click', this.closeDropdownOnOutsideClick);
  },
};
</script>

<template>
  <div class="flex flex-col gap-4 pb-6">
    <ReportHeader :header-title="$t('CSAT_REPORTS.HEADER')">
      <div class="flex items-center gap-4">
        <!-- Filter on the left -->
        <div class="flex-grow">
          <ReportFilterSelector
            show-agents-filter
            show-inbox-filter
            :show-business-hours-switch="false"
            @filter-change="onFilterChange"
          />
        </div>
        <!-- Export dropdown on the right -->
        <div v-if="userTier === 'pertamax' || userTier === 'pertamax_turbo'" class="relative inline-block text-left z-40" ref="dropdownContainer">
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

    <div class="flex flex-col gap-4">
      <CsatMetrics v-if="userTier === 'pertalite' || userTier === 'pertamax' || userTier === 'pertamax_turbo'" :filters="requestPayload" />

      <!-- CSAT Trends Line Chart -->
      <div v-if="userTier === 'pertamax' || userTier === 'pertamax_turbo'" class="flex flex-row flex-wrap max-w-full">
        <MetricCardFull class="w-full max-w-full">
          <template #header>
            <div class="flex items-center gap-2 flex-row">
              <h5 class="mb-0 text-n-slate-12 font-medium text-lg">
                {{ $t('CSAT_REPORTS.TRENDS.HEADER') }}
              </h5>
              <!-- <span
                v-if="selectedAgents.length > 0"
                class="flex flex-row items-center py-0.5 px-2 rounded bg-blue-100 dark:bg-blue-900/50 text-xs"
              >
                <span class="text-xs text-blue-700 dark:text-blue-400">
                  {{ selectedAgents.length }} {{ $t('CSAT_REPORTS.AGENTS_SELECTED') }}
                </span>
              </span> -->
            </div>
          </template>
          <div class="p-4">
            <div class="h-80">
              <LineChart2
                v-if="csatTrendData.length > 0"
                :datasets="csatTrendData"
              />
              <div v-else class="flex items-center justify-center h-full">
                <span class="text-sm text-gray-600 dark:text-gray-400">
                  {{ $t('REPORT.NO_ENOUGH_DATA') }}
                </span>
              </div>
            </div>
          </div>
        </MetricCardFull>
      </div>

      <CsatTable v-if="userTier === 'pertamax' || userTier === 'pertamax_turbo'" :page-index="pageIndex" @page-change="onPageNumberChange" />
    </div>
  </div>
</template>
