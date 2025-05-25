<template>
  <div class="facebook-dataset-settings">
    <div class="settings-header">
      <h3 class="block-title">
        {{ $t('INBOX_MGMT.FACEBOOK_DATASET.TITLE') }}
      </h3>
      <p class="block-description">
        {{ $t('INBOX_MGMT.FACEBOOK_DATASET.DESCRIPTION') }}
      </p>
    </div>

    <div v-if="isLoading" class="spinner-container">
      <spinner />
    </div>

    <div v-else class="settings-content">
      <!-- Enable/Disable Toggle -->
      <div class="settings-item">
        <label class="toggle-label">
          <input
            v-model="config.enabled"
            type="checkbox"
            class="toggle-input"
            @change="onToggleChange"
          />
          <span class="toggle-slider"></span>
          {{ $t('INBOX_MGMT.FACEBOOK_DATASET.ENABLE_TRACKING') }}
        </label>
      </div>

      <!-- Configuration Form -->
      <div v-if="config.enabled" class="config-form">
        <!-- Auto-fetch Facebook Pixels -->
        <div class="form-group">
          <label for="pixel_selection">
            {{ $t('INBOX_MGMT.FACEBOOK_DATASET.PIXEL_SELECTION') }}
            <span class="required">*</span>
          </label>
          <div class="pixel-selection-container">
            <button
              v-if="!pixelsLoaded"
              type="button"
              class="btn btn-primary btn-fetch-pixels"
              :disabled="isFetchingPixels"
              @click="fetchFacebookPixels"
            >
              <spinner v-if="isFetchingPixels" size="small" />
              {{ isFetchingPixels ? $t('INBOX_MGMT.FACEBOOK_DATASET.FETCHING_PIXELS') : $t('INBOX_MGMT.FACEBOOK_DATASET.FETCH_PIXELS') }}
            </button>

            <div v-if="pixelsLoaded" class="pixel-dropdown-container">
              <select
                id="pixel_selection"
                v-model="selectedPixelId"
                class="form-select pixel-select"
                @change="onPixelSelect"
              >
                <option value="">{{ $t('INBOX_MGMT.FACEBOOK_DATASET.SELECT_PIXEL') }}</option>
                <option
                  v-for="pixel in availablePixels"
                  :key="pixel.id"
                  :value="pixel.id"
                  :title="pixel.name"
                >
                  {{ pixel.name }} ({{ pixel.id }})
                </option>
              </select>
              <button
                type="button"
                class="btn btn-secondary btn-refresh-pixels"
                :disabled="isFetchingPixels"
                @click="fetchFacebookPixels"
              >
                <i class="icon ion-refresh"></i>
              </button>
            </div>

            <!-- Manual input fallback -->
            <div v-if="showManualInput" class="manual-input-container">
              <input
                id="pixel_id_manual"
                v-model="config.pixel_id"
                type="text"
                class="form-input"
                :placeholder="$t('INBOX_MGMT.FACEBOOK_DATASET.PIXEL_ID_PLACEHOLDER')"
                required
              />
            </div>

            <button
              v-if="pixelsLoaded"
              type="button"
              class="btn btn-link btn-toggle-manual"
              @click="toggleManualInput"
            >
              {{ showManualInput ? $t('INBOX_MGMT.FACEBOOK_DATASET.USE_DROPDOWN') : $t('INBOX_MGMT.FACEBOOK_DATASET.ENTER_MANUALLY') }}
            </button>
          </div>
        </div>

        <!-- Access Token - Auto-generated or Manual -->
        <div class="form-group">
          <label for="access_token">
            {{ $t('INBOX_MGMT.FACEBOOK_DATASET.ACCESS_TOKEN') }}
            <span class="required">*</span>
          </label>
          <div class="access-token-container">
            <div v-if="config.access_token && !showTokenInput" class="token-display">
              <span class="token-masked">{{ maskedToken }}</span>
              <button
                type="button"
                class="btn btn-link btn-edit-token"
                @click="showTokenInput = true"
              >
                {{ $t('INBOX_MGMT.FACEBOOK_DATASET.EDIT_TOKEN') }}
              </button>
            </div>
            <div v-else class="token-input-container">
              <input
                id="access_token"
                v-model="config.access_token"
                type="password"
                class="form-input"
                :placeholder="$t('INBOX_MGMT.FACEBOOK_DATASET.ACCESS_TOKEN_PLACEHOLDER')"
                required
              />
              <button
                v-if="selectedPixelId && !config.access_token"
                type="button"
                class="btn btn-primary btn-generate-token"
                :disabled="isGeneratingToken"
                @click="generateAccessToken"
              >
                <spinner v-if="isGeneratingToken" size="small" />
                {{ isGeneratingToken ? $t('INBOX_MGMT.FACEBOOK_DATASET.GENERATING_TOKEN') : $t('INBOX_MGMT.FACEBOOK_DATASET.GENERATE_TOKEN') }}
              </button>
            </div>
          </div>
        </div>

        <div class="form-group">
          <label for="test_event_code">
            {{ $t('INBOX_MGMT.FACEBOOK_DATASET.TEST_EVENT_CODE') }}
          </label>
          <input
            id="test_event_code"
            v-model="config.test_event_code"
            type="text"
            class="form-input"
            :placeholder="$t('INBOX_MGMT.FACEBOOK_DATASET.TEST_EVENT_CODE_PLACEHOLDER')"
          />
          <small class="form-help">
            {{ $t('INBOX_MGMT.FACEBOOK_DATASET.TEST_EVENT_CODE_HELP') }}
          </small>
        </div>

        <div class="form-row">
          <div class="form-group">
            <label for="default_event_name">
              {{ $t('INBOX_MGMT.FACEBOOK_DATASET.DEFAULT_EVENT_NAME') }}
            </label>
            <select
              id="default_event_name"
              v-model="config.default_event_name"
              class="form-select"
            >
              <option value="Lead">Lead</option>
              <option value="Contact">Contact</option>
              <option value="InitiateCheckout">Initiate Checkout</option>
              <option value="Purchase">Purchase</option>
              <option value="CompleteRegistration">Complete Registration</option>
            </select>
          </div>

          <div class="form-group">
            <label for="default_event_value">
              {{ $t('INBOX_MGMT.FACEBOOK_DATASET.DEFAULT_EVENT_VALUE') }}
            </label>
            <input
              id="default_event_value"
              v-model.number="config.default_event_value"
              type="number"
              step="0.01"
              class="form-input"
              placeholder="0.00"
            />
          </div>

          <div class="form-group">
            <label for="default_currency">
              {{ $t('INBOX_MGMT.FACEBOOK_DATASET.DEFAULT_CURRENCY') }}
            </label>
            <select
              id="default_currency"
              v-model="config.default_currency"
              class="form-select"
            >
              <option value="USD">USD</option>
              <option value="EUR">EUR</option>
              <option value="VND">VND</option>
              <option value="GBP">GBP</option>
              <option value="JPY">JPY</option>
            </select>
          </div>
        </div>

        <div class="settings-item">
          <label class="toggle-label">
            <input
              v-model="config.auto_send_conversions"
              type="checkbox"
              class="toggle-input"
            />
            <span class="toggle-slider"></span>
            {{ $t('INBOX_MGMT.FACEBOOK_DATASET.AUTO_SEND_CONVERSIONS') }}
          </label>
          <small class="form-help">
            {{ $t('INBOX_MGMT.FACEBOOK_DATASET.AUTO_SEND_CONVERSIONS_HELP') }}
          </small>
        </div>

        <!-- Action Buttons -->
        <div class="action-buttons">
          <button
            type="button"
            class="btn btn-secondary"
            :disabled="isTesting"
            @click="testConnection"
          >
            <spinner v-if="isTesting" size="small" />
            {{ $t('INBOX_MGMT.FACEBOOK_DATASET.TEST_CONNECTION') }}
          </button>

          <button
            type="button"
            class="btn btn-primary"
            :disabled="isSaving"
            @click="saveConfiguration"
          >
            <spinner v-if="isSaving" size="small" />
            {{ $t('INBOX_MGMT.FACEBOOK_DATASET.SAVE_CONFIGURATION') }}
          </button>
        </div>
      </div>

      <!-- Statistics -->
      <div v-if="config.enabled && stats" class="stats-section">
        <h4>{{ $t('INBOX_MGMT.FACEBOOK_DATASET.TRACKING_STATS') }}</h4>
        <div class="stats-grid">
          <div class="stat-item">
            <span class="stat-value">{{ stats.total_trackings }}</span>
            <span class="stat-label">{{ $t('INBOX_MGMT.FACEBOOK_DATASET.TOTAL_TRACKINGS') }}</span>
          </div>
          <div class="stat-item">
            <span class="stat-value">{{ stats.conversions_sent }}</span>
            <span class="stat-label">{{ $t('INBOX_MGMT.FACEBOOK_DATASET.CONVERSIONS_SENT') }}</span>
          </div>
          <div class="stat-item">
            <span class="stat-value">{{ stats.pending_conversions }}</span>
            <span class="stat-label">{{ $t('INBOX_MGMT.FACEBOOK_DATASET.PENDING_CONVERSIONS') }}</span>
          </div>
          <div class="stat-item">
            <span class="stat-value">{{ stats.unique_ads }}</span>
            <span class="stat-label">{{ $t('INBOX_MGMT.FACEBOOK_DATASET.UNIQUE_ADS') }}</span>
          </div>
        </div>
      </div>

      <!-- Recent Tracking Data -->
      <div v-if="config.enabled" class="tracking-data-section">
        <div class="section-header">
          <h4>{{ $t('INBOX_MGMT.FACEBOOK_DATASET.RECENT_TRACKING_DATA') }}</h4>
          <button
            type="button"
            class="btn btn-link"
            @click="loadTrackingData"
          >
            {{ $t('INBOX_MGMT.FACEBOOK_DATASET.REFRESH') }}
          </button>
        </div>

        <div v-if="trackingData.length > 0" class="tracking-table">
          <table class="table">
            <thead>
              <tr>
                <th>{{ $t('INBOX_MGMT.FACEBOOK_DATASET.DATE') }}</th>
                <th>{{ $t('INBOX_MGMT.FACEBOOK_DATASET.CONTACT') }}</th>
                <th>{{ $t('INBOX_MGMT.FACEBOOK_DATASET.AD_ID') }}</th>
                <th>{{ $t('INBOX_MGMT.FACEBOOK_DATASET.REF_PARAMETER') }}</th>
                <th>{{ $t('INBOX_MGMT.FACEBOOK_DATASET.EVENT_NAME') }}</th>
                <th>{{ $t('INBOX_MGMT.FACEBOOK_DATASET.CONVERSION_STATUS') }}</th>
                <th>{{ $t('INBOX_MGMT.FACEBOOK_DATASET.ACTIONS') }}</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="tracking in trackingData" :key="tracking.id">
                <td>{{ formatDate(tracking.created_at) }}</td>
                <td>{{ tracking.contact_name || tracking.contact_email }}</td>
                <td>{{ tracking.ad_id || '-' }}</td>
                <td>{{ tracking.ref_parameter }}</td>
                <td>{{ tracking.event_name || 'Lead' }}</td>
                <td>
                  <span
                    :class="[
                      'status-badge',
                      tracking.conversion_sent ? 'sent' : 'pending'
                    ]"
                  >
                    {{
                      tracking.conversion_sent
                        ? $t('INBOX_MGMT.FACEBOOK_DATASET.SENT')
                        : $t('INBOX_MGMT.FACEBOOK_DATASET.PENDING')
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
                    {{ $t('INBOX_MGMT.FACEBOOK_DATASET.RESEND') }}
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div v-else class="empty-state">
          <p>{{ $t('INBOX_MGMT.FACEBOOK_DATASET.NO_TRACKING_DATA') }}</p>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import Spinner from 'shared/components/Spinner.vue';
import FacebookDatasetAPI from '../../../../../api/inbox/facebookDataset';
import { useAlert } from 'dashboard/composables';

export default {
  name: 'FacebookDataset',
  components: {
    Spinner,
  },
  props: {
    inboxId: {
      type: [String, Number],
      required: true,
    },
  },
  data() {
    return {
      isLoading: true,
      isSaving: false,
      isTesting: false,
      isFetchingPixels: false,
      isGeneratingToken: false,
      pixelsLoaded: false,
      showManualInput: false,
      showTokenInput: false,
      selectedPixelId: '',
      availablePixels: [],
      config: {
        enabled: false,
        pixel_id: '',
        access_token: '',
        test_event_code: '',
        default_event_name: 'Lead',
        default_event_value: 0,
        default_currency: 'USD',
        auto_send_conversions: true,
      },
      stats: null,
      trackingData: [],
    };
  },
  computed: {
    ...mapGetters({
      currentAccount: 'accounts/getAccount',
    }),
    maskedToken() {
      if (!this.config.access_token) return '';
      const token = this.config.access_token;
      if (token.length <= 8) return token;
      return `${token.substring(0, 4)}${'*'.repeat(token.length - 8)}${token.substring(token.length - 4)}`;
    },
  },
  mounted() {
    this.loadConfiguration();
  },
  methods: {
    async loadConfiguration() {
      try {
        this.isLoading = true;
        const response = await FacebookDatasetAPI.getConfiguration(this.inboxId);
        this.config = { ...this.config, ...response.data.config };
        this.config.enabled = response.data.enabled;
        this.stats = response.data.tracking_stats;

        // Set selected pixel if already configured
        if (this.config.pixel_id) {
          this.selectedPixelId = this.config.pixel_id;
        }

        if (this.config.enabled) {
          await this.loadTrackingData();
        }
      } catch (error) {
        useAlert(this.$t('INBOX_MGMT.FACEBOOK_DATASET.LOAD_ERROR'));
      } finally {
        this.isLoading = false;
      }
    },

    async fetchFacebookPixels() {
      try {
        this.isFetchingPixels = true;
        const response = await FacebookDatasetAPI.getFacebookPixels(this.inboxId);

        if (response.data.success) {
          this.availablePixels = response.data.pixels || [];
          this.pixelsLoaded = true;

          // Auto-select if only one pixel available
          if (this.availablePixels.length === 1) {
            this.selectedPixelId = this.availablePixels[0].id;
            this.onPixelSelect();
          }

          useAlert(this.$t('INBOX_MGMT.FACEBOOK_DATASET.PIXELS_LOADED', { count: this.availablePixels.length }));
        } else {
          throw new Error(response.data.error || 'Failed to fetch pixels');
        }
      } catch (error) {
        console.error('Error fetching Facebook pixels:', error);
        useAlert(this.$t('INBOX_MGMT.FACEBOOK_DATASET.PIXELS_FETCH_ERROR'));

        // Show manual input as fallback
        this.showManualInput = true;
        this.pixelsLoaded = true;
      } finally {
        this.isFetchingPixels = false;
      }
    },

    async generateAccessToken() {
      if (!this.selectedPixelId) {
        useAlert(this.$t('INBOX_MGMT.FACEBOOK_DATASET.SELECT_PIXEL_FIRST'));
        return;
      }

      try {
        this.isGeneratingToken = true;
        const response = await FacebookDatasetAPI.generateAccessToken(this.inboxId, {
          pixel_id: this.selectedPixelId
        });

        if (response.data.success) {
          this.config.access_token = response.data.access_token;
          this.showTokenInput = false;
          useAlert(this.$t('INBOX_MGMT.FACEBOOK_DATASET.TOKEN_GENERATED'));
        } else {
          throw new Error(response.data.error || 'Failed to generate token');
        }
      } catch (error) {
        console.error('Error generating access token:', error);
        useAlert(this.$t('INBOX_MGMT.FACEBOOK_DATASET.TOKEN_GENERATION_ERROR'));
      } finally {
        this.isGeneratingToken = false;
      }
    },

    onPixelSelect() {
      const selectedPixel = this.availablePixels.find(p => p.id === this.selectedPixelId);
      if (selectedPixel) {
        this.config.pixel_id = selectedPixel.id;

        // Clear access token when pixel changes
        if (this.config.access_token) {
          this.config.access_token = '';
          this.showTokenInput = true;
        }
      }
    },

    toggleManualInput() {
      this.showManualInput = !this.showManualInput;
      if (this.showManualInput) {
        this.selectedPixelId = '';
      } else if (this.config.pixel_id) {
        this.selectedPixelId = this.config.pixel_id;
      }
    },

    async saveConfiguration() {
      try {
        this.isSaving = true;
        await FacebookDatasetAPI.updateConfiguration(this.inboxId, {
          facebook_dataset: this.config,
        });
        useAlert(this.$t('INBOX_MGMT.FACEBOOK_DATASET.SAVE_SUCCESS'));
        await this.loadConfiguration();
      } catch (error) {
        useAlert(this.$t('INBOX_MGMT.FACEBOOK_DATASET.SAVE_ERROR'));
      } finally {
        this.isSaving = false;
      }
    },

    async testConnection() {
      try {
        this.isTesting = true;
        const response = await FacebookDatasetAPI.testConnection(this.inboxId);
        if (response.data.success) {
          useAlert(this.$t('INBOX_MGMT.FACEBOOK_DATASET.TEST_SUCCESS'));
        } else {
          useAlert(response.data.error || this.$t('INBOX_MGMT.FACEBOOK_DATASET.TEST_ERROR'));
        }
      } catch (error) {
        useAlert(this.$t('INBOX_MGMT.FACEBOOK_DATASET.TEST_ERROR'));
      } finally {
        this.isTesting = false;
      }
    },

    async loadTrackingData() {
      try {
        const response = await FacebookDatasetAPI.getTrackingData(this.inboxId);
        this.trackingData = response.data.data;
      } catch (error) {
        console.error('Error loading tracking data:', error);
      }
    },

    async resendConversion(trackingId) {
      try {
        await FacebookDatasetAPI.resendConversion(this.inboxId, trackingId);
        useAlert(this.$t('INBOX_MGMT.FACEBOOK_DATASET.RESEND_SUCCESS'));
        await this.loadTrackingData();
      } catch (error) {
        useAlert(this.$t('INBOX_MGMT.FACEBOOK_DATASET.RESEND_ERROR'));
      }
    },

    onToggleChange() {
      if (!this.config.enabled) {
        // Reset form when disabling
        this.config = {
          ...this.config,
          pixel_id: '',
          access_token: '',
          test_event_code: '',
        };
      }
    },

    formatDate(dateString) {
      return new Date(dateString).toLocaleString();
    },
  },
};
</script>

<style scoped lang="scss">
.facebook-dataset-settings {
  .settings-header {
    margin-bottom: 2rem;

    .block-title {
      font-size: 1.25rem;
      font-weight: 600;
      margin-bottom: 0.5rem;
      color: var(--color-heading);
    }

    .block-description {
      color: var(--color-body);
      line-height: 1.5;
    }
  }

  .spinner-container {
    display: flex;
    justify-content: center;
    padding: 2rem;
  }

  .settings-item {
    margin-bottom: 1.5rem;

    .toggle-label {
      display: flex;
      align-items: center;
      gap: 0.75rem;
      font-weight: 500;
      cursor: pointer;

      .toggle-input {
        margin: 0;
      }

      .toggle-slider {
        // Add toggle slider styles if needed
      }
    }
  }

  .config-form {
    background: var(--color-background-light);
    border: 1px solid var(--color-border);
    border-radius: 8px;
    padding: 1.5rem;
    margin-bottom: 2rem;

    .form-group {
      margin-bottom: 1rem;

      label {
        display: block;
        font-weight: 500;
        margin-bottom: 0.5rem;
        color: var(--color-heading);

        .required {
          color: var(--color-error);
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

      .form-help {
        font-size: 0.75rem;
        color: var(--color-body-light);
        margin-top: 0.25rem;
      }

      // Enhanced styles for new pixel selection components
      .pixel-selection-container {
        display: flex;
        flex-direction: column;
        gap: 0.75rem;
      }

      .btn-fetch-pixels {
        align-self: flex-start;
        min-width: 200px;
      }

      .pixel-dropdown-container {
        display: flex;
        gap: 0.5rem;
        align-items: center;
      }

      .pixel-select {
        flex: 1;
        min-width: 0;
        max-width: 400px;

        option {
          padding: 0.5rem;
          white-space: nowrap;
          overflow: hidden;
          text-overflow: ellipsis;
        }
      }

      .btn-refresh-pixels {
        flex-shrink: 0;
        width: 40px;
        height: 40px;
        display: flex;
        align-items: center;
        justify-content: center;
        padding: 0;
      }

      .manual-input-container {
        margin-top: 0.5rem;
      }

      .btn-toggle-manual {
        font-size: 0.75rem;
        padding: 0.25rem 0.5rem;
        align-self: flex-start;
      }

      // Access token container styles
      .access-token-container {
        display: flex;
        flex-direction: column;
        gap: 0.5rem;
      }

      .token-display {
        display: flex;
        align-items: center;
        gap: 0.75rem;
        padding: 0.75rem;
        background: var(--color-background-light);
        border: 1px solid var(--color-border);
        border-radius: 4px;
      }

      .token-masked {
        font-family: monospace;
        font-size: 0.8125rem;
        color: var(--color-body);
        flex: 1;
      }

      .btn-edit-token {
        font-size: 0.75rem;
        padding: 0.25rem 0.5rem;
      }

      .token-input-container {
        display: flex;
        gap: 0.5rem;
        align-items: flex-end;

        .form-input {
          flex: 1;
        }

        .btn-generate-token {
          flex-shrink: 0;
          white-space: nowrap;
        }
      }
    }

    .form-row {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 1rem;
    }
  }

  .action-buttons {
    display: flex;
    gap: 1rem;
    margin-top: 1.5rem;

    .btn {
      padding: 0.75rem 1.5rem;
      border-radius: 4px;
      font-weight: 500;
      cursor: pointer;
      border: none;
      display: flex;
      align-items: center;
      gap: 0.5rem;

      &:disabled {
        opacity: 0.6;
        cursor: not-allowed;
      }

      &.btn-primary {
        background: var(--color-primary);
        color: white;

        &:hover:not(:disabled) {
          background: var(--color-primary-dark);
        }
      }

      &.btn-secondary {
        background: var(--color-background);
        color: var(--color-body);
        border: 1px solid var(--color-border);

        &:hover:not(:disabled) {
          background: var(--color-background-light);
        }
      }
    }
  }

  .stats-section {
    background: var(--color-background-light);
    border: 1px solid var(--color-border);
    border-radius: 8px;
    padding: 1.5rem;
    margin-bottom: 2rem;

    h4 {
      margin-bottom: 1rem;
      color: var(--color-heading);
    }

    .stats-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
      gap: 1rem;

      .stat-item {
        text-align: center;

        .stat-value {
          display: block;
          font-size: 1.5rem;
          font-weight: 600;
          color: var(--color-primary);
        }

        .stat-label {
          font-size: 0.75rem;
          color: var(--color-body-light);
          margin-top: 0.25rem;
        }
      }
    }
  }

  .tracking-data-section {
    .section-header {
      display: flex;
      justify-content: between;
      align-items: center;
      margin-bottom: 1rem;

      h4 {
        margin: 0;
        color: var(--color-heading);
      }

      .btn-link {
        background: none;
        border: none;
        color: var(--color-primary);
        cursor: pointer;
        font-size: 0.875rem;

        &:hover {
          text-decoration: underline;
        }
      }
    }

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
          background: var(--color-background-light);
          font-weight: 600;
          color: var(--color-heading);
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
        }
      }
    }

    .empty-state {
      text-align: center;
      padding: 2rem;
      color: var(--color-body-light);
    }
  }

  // Responsive design
  @media (max-width: 768px) {
    padding: 1rem;

    .config-form {
      padding: 1rem;

      .form-group {
        .pixel-dropdown-container {
          flex-direction: column;
          align-items: stretch;
        }

        .btn-refresh-pixels {
          width: 100%;
          height: auto;
          padding: 0.75rem;
        }

        .token-input-container {
          flex-direction: column;

          .btn-generate-token {
            align-self: stretch;
          }
        }
      }
    }

    .action-buttons {
      flex-direction: column;
    }

    .stats-section {
      .stats-grid {
        grid-template-columns: 1fr;
      }
    }

    .tracking-data-section {
      .section-header {
        flex-direction: column;
        align-items: flex-start;
        gap: 0.5rem;
      }
    }
  }
}
</style>
