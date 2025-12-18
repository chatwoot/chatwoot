<script>
import { useAlert, useTrack } from 'dashboard/composables';
import ReportFilterSelector from './components/FilterSelector.vue';
import { GROUP_BY_FILTER } from './constants';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import { STATUS } from 'dashboard/store/constants';
import { REPORTS_EVENTS } from '../../../../helper/AnalyticsHelper/events';
import ReportContainer from './ReportContainer.vue';
import ReportHeader from './components/ReportHeader.vue';

const REPORTS_KEYS = {
  LINKS_SENT: 'booking_links_sent',
  FORMS_COMPLETED: 'booking_forms_completed',
};

export default {
  name: 'BookingsReports',
  components: {
    ReportHeader,
    ReportFilterSelector,
    ReportContainer,
    Spinner,
  },
  data() {
    return {
      from: 0,
      to: 0,
      groupBy: GROUP_BY_FILTER[1],
      businessHours: false,
    };
  },

  computed: {
    summary() {
      return this.$store.getters.getBookingSummary || {};
    },

    linksSent() {
      return this.summary.booking_links_sent || 0;
    },

    formsCompleted() {
      return this.summary.booking_forms_completed || 0;
    },

    conversionRate() {
      if (this.linksSent === 0) return 0;
      return Math.round((this.formsCompleted / this.linksSent) * 100);
    },

    generatedValue() {
      return this.formsCompleted * 250;
    },

    fetchingStatus() {
      return this.$store.getters.getBookingSummaryFetchingStatus;
    },

    isLoading() {
      return this.fetchingStatus === STATUS.FETCHING;
    },
  },

  mounted() {
    this.fetchAllData();
  },

  methods: {
    fetchAllData() {
      this.fetchBookingSummary();
      this.fetchChartData();
    },
    fetchBookingSummary() {
      try {
        this.$store.dispatch('fetchBookingSummary', this.getRequestPayload());
      } catch {
        useAlert(this.$t('REPORT.SUMMARY_FETCHING_FAILED'));
      }
    },
    async fetchChartData() {
      const payload = this.getRequestPayload();

      try {
        await Promise.all([
          this.$store.dispatch('fetchAccountReport', {
            metric: REPORTS_KEYS.LINKS_SENT,
            ...payload,
          }),
          this.$store.dispatch('fetchAccountReport', {
            metric: REPORTS_KEYS.FORMS_COMPLETED,
            ...payload,
          }),
        ]);
      } catch {
        useAlert(this.$t('REPORT.DATA_FETCHING_FAILED'));
      }
    },
    getRequestPayload() {
      return {
        from: this.from,
        to: this.to,
        groupBy: this.groupBy?.period,
        businessHours: this.businessHours,
      };
    },
    onFilterChange({ from, to, groupBy, businessHours }) {
      this.from = from;
      this.to = to;
      this.groupBy = groupBy;
      this.businessHours = businessHours;
      this.fetchAllData();

      useTrack(REPORTS_EVENTS.FILTER_REPORT, {
        filterValue: { from, to, groupBy, businessHours },
        reportType: 'bookings',
      });
    },
  },
};
</script>

<template>
  <ReportHeader :header-title="$t('BOOKINGS_REPORTS.HEADER')" />
  <div class="flex flex-col gap-3">
    <ReportFilterSelector
      :show-agents-filter="false"
      :show-business-hours-switch="false"
      show-group-by-filter
      @filter-change="onFilterChange"
    />

    <!-- EXISTING GRAPHS & COUNTS -->
    <ReportContainer
      :group-by="groupBy"
      :report-keys="{
        LINKS_SENT: 'booking_links_sent',
        FORMS_COMPLETED: 'booking_forms_completed',
      }"
      account-summary-key="getBookingSummary"
      summary-fetching-key="getBookingSummaryFetchingStatus"
    />
    <div
      class="grid grid-cols-2 gap-4 p-4 rounded-xl border border-n-container shadow-md mt-2 dark:bg-n-solid-2"
    >
      <!-- CONVERSION RATE -->
      <div
        class="flex flex-col p-4 rounded-lg border border-n-container shadow-md bg-n-gray-2 dark:bg-n-solid-1 dark:border-n-gray-2"
      >
        <span class="text-sm opacity-70">{{
          $t('REPORT.METRICS.CONVERSION_RATE.NAME')
        }}</span>
        <div v-if="isLoading" class="min-h-[2.25rem] flex items-center text-n-slate-12">
          <Spinner />
        </div>
        <span v-else class="text-3xl font-bold"
          >{{ conversionRate
          }}{{ $t('REPORT.METRICS.CONVERSION_RATE.DESC') }}</span
        >
      </div>

      <!-- GENERATED VALUE -->
      <div
        class="flex flex-col p-4 rounded-lg border border-n-container shadow-md bg-n-gray-2 dark:bg-n-solid-1 dark:border-n-gray-2"
      >
        <span class="text-sm opacity-70">{{
          $t('REPORT.METRICS.GENERATED_VALUE.NAME')
        }}</span>
        <div v-if="isLoading" class="min-h-[2.25rem] flex items-center text-n-slate-12">
          <Spinner />
        </div>
        <span v-else class="text-3xl font-bold text-green-400"
          >{{ $t('REPORT.METRICS.GENERATED_VALUE.DESC')
          }}{{ generatedValue }}</span
        >
      </div>
    </div>
  </div>
</template>
