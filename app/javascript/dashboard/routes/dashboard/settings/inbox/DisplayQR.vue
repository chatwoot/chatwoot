<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import router from '../../../index';
import PageHeader from '../SettingsSubPageHeader.vue';
import WhatsAppUnofficialChannels from 'dashboard/api/WhatsAppUnofficialChannels';
import { createConsumer } from '@rails/actioncable';

export default {
  components: {
    PageHeader,
  },
  data() {
    return {
      qrCodeData: null,
      connectionStatus: 'waiting', // waiting, connected, expired, mismatch
      countdown: 60,
      countdownInterval: null,
      statusInterval: null,
      isLoading: true,
      isConnecting: false,
      mismatchInfo: null,
      expectedPhoneNumber: null,
      subscription: null, // ActionCable subscription
      channelId: null, // Channel ID for WhatsApp
    };
  },
  computed: {
    ...mapGetters({
      globalConfig: 'globalConfig/get',
    }),
    statusMessage() {
      switch (this.connectionStatus) {
        case 'waiting':
          return 'Menunggu dipindai...';
        case 'connected':
          return 'Berhasil terhubung!';
        case 'expired':
          return 'Menghasilkan kode QR baru...';
        case 'mismatch':
          return 'Nomor WhatsApp tidak sesuai!';
        default:
          return 'Memuat...';
      }
    },
    countdownMessage() {
      return `Kode QR akan kedaluwarsa dalam ${this.countdown} detik`;
    },
    instructionMessage() {
      if (this.expectedPhoneNumber) {
        return `Pastikan Anda menggunakan WhatsApp dengan nomor ${this.expectedPhoneNumber}`;
      }
      return 'Silakan pindai kode ini menggunakan aplikasi WhatsApp Anda';
    }
  },
  async mounted() {
    await this.fetchInboxInfo();
    await this.setupWebSocketSubscription();
    await this.generateQRCode();
    this.startCountdown();
    this.checkConnectionStatus();
  },
  beforeUnmount() {
    this.clearIntervals();
    this.disconnectWebSocket();
  },
  methods: {
    async fetchInboxInfo() {
      try {
        const inboxId = this.$route.params.inbox_id;
        const response = await this.$http.get(`inboxes/${inboxId}`);
        
        if (response.data && response.data.channel && response.data.channel.phone_number) {
          this.expectedPhoneNumber = response.data.channel.phone_number;
          // Store channel ID for WebSocket subscription
          this.channelId = response.data.channel.id;
        }
      } catch (error) {
        console.error('Failed to fetch inbox info:', error);
      }
    },

    async setupWebSocketSubscription() {
      
      try {
        // Use Chatwoot's existing WebSocket approach
        // Subscribe to room channel with pubsub token for real-time updates
        const accountId = this.$route.params.accountId;
        const pubsub_token = `${accountId}_inbox_${this.$route.params.inbox_id}`;
        
        // Create ActionCable consumer using Chatwoot's approach
        const cable = createConsumer();
        
        // Subscribe to RoomChannel for inbox-specific updates
        this.subscription = cable.subscriptions.create(
          { 
            channel: 'RoomChannel',
            pubsub_token: pubsub_token
          },
          {
            received: (data) => {
              console.log('📡 WebSocket received:', data);
              this.handleWebSocketMessage(data);
            },
            connected: () => {
              console.log('📡 WebSocket connected for inbox:', this.$route.params.inbox_id);
            },
            disconnected: () => {
              console.log('📡 WebSocket disconnected for inbox:', this.$route.params.inbox_id);
            }
          }
        );

        console.log('✅ WebSocket subscription setup complete');
      } catch (error) {
        console.error('Failed to setup WebSocket:', error);
      }
    },

    handleWebSocketMessage(data) {
      console.log('🔄 Processing WebSocket message:', data);

      if (data.event === 'whatsapp_status_changed') {
        this.handleStatusUpdate(data);
      } else {
        console.log('📡 Unhandled WebSocket message event:', data.event);
      }
    },

    handleStatusUpdate(data) {
      console.log('📊 Status update received:', data);

      if (data.type === 'session_ready' || data.type === 'phone_validation_success') {
        console.log('🎉 WhatsApp connected successfully!');
        this.connectionStatus = 'connected';
        this.clearIntervals();
        
        setTimeout(() => {
          this.redirectToInboxSettings();
        }, 2000);

      } else if (data.type === 'session_mismatch') {
        console.error('📱 Phone number mismatch detected!', data);
        this.handlePhoneMismatch(data.expected_phone, data.connected_phone);
      
      } else if (data.status === 'disconnected') {
        console.log('❌ WhatsApp disconnected');
        if (this.connectionStatus !== 'mismatch' && this.connectionStatus !== 'connected') {
          this.connectionStatus = 'waiting';
        }
      }
    },

    disconnectWebSocket() {
      if (this.subscription) {
        this.subscription.unsubscribe();
        this.subscription = null;
        console.log('📡 WebSocket subscription disconnected');
      }
    },

    async generateQRCode() {
      try {
        this.isLoading = true;
        const inboxId = this.$route.params.inbox_id;
        const accountId = this.$route.params.accountId;
        
        const response = await WhatsAppUnofficialChannels.generateQR(inboxId);
        
        if (response.data.success && response.data.qr_code) {
          // Convert base64 to data URL for image display
          this.qrCodeData = `data:image/png;base64,${response.data.qr_code}`;
        } else {
          throw new Error(response.data.message || 'Failed to generate QR code');
        }
      } catch (error) {
        useAlert('Gagal menghasilkan kode QR. Silakan coba lagi.');
        console.error('QR Generation Error:', error);
      } finally {
        this.isLoading = false;
      }
    },

    startCountdown() {
      this.countdownInterval = setInterval(() => {
        this.countdown--;
        if (this.countdown <= 0) {
          this.handleQRExpired();
        }
      }, 1000);
    },

    async handleQRExpired() {
      this.connectionStatus = 'expired';
      this.clearIntervals();
      
      // Auto refresh QR code setelah 1 detik
      setTimeout(async () => {
        await this.refreshQRCode();
      }, 1000);
    },

    async refreshQRCode() {
      this.countdown = 60;
      this.connectionStatus = 'waiting';
      await this.generateQRCode();
      this.startCountdown();
      this.checkConnectionStatus();
    },

    async checkConnectionStatus() {
      this.statusInterval = setInterval(async () => {

        const inboxId = this.$route.params.inbox_id;

        if (!inboxId || ['connected', 'expired'].includes(this.connectionStatus)) {
          this.clearIntervals();
          return;
        }

        try {
          await WhatsAppUnofficialChannels.getConnectionStatus(inboxId);
        } catch (error) {
          if (error.response && error.response.status === 404) {
            this.clearIntervals();
          } else {
            console.error('Status check error:', error);
          }
        }
      }, 5000);
    },

    redirectToInboxSettings() {
      console.log('🚀 Redirecting to inbox settings...');
      this.proceedToNextStep();
    },

    clearIntervals() {
      if (this.countdownInterval) {
        clearInterval(this.countdownInterval);
        this.countdownInterval = null;
        console.log('Countdown interval cleared.');
      }
      if (this.statusInterval) {
        clearInterval(this.statusInterval);
        this.statusInterval = null;
        console.log('Status interval cleared.');
      }
    },

    async proceedToNextStep() {
      this.isConnecting = true;
      const inboxId = this.$route.params.inbox_id;
      const webhookUrl = this.$route.query.webhook_url;

      try {
        const routeParams = {
          name: 'settings_inboxes_add_agents',
          params: {
            inbox_id: inboxId,
          },
        };

        if (webhookUrl) {
          routeParams.query = { webhook_url: webhookUrl };
        }

        router.replace(routeParams);
      } catch (error) {
        useAlert('Terjadi kesalahan saat melanjutkan. Silakan coba lagi.');
        this.isConnecting = false;
      }
    },

    handlePhoneMismatch(expectedPhone, connectedPhone) {
      this.connectionStatus = 'mismatch';
      this.mismatchInfo = {
        expected: expectedPhone,
        connected: connectedPhone
      };
      this.clearIntervals();
      
      useAlert(`Nomor WhatsApp tidak sesuai! Diharapkan: ${expectedPhone}, Terhubung: ${connectedPhone}. Silakan scan dengan nomor yang benar.`);
      
      // Auto refresh QR code setelah 5 detik
      setTimeout(async () => {
        await this.refreshQRCode();
      }, 5000);
    }
  },
};
</script>
<template>
  <div
    class="border border-slate-25 dark:border-slate-800/60 bg-white dark:bg-slate-900 h-full p-6 w-full max-w-full md:w-3/4 md:max-w-[75%] flex-shrink-0 flex-grow-0"
  >
    <div class="flex flex-wrap mx-0">
      <div class="w-full">
        <PageHeader
          :header-title="$t('INBOX_MGMT.ADD.QRCODE.TITLE')"
          :header-content="$t('INBOX_MGMT.ADD.QRCODE.DESC')"
        />
      </div>

      <div class="w-full max-w-4xl mx-auto">
        <!-- QR Code and Instructions Side by Side -->
        <div class="flex flex-col md:flex-row gap-8 items-start justify-center mt-8">
          <!-- QR Code + Status Card -->
          <div class="flex-shrink-0 w-full md:w-auto">
            <div class="bg-slate-100 dark:bg-slate-900 p-6 rounded-xl shadow-lg w-80 mx-auto">
              <!-- QR Code Image Area -->
              <div class="w-full h-64 flex items-center justify-center bg-white rounded-md mb-4">
                <div v-if="isLoading" class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
                <img 
                  v-else-if="qrCodeData" 
                  :src="qrCodeData" 
                  alt="WhatsApp QR Code" 
                  class="w-full h-full object-contain p-4"
                />
                <div v-else class="text-slate-500 text-center">
                  Gagal memuat QR Code
                </div>
              </div>

              <!-- Description Text -->
              <p class="text-sm font-semibold text-slate-600 dark:text-slate-400 text-center mb-4">
                {{ instructionMessage }}
              </p>

              <!-- Status Display -->
              <div class="text-center">
                <div class="flex items-center justify-center space-x-3 mb-3">
                  <div 
                    class="w-3 h-3 rounded-full"
                    :class="{
                      'bg-green-500 animate-pulse': connectionStatus === 'waiting',
                      'bg-green-500': connectionStatus === 'connected',
                      'bg-orange-500 animate-pulse': connectionStatus === 'expired',
                      'bg-red-500 animate-pulse': connectionStatus === 'mismatch'
                    }"
                  ></div>
                  <span 
                    class="text-sm font-medium"
                    :class="{
                      'text-green-600 dark:text-yellow-400': connectionStatus === 'waiting',
                      'text-green-600 dark:text-green-400': connectionStatus === 'connected',
                      'text-orange-600 dark:text-orange-400': connectionStatus === 'expired',
                      'text-red-600 dark:text-red-400': connectionStatus === 'mismatch'
                    }"
                  >
                    {{ statusMessage }}
                  </span>
                </div>

                <div v-if="connectionStatus === 'waiting'" class="text-slate-600 dark:text-slate-400 text-xs">
                  {{ countdownMessage }}
                </div>

                <div v-if="connectionStatus === 'connected'" class="text-green-600 dark:text-green-400 text-xs">
                  Mengarahkan ke langkah berikutnya...
                </div>

                <div v-if="connectionStatus === 'expired'" class="text-orange-600 dark:text-orange-400 text-xs">
                  Kode QR akan diperbarui otomatis...
                </div>

                <div v-if="connectionStatus === 'mismatch'" class="text-red-600 dark:text-red-400 text-xs text-center">
                  <div v-if="mismatchInfo">
                    Diharapkan: {{ mismatchInfo.expected }} <br />
                    Terhubung: {{ mismatchInfo.connected }}
                  </div>
                  <div class="mt-1">QR akan diperbarui dalam 5 detik...</div>
                </div>
              </div>
            </div>
          </div>

          <!-- Instructions Section -->
          <div class="flex-1 max-w-md">
            <div class="p-6 pt-0 rounded-lg">
              <h4 class="font-semibold text-slate-800 dark:text-slate-200 mb-4">
                Cara Menghubungkan:
              </h4>
              <ol class="list-decimal list-inside space-y-3 text-slate-600 dark:text-slate-400">
                <li>Buka aplikasi WhatsApp di HP Anda.</li>
                <li>Masuk ke menu Setelan > Perangkat Tertaut.</li>
                <li>Tekan Tautkan Perangkat, lalu arahkan kamera HP Anda ke kode QR ini.</li>
              </ol>
            </div>
          </div>
        </div>

        <!-- Action Buttons - Only show when connected -->
        <div class="text-center">
          <button
            v-if="connectionStatus === 'connected'"
            @click="proceedToNextStep"
            :disabled="isConnecting"
            class="bg-green-600 hover:bg-green-700 disabled:bg-green-400 disabled:cursor-not-allowed text-white font-medium py-3 px-8 rounded-lg transition-all duration-200 transform hover:scale-105 focus:outline-none focus:ring-2 focus:ring-green-500 focus:ring-offset-2 focus:ring-offset-slate-900"
          >
            <span v-if="isConnecting" class="flex items-center">
              <div class="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
              Melanjutkan...
            </span>
            <span v-else>Lanjutkan</span>
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.animate-pulse {
  animation: pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}

@keyframes pulse {
  0%, 100% {
    opacity: 1;
  }
  50% {
    opacity: .5;
  }
}
</style>