<template>
  <div class="flex-1 overflow-auto p-4">
    <woot-button
      color-scheme="success"
      class-names="button--fixed-top"
      icon="arrow-download"
      @click="downloadAgentReports"
    >
      {{ $t('REPORT.DOWNLOAD_AGENT_REPORTS') }}
    </woot-button>
    <report-filter-selector
      :show-labels-filter="true"
      :show-inbox-filter="true"
      :show-team-filter="true"
      :show-agents-filter="false"
      :show-group-by-filter="true"
      :show-rating-filter="true"
      :multiple-labels="true"
      :multiple-teams="true"
      :multiple-inboxes="true"
      :multiple-ratings="true"
      @filter-change="onFilterChange"
    />
    <report-container :group-by="groupBy" />
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import fromUnixTime from 'date-fns/fromUnixTime';
import format from 'date-fns/format';
import ReportFilterSelector from './components/FilterSelector.vue';
import { GROUP_BY_FILTER } from './constants';
import reportMixin from 'dashboard/mixins/reportMixin';
import alertMixin from 'shared/mixins/alertMixin';
import { REPORTS_EVENTS } from '../../../../helper/AnalyticsHelper/events';
import ReportContainer from './ReportContainer.vue';

const REPORTS_KEYS = {
  CONVERSATIONS: 'conversations_count',
  INCOMING_MESSAGES: 'incoming_messages_count',
  OUTGOING_MESSAGES: 'outgoing_messages_count',
  FIRST_RESPONSE_TIME: 'avg_first_response_time',
  RESOLUTION_TIME: 'avg_resolution_time',
  RESOLUTION_COUNT: 'resolutions_count',
  REPLY_TIME: 'reply_time',
};

export default {
  name: 'ConversationReports',
  components: {
    ReportFilterSelector,
    ReportContainer,
  },
  mixins: [reportMixin, alertMixin],
  data() {
    return {
      from: 0,
      to: 0,
      selectedLabel: [],
      selectedTeam: [],
      selectedInbox: [],
      selectedRating: [],
      groupBy: GROUP_BY_FILTER[1],
      businessHours: false,
    };
  },
  computed: {
    ...mapGetters({
      accountSummary: 'getAccountSummary',
      accountReport: 'getAccountReports',
    }),
  },
  methods: {
    fetchAllData() {
      this.fetchAccountSummary();
      this.fetchChartData();
    },
    fetchAccountSummary() {
      try {
        this.$store.dispatch('fetchAccountSummary', this.getRequestPayload());
      } catch (error) {
        this.showAlert(this.$t('REPORT.SUMMARY_FETCHING_FAILED'));
      }
    },
    fetchChartData() {
      [
        'CONVERSATIONS',
        'INCOMING_MESSAGES',
        'OUTGOING_MESSAGES',
        'FIRST_RESPONSE_TIME',
        'RESOLUTION_TIME',
        'RESOLUTION_COUNT',
        'REPLY_TIME',
      ].forEach(async key => {
        try {
          await this.$store.dispatch('fetchAccountReport', {
            metric: REPORTS_KEYS[key],
            ...this.getRequestPayload(),
          });
        } catch {
          this.showAlert(this.$t('REPORT.DATA_FETCHING_FAILED'));
        }
      });
    },
    getRequestPayload() {
      const { from, to, selectedLabel, selectedTeam, selectedInbox, selectedRating, groupBy, businessHours } = this;

      return {
        from,
        to,
        selectedLabel,
        selectedTeam,
        selectedInbox,
        selectedRating,
        groupBy: groupBy?.period,
        businessHours,
      };
    },
    downloadAgentReports() {
      const { from, to } = this;
      const fileName = `agent-report-${format(
        fromUnixTime(to),
        'dd-MM-yyyy'
      )}.csv`;
      this.$store.dispatch('downloadAgentReports', { from, to, fileName });
    },
    onFilterChange({ from, to, selectedLabel, selectedTeam, selectedInbox, selectedRating, groupBy, businessHours }) {
      this.from = from;
      this.to = to;
      this.selectedLabel = selectedLabel && selectedLabel.map(label => label.title);
      this.selectedTeam = selectedTeam && selectedTeam.map(team => team.id);
      this.selectedInbox = selectedInbox && selectedInbox.map(inbox => inbox.id);
      this.selectedRating = selectedRating && selectedRating.map(rating => rating.value)
      this.groupBy = groupBy;
      this.businessHours = businessHours;
      this.fetchAllData();

      this.$track(REPORTS_EVENTS.FILTER_REPORT, {
        filterValue: { from, to, selectedLabel, selectedTeam, selectedInbox, selectedRating, groupBy, businessHours },
        reportType: 'conversations',
      });
    },
  },
};
</script>
