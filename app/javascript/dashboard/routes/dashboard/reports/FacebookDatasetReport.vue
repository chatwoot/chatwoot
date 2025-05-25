<template>
  <div class="facebook-dataset-report">
    <div class="page-header">
      <h1 class="page-title">
        {{ $t('FACEBOOK_DATASET_REPORT.TITLE') }}
      </h1>
      <p class="page-description">
        {{ $t('FACEBOOK_DATASET_REPORT.DESCRIPTION') }}
      </p>
    </div>

    <!-- Filters -->
    <div class="filters-section">
      <div class="filter-group">
        <label>{{ $t('FACEBOOK_DATASET_REPORT.DATE_RANGE') }}</label>
        <div class="date-inputs">
          <input
            v-model="filters.startDate"
            type="date"
            class="form-input"
            @change="loadData"
          />
          <span>to</span>
          <input
            v-model="filters.endDate"
            type="date"
            class="form-input"
            @change="loadData"
          />
        </div>
      </div>

      <div class="filter-group">
        <label>{{ $t('FACEBOOK_DATASET_REPORT.INBOX') }}</label>
        <select
          v-model="filters.inboxId"
          class="form-select"
          @change="loadData"
        >
          <option value="">{{ $t('FACEBOOK_DATASET_REPORT.ALL_INBOXES') }}</option>
          <option
            v-for="inbox in inboxes"
            :key="inbox.id"
            :value="inbox.id"
          >
            {{ inbox.name }}
          </option>
        </select>
      </div>

      <div class="filter-group">
        <label>{{ $t('FACEBOOK_DATASET_REPORT.CONVERSION_STATUS') }}</label>
        <select
          v-model="filters.conversionStatus"
          class="form-select"
          @change="loadData"
        >
          <option value="">{{ $t('FACEBOOK_DATASET_REPORT.ALL_STATUS') }}</option>
          <option value="sent">{{ $t('FACEBOOK_DATASET_REPORT.SENT') }}</option>
          <option value="pending">{{ $t('FACEBOOK_DATASET_REPORT.PENDING') }}</option>
        </select>
      </div>

      <div class="filter-actions">
        <button
          type="button"
          class="btn btn-secondary"
          @click="exportData"
        >
          {{ $t('FACEBOOK_DATASET_REPORT.EXPORT') }}
        </button>
        <button
          type="button"
          class="btn btn-primary"
          @click="loadData"
        >
          {{ $t('FACEBOOK_DATASET_REPORT.REFRESH') }}
        </button>
      </div>
    </div>

    <!-- Loading State -->
    <div v-if="isLoading" class="loading-container">
      <spinner />
    </div>

    <!-- Stats Overview -->
    <div v-else-if="stats" class="stats-overview">
      <div class="stats-grid">
        <div class="stat-card">
          <div class="stat-value">{{ stats.total_trackings }}</div>
          <div class="stat-label">{{ $t('FACEBOOK_DATASET_REPORT.TOTAL_TRACKINGS') }}</div>
        </div>
        <div class="stat-card">
          <div class="stat-value">{{ stats.conversions_sent }}</div>
          <div class="stat-label">{{ $t('FACEBOOK_DATASET_REPORT.CONVERSIONS_SENT') }}</div>
        </div>
        <div class="stat-card">
          <div class="stat-value">{{ stats.pending_conversions }}</div>
          <div class="stat-label">{{ $t('FACEBOOK_DATASET_REPORT.PENDING_CONVERSIONS') }}</div>
        </div>
        <div class="stat-card">
          <div class="stat-value">{{ stats.unique_contacts }}</div>
          <div class="stat-label">{{ $t('FACEBOOK_DATASET_REPORT.UNIQUE_CONTACTS') }}</div>
        </div>
        <div class="stat-card">
          <div class="stat-value">{{ formatCurrency(stats.total_event_value) }}</div>
          <div class="stat-label">{{ $t('FACEBOOK_DATASET_REPORT.TOTAL_VALUE') }}</div>
        </div>
        <div class="stat-card">
          <div class="stat-value">{{ stats.unique_ads }}</div>
          <div class="stat-label">{{ $t('FACEBOOK_DATASET_REPORT.UNIQUE_ADS') }}</div>
        </div>
      </div>
    </div>

    <!-- Charts Section -->
    <div v-if="stats && !isLoading" class="charts-section">
      <div class="chart-container">
        <h3>{{ $t('FACEBOOK_DATASET_REPORT.DAILY_TRACKING_TREND') }}</h3>
        <line-chart
          :data="dailyChartData"
          :options="chartOptions"
          height="300"
        />
      </div>

      <div class="chart-container">
        <h3>{{ $t('FACEBOOK_DATASET_REPORT.CONVERSION_RATES_BY_SOURCE') }}</h3>
        <bar-chart
          :data="conversionRateChartData"
          :options="barChartOptions"
          height="300"
        />
      </div>
    </div>

    <!-- Top Performing Ads -->
    <div v-if="stats && stats.top_ads && !isLoading" class="top-ads-section">
      <h3>{{ $t('FACEBOOK_DATASET_REPORT.TOP_PERFORMING_ADS') }}</h3>
      <div class="ads-table">
        <table class="table">
          <thead>
            <tr>
              <th>{{ $t('FACEBOOK_DATASET_REPORT.AD_TITLE') }}</th>
              <th>{{ $t('FACEBOOK_DATASET_REPORT.AD_ID') }}</th>
              <th>{{ $t('FACEBOOK_DATASET_REPORT.TOTAL_TRACKINGS') }}</th>
              <th>{{ $t('FACEBOOK_DATASET_REPORT.CONVERSIONS_SENT') }}</th>
              <th>{{ $t('FACEBOOK_DATASET_REPORT.CONVERSION_RATE') }}</th>
              <th>{{ $t('FACEBOOK_DATASET_REPORT.TOTAL_VALUE') }}</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="ad in stats.top_ads" :key="ad.ad_id">
              <td>{{ ad.ad_title || '-' }}</td>
              <td>{{ ad.ad_id }}</td>
              <td>{{ ad.total_trackings }}</td>
              <td>{{ ad.conversions_sent }}</td>
              <td>{{ ad.conversion_rate }}%</td>
              <td>{{ formatCurrency(ad.total_value) }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Recent Tracking Data -->
    <div v-if="trackingData.length > 0 && !isLoading" class="recent-data-section">
      <div class="section-header">
        <h3>{{ $t('FACEBOOK_DATASET_REPORT.RECENT_TRACKING_DATA') }}</h3>
        <div class="bulk-actions">
          <button
            v-if="selectedTrackings.length > 0"
            type="button"
            class="btn btn-secondary"
            @click="bulkResendConversions"
          >
            {{ $t('FACEBOOK_DATASET_REPORT.BULK_RESEND') }} ({{ selectedTrackings.length }})
          </button>
        </div>
      </div>

      <div class="tracking-table">
        <table class="table">
          <thead>
            <tr>
              <th>
                <input
                  v-model="selectAll"
                  type="checkbox"
                  @change="toggleSelectAll"
                />
              </th>
              <th>{{ $t('FACEBOOK_DATASET_REPORT.DATE') }}</th>
              <th>{{ $t('FACEBOOK_DATASET_REPORT.CONTACT') }}</th>
              <th>{{ $t('FACEBOOK_DATASET_REPORT.INBOX') }}</th>
              <th>{{ $t('FACEBOOK_DATASET_REPORT.AD_ID') }}</th>
              <th>{{ $t('FACEBOOK_DATASET_REPORT.REF_PARAMETER') }}</th>
              <th>{{ $t('FACEBOOK_DATASET_REPORT.SOURCE') }}</th>
              <th>{{ $t('FACEBOOK_DATASET_REPORT.EVENT_VALUE') }}</th>
              <th>{{ $t('FACEBOOK_DATASET_REPORT.CONVERSION_STATUS') }}</th>
              <th>{{ $t('FACEBOOK_DATASET_REPORT.ACTIONS') }}</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="tracking in trackingData" :key="tracking.id">
              <td>
                <input
                  v-model="selectedTrackings"
                  type="checkbox"
                  :value="tracking.id"
                />
              </td>
              <td>{{ formatDate(tracking.created_at) }}</td>
              <td>{{ tracking.contact_name || tracking.contact_email || '-' }}</td>
              <td>{{ getInboxName(tracking.inbox_id) }}</td>
              <td>{{ tracking.ad_id || '-' }}</td>
              <td>{{ tracking.ref_parameter }}</td>
              <td>{{ tracking.referral_source }}</td>
              <td>{{ formatCurrency(tracking.event_value) }}</td>
              <td>
                <span
                  :class="[
                    'status-badge',
                    tracking.conversion_sent ? 'sent' : 'pending'
                  ]"
                >
                  {{
                    tracking.conversion_sent
                      ? $t('FACEBOOK_DATASET_REPORT.SENT')
                      : $t('FACEBOOK_DATASET_REPORT.PENDING')
                  }}
                </span>
              </td>
              <td>
                <button
                  v-if="!tracking.conversion_sent"
                  type="button"
                  class="btn btn-sm btn-secondary"
                  @click="resendConversion(tracking.id)"
                >
                  {{ $t('FACEBOOK_DATASET_REPORT.RESEND') }}
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Pagination -->
      <div v-if="pagination" class="pagination-container">
        <button
          :disabled="pagination.current_page <= 1"
          class="btn btn-secondary"
          @click="loadPage(pagination.current_page - 1)"
        >
          {{ $t('FACEBOOK_DATASET_REPORT.PREVIOUS') }}
        </button>
        <span class="pagination-info">
          {{ $t('FACEBOOK_DATASET_REPORT.PAGE_INFO', {
            current: pagination.current_page,
            total: pagination.total_pages
          }) }}
        </span>
        <button
          :disabled="pagination.current_page >= pagination.total_pages"
          class="btn btn-secondary"
          @click="loadPage(pagination.current_page + 1)"
        >
          {{ $t('FACEBOOK_DATASET_REPORT.NEXT') }}
        </button>
      </div>
    </div>

    <!-- Empty State -->
    <div v-else-if="!isLoading" class="empty-state">
      <p>{{ $t('FACEBOOK_DATASET_REPORT.NO_DATA') }}</p>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import Spinner from 'shared/components/Spinner.vue';
import LineChart from 'shared/components/charts/LineChart.vue';
import BarChart from 'shared/components/charts/BarChart.vue';
import FacebookDatasetAPI from '../../../api/accounts/facebookDataset';
import { useAlert } from 'dashboard/composables';

export default {
  name: 'FacebookDatasetReport',
  components: {
    Spinner,
    LineChart,
    BarChart,
  },
  data() {
    return {
      isLoading: true,
      stats: null,
      trackingData: [],
      pagination: null,
      selectedTrackings: [],
      selectAll: false,
      filters: {
        startDate: this.getDefaultStartDate(),
        endDate: this.getDefaultEndDate(),
        inboxId: '',
        conversionStatus: '',
      },
      chartOptions: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          y: {
            beginAtZero: true,
          },
        },
      },
      barChartOptions: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          y: {
            beginAtZero: true,
            max: 100,
          },
        },
      },
    };
  },
  computed: {
    ...mapGetters({
      inboxes: 'inboxes/getInboxes',
      currentAccount: 'accounts/getAccount',
    }),
    dailyChartData() {
      if (!this.stats?.daily_stats) return { labels: [], datasets: [] };

      const labels = this.stats.daily_stats.map(stat =>
        new Date(stat.date).toLocaleDateString()
      );
      const trackingData = this.stats.daily_stats.map(stat => stat.total);
      const conversionData = this.stats.daily_stats.map(stat => stat.conversions_sent);

      return {
        labels,
        datasets: [
          {
            label: this.$t('FACEBOOK_DATASET_REPORT.TOTAL_TRACKINGS'),
            data: trackingData,
            borderColor: 'rgb(75, 192, 192)',
            backgroundColor: 'rgba(75, 192, 192, 0.2)',
          },
          {
            label: this.$t('FACEBOOK_DATASET_REPORT.CONVERSIONS_SENT'),
            data: conversionData,
            borderColor: 'rgb(255, 99, 132)',
            backgroundColor: 'rgba(255, 99, 132, 0.2)',
          },
        ],
      };
    },
    conversionRateChartData() {
      if (!this.stats?.conversion_rates) return { labels: [], datasets: [] };

      const labels = this.stats.conversion_rates.map(rate => rate.source);
      const rates = this.stats.conversion_rates.map(rate => rate.conversion_rate);

      return {
        labels,
        datasets: [
          {
            label: this.$t('FACEBOOK_DATASET_REPORT.CONVERSION_RATE'),
            data: rates,
            backgroundColor: [
              'rgba(255, 99, 132, 0.8)',
              'rgba(54, 162, 235, 0.8)',
              'rgba(255, 205, 86, 0.8)',
              'rgba(75, 192, 192, 0.8)',
              'rgba(153, 102, 255, 0.8)',
            ],
          },
        ],
      };
    },
  },
  mounted() {
    this.loadData();
  },
  methods: {
    async loadData() {
      try {
        this.isLoading = true;

        // Load stats
        const statsResponse = await FacebookDatasetAPI.getStats(this.filters);
        this.stats = statsResponse.data;

        // Load tracking data
        await this.loadTrackingData();
      } catch (error) {
        useAlert(this.$t('FACEBOOK_DATASET_REPORT.LOAD_ERROR'));
      } finally {
        this.isLoading = false;
      }
    },

    async loadTrackingData(page = 1) {
      try {
        const response = await FacebookDatasetAPI.getTrackingData({
          ...this.filters,
          page,
          per_page: 20,
        });
        this.trackingData = response.data.data;
        this.pagination = response.data.pagination;
      } catch (error) {
        console.error('Error loading tracking data:', error);
      }
    },

    async loadPage(page) {
      await this.loadTrackingData(page);
    },

    async resendConversion(trackingId) {
      try {
        await FacebookDatasetAPI.resendConversion(trackingId);
        useAlert(this.$t('FACEBOOK_DATASET_REPORT.RESEND_SUCCESS'));
        await this.loadTrackingData();
      } catch (error) {
        useAlert(this.$t('FACEBOOK_DATASET_REPORT.RESEND_ERROR'));
      }
    },

    async bulkResendConversions() {
      try {
        await FacebookDatasetAPI.bulkResend({
          tracking_ids: this.selectedTrackings,
        });
        useAlert(this.$t('FACEBOOK_DATASET_REPORT.BULK_RESEND_SUCCESS'));
        this.selectedTrackings = [];
        this.selectAll = false;
        await this.loadTrackingData();
      } catch (error) {
        useAlert(this.$t('FACEBOOK_DATASET_REPORT.BULK_RESEND_ERROR'));
      }
    },

    async exportData() {
      try {
        const response = await FacebookDatasetAPI.export(this.filters);

        // Create download link
        const blob = new Blob([response.data], { type: 'text/csv' });
        const url = window.URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.download = `facebook_dataset_${Date.now()}.csv`;
        link.click();
        window.URL.revokeObjectURL(url);

        useAlert(this.$t('FACEBOOK_DATASET_REPORT.EXPORT_SUCCESS'));
      } catch (error) {
        useAlert(this.$t('FACEBOOK_DATASET_REPORT.EXPORT_ERROR'));
      }
    },

    toggleSelectAll() {
      if (this.selectAll) {
        this.selectedTrackings = this.trackingData.map(tracking => tracking.id);
      } else {
        this.selectedTrackings = [];
      }
    },

    getInboxName(inboxId) {
      const inbox = this.inboxes.find(i => i.id === inboxId);
      return inbox ? inbox.name : '-';
    },

    formatDate(dateString) {
      return new Date(dateString).toLocaleString();
    },

    formatCurrency(value) {
      if (!value) return '$0.00';
      return new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: 'USD',
      }).format(value);
    },

    getDefaultStartDate() {
      const date = new Date();
      date.setDate(date.getDate() - 30);
      return date.toISOString().split('T')[0];
    },

    getDefaultEndDate() {
      return new Date().toISOString().split('T')[0];
    },
  },
};
</script>

<style scoped lang="scss">
.facebook-dataset-report {
  padding: 1.5rem;

  .page-header {
    margin-bottom: 2rem;

    .page-title {
      font-size: 1.5rem;
      font-weight: 600;
      margin-bottom: 0.5rem;
      color: var(--color-heading);
    }

    .page-description {
      color: var(--color-body);
      line-height: 1.5;
    }
  }

  .filters-section {
    background: var(--color-background-light);
    border: 1px solid var(--color-border);
    border-radius: 8px;
    padding: 1.5rem;
    margin-bottom: 2rem;
    display: flex;
    flex-wrap: wrap;
    gap: 1rem;
    align-items: end;

    .filter-group {
      min-width: 200px;

      label {
        display: block;
        font-weight: 500;
        margin-bottom: 0.5rem;
        color: var(--color-heading);
      }

      .date-inputs {
        display: flex;
        align-items: center;
        gap: 0.5rem;

        span {
          color: var(--color-body);
          font-size: 0.875rem;
        }
      }

      .form-input,
      .form-select {
        width: 100%;
        padding: 0.75rem;
        border: 1px solid var(--color-border);
        border-radius: 4px;
        font-size: 0.875rem;

        &:focus {
          outline: none;
          border-color: var(--color-primary);
          box-shadow: 0 0 0 2px var(--color-primary-light);
        }
      }
    }

    .filter-actions {
      display: flex;
      gap: 0.5rem;

      .btn {
        padding: 0.75rem 1.5rem;
        border-radius: 4px;
        font-weight: 500;
        cursor: pointer;
        border: none;

        &.btn-primary {
          background: var(--color-primary);
          color: white;

          &:hover {
            background: var(--color-primary-dark);
          }
        }

        &.btn-secondary {
          background: var(--color-background);
          color: var(--color-body);
          border: 1px solid var(--color-border);

          &:hover {
            background: var(--color-background-light);
          }
        }
      }
    }
  }

  .loading-container {
    display: flex;
    justify-content: center;
    padding: 3rem;
  }

  .stats-overview {
    margin-bottom: 2rem;

    .stats-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 1rem;

      .stat-card {
        background: var(--color-background-light);
        border: 1px solid var(--color-border);
        border-radius: 8px;
        padding: 1.5rem;
        text-align: center;

        .stat-value {
          font-size: 2rem;
          font-weight: 600;
          color: var(--color-primary);
          margin-bottom: 0.5rem;
        }

        .stat-label {
          font-size: 0.875rem;
          color: var(--color-body);
        }
      }
    }
  }

  .charts-section {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 2rem;
    margin-bottom: 2rem;

    .chart-container {
      background: var(--color-background-light);
      border: 1px solid var(--color-border);
      border-radius: 8px;
      padding: 1.5rem;

      h3 {
        margin-bottom: 1rem;
        color: var(--color-heading);
        font-size: 1.125rem;
      }
    }
  }

  .top-ads-section,
  .recent-data-section {
    background: var(--color-background-light);
    border: 1px solid var(--color-border);
    border-radius: 8px;
    padding: 1.5rem;
    margin-bottom: 2rem;

    h3 {
      margin-bottom: 1rem;
      color: var(--color-heading);
      font-size: 1.125rem;
    }

    .section-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 1rem;

      .bulk-actions {
        .btn {
          padding: 0.5rem 1rem;
          border-radius: 4px;
          font-weight: 500;
          cursor: pointer;
          border: none;
          background: var(--color-secondary);
          color: white;

          &:hover {
            background: var(--color-secondary-dark);
          }
        }
      }
    }
  }

  .ads-table,
  .tracking-table {
    overflow-x: auto;

    .table {
      width: 100%;
      border-collapse: collapse;

      th,
      td {
        padding: 0.75rem;
        text-align: left;
        border-bottom: 1px solid var(--color-border);
      }

      th {
        background: var(--color-background);
        font-weight: 600;
        color: var(--color-heading);
        position: sticky;
        top: 0;
      }

      .status-badge {
        padding: 0.25rem 0.5rem;
        border-radius: 12px;
        font-size: 0.75rem;
        font-weight: 500;

        &.sent {
          background: var(--color-success-light);
          color: var(--color-success);
        }

        &.pending {
          background: var(--color-warning-light);
          color: var(--color-warning);
        }
      }

      .btn-sm {
        padding: 0.375rem 0.75rem;
        font-size: 0.75rem;
        border-radius: 4px;
        border: none;
        cursor: pointer;

        &.btn-secondary {
          background: var(--color-background);
          color: var(--color-body);
          border: 1px solid var(--color-border);

          &:hover {
            background: var(--color-background-light);
          }
        }
      }
    }
  }

  .pagination-container {
    display: flex;
    justify-content: center;
    align-items: center;
    gap: 1rem;
    margin-top: 1rem;

    .btn {
      padding: 0.5rem 1rem;
      border-radius: 4px;
      border: 1px solid var(--color-border);
      background: var(--color-background);
      color: var(--color-body);
      cursor: pointer;

      &:disabled {
        opacity: 0.5;
        cursor: not-allowed;
      }

      &:hover:not(:disabled) {
        background: var(--color-background-light);
      }
    }

    .pagination-info {
      font-size: 0.875rem;
      color: var(--color-body);
    }
  }

  .empty-state {
    text-align: center;
    padding: 3rem;
    color: var(--color-body-light);

    p {
      font-size: 1.125rem;
    }
  }
}

// Responsive design
@media (max-width: 1024px) {
  .facebook-dataset-report {
    .charts-section {
      grid-template-columns: 1fr;
    }

    .filters-section {
      flex-direction: column;
      align-items: stretch;

      .filter-group {
        min-width: auto;
      }

      .filter-actions {
        justify-content: flex-end;
      }
    }
  }
}

@media (max-width: 768px) {
  .facebook-dataset-report {
    padding: 1rem;

    .stats-overview .stats-grid {
      grid-template-columns: repeat(2, 1fr);
    }

    .filters-section .filter-actions {
      flex-direction: column;
    }

    .recent-data-section .section-header {
      flex-direction: column;
      align-items: flex-start;
      gap: 1rem;
    }
  }
}

@media (max-width: 480px) {
  .facebook-dataset-report {
    .stats-overview .stats-grid {
      grid-template-columns: 1fr;
    }
  }
}
</style>
