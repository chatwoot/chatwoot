<script>
import { useAlert } from 'dashboard/composables';
import NextButton from 'dashboard/components-next/button/Button.vue';
import PageHeader from '../SettingsSubPageHeader.vue';

export default {
  name: 'ErrorReports',
  components: { PageHeader, NextButton },
  data() {
    return {
      reports: [],
      loading: false,
      page: 1,
      hasMore: false,
      platformFilter: '',
    };
  },
  computed: {
    filteredReports() {
      if (!this.platformFilter) return this.reports;
      return this.reports.filter(r => r.platform === this.platformFilter);
    },
  },
  mounted() {
    this.fetchReports();
  },
  methods: {
    async fetchReports() {
      this.loading = true;
      try {
        const { data } = await this.$store.dispatch('clientErrorReports/fetch', this.page);
        this.reports = this.page === 1 ? data : [...this.reports, ...data];
        this.hasMore = data.length === 50;
      } catch (error) {
        useAlert(error.message || 'Failed to load error reports');
      } finally {
        this.loading = false;
      }
    },
    formatTime(ts) {
      return new Date(ts).toLocaleString();
    },
    loadMore() {
      this.page += 1;
      this.fetchReports();
    },
  },
};
</script>

<template>
  <div class="flex flex-col h-full overflow-auto">
    <PageHeader
      header-title="Client Error Reports"
      header-content="Errors reported by the widget, dashboard, and desktop pet across your users' platforms. Use these to debug issues in production."
    />
    <div class="flex-1 px-6 py-4">
      <div class="flex gap-2 mb-4">
        <button
          class="px-3 py-1.5 text-xs rounded-full border"
          :class="platformFilter === '' ? 'bg-n-brand text-white border-n-brand' : 'border-n-slate-6 text-n-slate-11'"
          @click="platformFilter = ''"
        >All</button>
        <button
          v-for="p in ['widget', 'dashboard', 'pet']"
          :key="p"
          class="px-3 py-1.5 text-xs rounded-full border capitalize"
          :class="platformFilter === p ? 'bg-n-brand text-white border-n-brand' : 'border-n-slate-6 text-n-slate-11'"
          @click="platformFilter = p"
        >{{ p }}</button>
      </div>

      <div v-if="loading && reports.length === 0" class="text-center py-8 text-n-slate-10">
        Loading...
      </div>
      <div v-else-if="reports.length === 0" class="text-center py-8 text-n-slate-10">
        No errors reported yet. 🎉
      </div>

      <div v-else class="space-y-2">
        <div
          v-for="report in filteredReports"
          :key="report.id"
          class="p-3 border rounded-lg border-n-slate-6"
        >
          <div class="flex items-center justify-between">
            <span class="text-sm font-medium text-n-slate-12">{{ report.message }}</span>
            <span class="text-xs px-2 py-0.5 rounded-full bg-n-slate-3 text-n-slate-11 capitalize">{{ report.platform }}</span>
          </div>
          <div class="text-xs text-n-slate-10 mt-1">
            {{ formatTime(report.created_at) }} · v{{ report.app_version }} · {{ report.url }}
          </div>
          <pre v-if="report.stack" class="mt-2 text-[11px] bg-n-slate-2 p-2 rounded overflow-x-auto text-n-slate-11">{{ report.stack }}</pre>
        </div>

        <NextButton
          v-if="hasMore"
          ghost
          :label="loading ? 'Loading...' : 'Load more'"
          :disabled="loading"
          @click="loadMore"
        />
      </div>
    </div>
  </div>
</template>
