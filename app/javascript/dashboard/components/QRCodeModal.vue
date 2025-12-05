<script>
import { useAlert } from 'dashboard/composables';
import WhatsappWebGatewayApi from 'dashboard/api/whatsappWebGateway';

export default {
  name: 'QRCodeModal',
  props: {
    show: {
      type: Boolean,
      default: false,
    },
    gatewayConfig: {
      type: Object,
      required: true,
    },
    inboxId: {
      type: [String, Number],
      default: null,
    },
  },
  emits: ['close', 'connected'],
  data() {
    return {
      qrCodeUrl: null,
      qrCodeBlobUrl: null,
      isLoading: false,
      timeRemaining: 0,
      qrDuration: 60,
      timer: null,
      refreshTimer: null,
      connectionCheckTimer: null,
    };
  },
  watch: {
    show(newValue) {
      if (newValue) {
        this.fetchQRCode();
      } else {
        this.stopTimers();
      }
    },
  },
  beforeUnmount() {
    this.stopTimers();
  },
  methods: {
    async fetchQRCode() {
      this.isLoading = true;

      try {
        // Use the inbox ID if available, otherwise this is for testing/preview
        if (this.inboxId) {
          const response = await WhatsappWebGatewayApi.login(this.inboxId);
          if (response.data && response.data.data.results) {
            this.qrCodeUrl = response.data.data.results.qr_link;
            this.qrDuration = response.data.data.results.qr_duration || 60;

            // The QR code URL is now a base64 data URL, so we can use it directly
            this.qrCodeBlobUrl = this.qrCodeUrl;
          } else {
            throw new Error('Invalid response format from gateway');
          }
        } else {
          // For testing/preview mode, we'll create a test connection
          // This is used when the inbox isn't created yet
          const testResponse = await this.testGatewayConnection();
          this.qrCodeUrl = testResponse.qr_link;
          this.qrDuration = testResponse.qr_duration || 60;

          // For test mode, the QR URL might be a direct gateway URL
          // so we don't need authentication headers
          this.qrCodeBlobUrl = this.qrCodeUrl;
        }

        this.timeRemaining = this.qrDuration;
        this.startTimer();
        this.startConnectionCheck();
      } catch (error) {
        useAlert(
          error.message ||
            this.$t('INBOX_MGMT.ADD.WHATSAPP_WEB.QR_CODE.FETCH_ERROR')
        );
        this.qrCodeUrl = null;
        this.qrCodeBlobUrl = null;
      } finally {
        this.isLoading = false;
      }
    },

    async testGatewayConnection() {
      // Test connection to gateway via backend endpoint
      const response = await WhatsappWebGatewayApi.testConnection(
        this.gatewayConfig
      );
      return response.data.data;
    },

    refreshQRCode() {
      this.stopTimers();
      this.fetchQRCode();
    },

    startTimer() {
      this.timer = setInterval(() => {
        this.timeRemaining -= 1;

        if (this.timeRemaining <= 0) {
          this.stopTimers();
          setTimeout(() => {
            if (this.show) {
              this.refreshQRCode();
            }
          }, 1000);
        }
      }, 1000);
    },

    async startConnectionCheck() {
      this.connectionCheckTimer = setInterval(async () => {
        try {
          if (this.inboxId) {
            // Check connection status via status endpoint
            const response = await WhatsappWebGatewayApi.getStatus(
              this.inboxId
            );
            if (
              response.data &&
              response.data.data &&
              response.data.data.results &&
              response.data.data.results.is_logged_in
            ) {
              this.handleConnectionSuccess();
            }
          } else {
            // For test mode, check via test devices endpoint
            const devices = await this.checkGatewayDevices();
            if (devices && devices.length > 0) {
              this.handleConnectionSuccess();
            }
          }
        } catch (error) {
          // Connection not established yet, continue checking
          // Debug log removed for production
        }
      }, 3000);
    },

    async checkGatewayDevices() {
      // Check devices via backend endpoint for test mode
      const response = await WhatsappWebGatewayApi.testDevices(
        this.gatewayConfig
      );
      return response.data.data.devices || [];
    },

    handleConnectionSuccess() {
      this.stopTimers();
      this.$emit('connected');
      useAlert(
        this.$t('INBOX_MGMT.ADD.WHATSAPP_WEB.QR_CODE.CONNECTION_SUCCESS')
      );
      this.handleCloseModal();
    },

    stopTimers() {
      if (this.timer) {
        clearInterval(this.timer);
        this.timer = null;
      }
      if (this.refreshTimer) {
        clearInterval(this.refreshTimer);
        this.refreshTimer = null;
      }
      if (this.connectionCheckTimer) {
        clearInterval(this.connectionCheckTimer);
        this.connectionCheckTimer = null;
      }
    },

    handleCloseModal() {
      this.stopTimers();
      this.$emit('close');
    },
  },
};
</script>

<template>
  <transition name="modal-animation">
    <div
      v-if="show"
      class="fixed inset-0 z-50 flex items-center justify-center overflow-x-hidden overflow-y-auto outline-none focus:outline-none"
      @click.self="handleCloseModal"
    >
      <div class="fixed inset-0 bg-black bg-opacity-50" />
      <div
        class="relative w-full max-w-md mx-auto my-6 bg-white rounded-lg shadow-lg"
      >
        <div
          class="flex items-center justify-between p-5 border-b border-solid border-n-alpha-20 rounded-t"
        >
          <h3 class="text-xl font-semibold">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.QR_CODE.TITLE') }}
          </h3>
          <button
            type="button"
            class="p-1 ml-auto bg-transparent border-0 text-n-slate-11 float-right text-3xl leading-none font-semibold outline-none focus:outline-none"
            @click="handleCloseModal"
          >
            <span class="sr-only">
              {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.QR_CODE.CLOSE') }}
            </span>
            <i class="ri-close-line" />
          </button>
        </div>

        <div class="relative p-6 flex-auto">
          <div class="text-center">
            <p class="mb-4 text-n-slate-9">
              {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.QR_CODE.DESC') }}
            </p>

            <div class="flex justify-center mb-4">
              <div
                v-if="isLoading"
                class="flex items-center justify-center w-64 h-64 border border-n-alpha-20 rounded-lg"
              >
                <div
                  class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"
                />
              </div>
              <div
                v-else-if="qrCodeBlobUrl"
                class="border border-n-alpha-20 rounded-lg p-4"
              >
                <img
                  :src="qrCodeBlobUrl"
                  alt="QR Code"
                  class="w-64 h-64 object-contain"
                />
              </div>
              <div
                v-else
                class="flex items-center justify-center w-64 h-64 border border-n-alpha-20 rounded-lg bg-n-alpha-2"
              >
                <p class="text-n-slate-9">
                  {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.QR_CODE.ERROR') }}
                </p>
              </div>
            </div>

            <div class="mb-4">
              <p v-if="timeRemaining > 0" class="text-sm text-n-slate-9">
                {{
                  $t('INBOX_MGMT.ADD.WHATSAPP_WEB.QR_CODE.EXPIRES_IN', {
                    seconds: timeRemaining,
                  })
                }}
              </p>
              <p v-else class="text-sm text-orange-600">
                {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.QR_CODE.EXPIRED') }}
              </p>
            </div>

            <div class="mb-4 p-4 bg-blue-50 rounded-lg">
              <h4 class="font-medium mb-2">
                {{
                  $t('INBOX_MGMT.ADD.WHATSAPP_WEB.QR_CODE.INSTRUCTIONS.TITLE')
                }}
              </h4>
              <ol class="text-sm text-left text-n-slate-9 space-y-1">
                <li>
                  {{
                    $t('INBOX_MGMT.ADD.WHATSAPP_WEB.QR_CODE.INSTRUCTIONS.STEP1')
                  }}
                </li>
                <li>
                  {{
                    $t('INBOX_MGMT.ADD.WHATSAPP_WEB.QR_CODE.INSTRUCTIONS.STEP2')
                  }}
                </li>
                <li>
                  {{
                    $t('INBOX_MGMT.ADD.WHATSAPP_WEB.QR_CODE.INSTRUCTIONS.STEP3')
                  }}
                </li>
              </ol>
            </div>
          </div>
        </div>

        <div
          class="flex items-center justify-end p-6 border-t border-solid border-n-alpha-20 rounded-b"
        >
          <button
            type="button"
            class="px-6 py-2 mr-2 text-sm font-medium text-n-slate-9 bg-transparent border border-n-alpha-20 rounded-md hover:bg-n-alpha-2 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
            @click="handleCloseModal"
          >
            {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.QR_CODE.CLOSE') }}
          </button>
          <button
            type="button"
            class="px-6 py-2 text-sm font-medium text-white bg-blue-600 border border-transparent rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
            :disabled="isLoading"
            @click="refreshQRCode"
          >
            <div v-if="isLoading" class="flex items-center">
              <div
                class="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"
              />
              {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.QR_CODE.REFRESHING') }}
            </div>
            <span v-else>
              {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.QR_CODE.REFRESH') }}
            </span>
          </button>
        </div>
      </div>
    </div>
  </transition>
</template>

<style scoped>
.modal-animation-enter-active,
.modal-animation-leave-active {
  transition: opacity 0.3s ease;
}

.modal-animation-enter-from,
.modal-animation-leave-to {
  opacity: 0;
}
</style>
