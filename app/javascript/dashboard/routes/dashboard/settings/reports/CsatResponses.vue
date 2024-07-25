<template>
  <div class="flex-1 p-4 overflow-auto">
    <report-filter-selector
      :show-agents-filter="true"
      :show-inbox-filter="true"
      :show-rating-filter="true"
      :show-team-filter="isTeamsEnabled"
      :show-business-hours-switch="false"
      @filter-change="onFilterChange"
    />
    <woot-button
      color-scheme="success"
      class-names="button--fixed-top"
      icon="arrow-download"
      @click="downloadReports"
    >
      {{ $t('CSAT_REPORTS.DOWNLOAD') }}
    </woot-button>
    <csat-metrics :filters="requestPayload" />
    <csat-table :page-index="pageIndex" @page-change="onPageNumberChange" />
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import CsatMetrics from './components/CsatMetrics.vue';
import CsatTable from './components/CsatTable.vue';
import ReportFilterSelector from './components/FilterSelector.vue';
import { generateFileName } from '../../../../helper/downloadHelper';
import { REPORTS_EVENTS } from '../../../../helper/AnalyticsHelper/events';
import { FEATURE_FLAGS } from '../../../../featureFlags';

export default {
  name: 'CsatResponses',
  components: {
    CsatMetrics,
    CsatTable,
    ReportFilterSelector,
  },
  data() {
    return {
      pageIndex: 1,
      from: 0,
      to: 0,
      userIds: [],
      inbox: null,
      team: null,
      rating: null,
    };
  },
  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
      isFeatureEnabledOnAccount: 'accounts/isFeatureEnabledonAccount',
    }),
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
    isTeamsEnabled() {
      return this.isFeatureEnabledOnAccount(
        this.accountId,
        FEATURE_FLAGS.TEAM_MANAGEMENT
      );
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
        page: this.pageIndex,
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
        this.$track(REPORTS_EVENTS.FILTER_REPORT, {
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
  },
};
</script>
