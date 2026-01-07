<template>
  <div
    class="metric-card flex flex-col m-2 p-4 border border-solid overflow-hidden rounded-md flex-grow shadow-sm text-slate-700 dark:text-slate-100 bg-white dark:bg-slate-800 border-slate-75 dark:border-slate-700 min-h-[10rem]"
  >
    <div class="card-header">
      <slot name="header">
        <div class="flex items-center gap-0.5 flex-row">
          <h5
            class="mb-0 text-slate-800 dark:text-slate-100 font-medium text-xl"
          >
            {{ header }}
          </h5>
          <span
            v-if="isLive"
            class="flex flex-row items-center pr-2 pl-2 m-1 rounded-sm text-green-400 dark:text-green-400 text-xs bg-green-100/30 dark:bg-green-100/20"
          >
            <span
              class="bg-green-500 dark:bg-green-500 h-1 w-1 rounded-full mr-1 rtl:mr-0 rtl:ml-0"
            />
            <span>
              {{ $t('OVERVIEW_REPORTS.LIVE') }}
            </span>
          </span>
        </div>
        <div class="card-header--control-area">
          <woot-button
            v-if="showDownloadButton"
            class="ml-auto"
            variant="clear"
            icon="arrow-download"
            @click="openDownloadModal"
          >
            Download Report
          </woot-button>
          <slot name="control" />
        </div>
      </slot>
    </div>
    <div
      v-if="!isLoading"
      :class="[!isLive ? 'px-0' : '', customClass]"
      class="card-body max-w-full w-full ml-auto mr-auto justify-between flex"
    >
      <slot />
    </div>
    <div
      v-else-if="isLoading"
      class="items-center flex text-base justify-center px-12 py-6"
    >
      <spinner />
      <span class="text-slate-300 dark:text-slate-200">
        {{ loadingMessage }}
      </span>
    </div>
    <woot-modal :show="showDownloadModal" :on-close="closeDownloadModal">
      <div class="h-auto overflow-auto flex flex-col">
        <woot-modal-header
          :header-title="'Enter Email Address'"
          :header-content="'We will send the report on this email.'"
        />
        <form class="w-full" @submit.prevent="sendReport">
          <label class="block">
            <span class="text-gray-700">Email Address</span>
            <input
              v-model="emailAddress"
              type="email"
              class="mt-4 block w-full rounded-md border-gray-300 shadow-sm"
              placeholder="Enter your email address"
              required
            />
          </label>
          <div class="flex justify-end mt-6 space-x-2">
            <woot-button
              class="button clear"
              @click.prevent="closeDownloadModal"
            >
              Cancel
            </woot-button>
            <woot-button type="submit"> Send Report </woot-button>
          </div>
        </form>
      </div>
    </woot-modal>
  </div>
</template>
<script>
import Spinner from 'shared/components/Spinner.vue';
import alertMixin from 'shared/mixins/alertMixin';
import CustomReportsAPI from 'dashboard/api/customReports';
import reportsAPI from 'dashboard/api/reports';

export default {
  name: 'MetricCard',
  components: {
    Spinner,
  },
  mixins: [alertMixin],
  props: {
    isLive: {
      type: Boolean,
      default: true,
    },
    header: {
      type: String,
      default: '',
    },
    isLoading: {
      type: Boolean,
      default: false,
    },
    loadingMessage: {
      type: String,
      default: '',
    },
    isFilter: {
      type: Boolean,
      default: false,
    },
    showDownloadButton: {
      type: Boolean,
      default: false,
    },
    downloadFilters: {
      type: Object,
      default: () => ({}),
    },
    downloadType: {
      type: String,
      default: '',
    },
    customClass: {
      type: String,
      default: '',
    },
  },
  data() {
    return {
      showDownloadModal: false,
      emailAddress: '',
    };
  },
  methods: {
    openDownloadModal() {
      if (
        this.downloadType === 'labelOverview' ||
        this.downloadType === 'labelConversationStates'
      ) {
        this.downloadLabelReport();
        return;
      }
      this.showDownloadModal = true;
    },
    closeDownloadModal() {
      this.showDownloadModal = false;
      this.emailAddress = '';
    },
    async sendReport() {
      if (this.downloadType === 'overview') {
        await CustomReportsAPI.downloadCustomAgentOverviewReports({
          ...this.downloadFilters,
          email: this.emailAddress,
        });
      } else if (this.downloadType === 'conversationStates') {
        await CustomReportsAPI.downloadCustomAgentWiseConversationStatesReports(
          {
            ...this.downloadFilters,
            email: this.emailAddress,
          }
        );
      } else if (this.downloadType === 'botAnalyticsOverview') {
        await CustomReportsAPI.downloadCustomBotAnalyticsOverviewReports({
          ...this.downloadFilters,
          email: this.emailAddress,
        });
      } else if (this.downloadType === 'botAnalyticsSalesOverview') {
        await CustomReportsAPI.downloadCustomBotAnalyticsSalesOverviewReports({
          ...this.downloadFilters,
          email: this.emailAddress,
        });
      } else if (this.downloadType === 'liveChatSalesOverview') {
        await CustomReportsAPI.downloadCustomLiveChatAnalyticsSalesOverviewReports(
          {
            ...this.downloadFilters,
            email: this.emailAddress,
          }
        );
      } else if (this.downloadType === 'botAnalyticsSupportOverview') {
        await CustomReportsAPI.downloadCustomBotAnalyticsSupportOverviewReports(
          {
            ...this.downloadFilters,
            email: this.emailAddress,
          }
        );
      } else if (this.downloadType === 'liveChatSupportOverview') {
        await CustomReportsAPI.downloadCustomLiveChatAnalyticsSupportOverviewReports(
          {
            ...this.downloadFilters,
            email: this.emailAddress,
          }
        );
      } else if (this.downloadType === 'callOverview') {
        const endDate = new Date(this.downloadFilters.until * 1000)
          .toISOString()
          .split('T')[0];
        const startDate = new Date(this.downloadFilters.since * 1000)
          .toISOString()
          .split('T')[0];
        await CustomReportsAPI.getCallLogsReport({
          startDate,
          endDate,
          email: this.emailAddress,
        });
      }

      this.showAlert('Report sent successfully!');
      this.closeDownloadModal();
    },
    async downloadLabelReport() {
      try {
        const { since, until, businessHours } = this.downloadFilters;
        const response = await reportsAPI.getLabelReports({
          from: since,
          to: until,
          businessHours,
        });
        const blob = new Blob([response.data], { type: 'text/csv' });
        const url = window.URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.setAttribute(
          'download',
          `label_report_${new Date().toISOString().split('T')[0]}.csv`
        );
        document.body.appendChild(link);
        link.click();
        link.remove();
        window.URL.revokeObjectURL(url);
      } catch (error) {
        this.showAlert(this.$t('LABEL_REPORTS.DOWNLOAD_ERROR'));
      }
    },
  },
};
</script>
<style lang="scss" scoped>
.metric-card {
  @apply flex flex-col mb-2 p-4 border border-solid overflow-hidden rounded-md flex-grow shadow-sm text-slate-700 dark:text-slate-100 bg-white dark:bg-slate-800 border-slate-75 dark:border-slate-700 min-h-[10rem];

  .card-header--control-area {
    transition: opacity 0.2s ease-in-out;
    @apply opacity-20;
  }

  &:hover {
    .card-header--control-area {
      @apply opacity-100;
    }
  }
}

.card-header {
  grid-template-columns: repeat(auto-fit, minmax(max-content, 50%));
  gap: var(--space-small) 0px;
  @apply grid flex-grow w-full mb-6;

  .card-header--control-area {
    @apply flex flex-row items-center justify-end gap-2;
  }
}

.card-body {
  .metric-content {
    @apply pb-2;

    .heading {
      @apply text-base text-slate-700 dark:text-slate-100;
    }

    .metric {
      @apply text-woot-800 dark:text-woot-300 text-3xl mb-0 mt-1;
    }
  }
}
</style>
