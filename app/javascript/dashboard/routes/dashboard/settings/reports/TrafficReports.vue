<template>
  <div class="flex-1 overflow-auto p-4">
    <div class="max-w-full flex flex-wrap flex-row ml-auto mr-auto">
      <metric-card :header="$t('TRAFFIC_REPORTS.HEADER')">
        <template #control>
          <woot-button
            icon="arrow-download"
            size="small"
            variant="smooth"
            color-scheme="secondary"
            @click="downloadHeatmapData"
          >
            {{ $t('TRAFFIC_REPORTS.DOWNLOAD_BUTTON') }}
          </woot-button>
        </template>
        <report-heatmap
          :heat-data="accountConversationHeatmap"
          :is-loading="uiFlags.isFetchingAccountConversationsHeatmap"
        />
      </metric-card>
    </div>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import MetricCard from './components/overview/MetricCard.vue';
import ReportHeatmap from './components/Heatmap.vue';

import endOfDay from 'date-fns/endOfDay';
import getUnixTime from 'date-fns/getUnixTime';
import startOfDay from 'date-fns/startOfDay';
import subDays from 'date-fns/subDays';

export default {
  name: 'TrafficReports',
  components: {
    MetricCard,
    ReportHeatmap,
  },
  data() {
    return {
      pageIndex: 1,
    };
  },
  computed: {
    ...mapGetters({
      accountConversationHeatmap: 'getAccountConversationHeatmapData',
      uiFlags: 'getOverviewUIFlags',
    }),
  },
  mounted() {
    this.fetchHeatmapData();

    bus.$on('fetch_traffic_reports', () => {
      this.fetchHeatmapData();
    });
  },
  methods: {
    downloadHeatmapData() {
      let to = endOfDay(new Date());

      this.$store.dispatch('downloadAccountConversationHeatmap', {
        to: getUnixTime(to),
      });
    },
    fetchHeatmapData() {
      if (this.uiFlags.isFetchingAccountConversationsHeatmap) {
        return;
      }

      // the data for the last 6 days won't ever change,
      // so there's no need to fetch it again
      // but we can write some logic to check if the data is already there
      // if it is there, we can refetch data only for today all over again
      // and reconcile it with the rest of the data
      // this will reduce the load on the server doing number crunching
      let to = endOfDay(new Date());
      let from = startOfDay(subDays(to, 13));

      if (this.accountConversationHeatmap.length) {
        to = endOfDay(new Date());
        from = startOfDay(to);
      }
      this.$store.dispatch('fetchAccountConversationHeatmap', {
        metric: 'conversations_count',
        from: getUnixTime(from),
        to: getUnixTime(to),
        groupBy: 'hour',
        businessHours: false,
      });
    },
  },
};
</script>
