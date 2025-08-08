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
      connectionStatus: 'waiting',
      countdown: 60,
      countdownInterval: null,
      statusInterval: null,
      isLoading: true,
      isConnecting: false,
      mismatchInfo: null,
      expectedPhoneNumber: null,
      subscription: null,
      channelId: null, 
      lastMismatchTime: 0, 
      mismatchAttempts: 0,
      maxMismatchAttempts: 3,
      lastSuccessAlertTime: 0, // Add debouncing for success alerts
    };
  },
  computed: {
    ...mapGetters({
      globalConfig: 'globalConfig/get',
    }),
    isRescanContext() {
      // Detect if this is a rescan by checking if we came from the inbox settings page
      // or if there's a 'rescan' query parameter
      return this.$route.query.rescan === 'true' || this.$route.query.context === 'rescan';
    },
    statusMessage() {
      switch (this.connectionStatus) {
        case 'waiting':
          return this.isRescanContext ? 'Menunggu re-scan...' : 'Menunggu dipindai...';
        case 'connected':
          return this.isRescanContext ? 'Berhasil terkoneksi kembali!' : 'Berhasil terhubung!';
        case 'expired':
          return 'Menghasilkan kode QR baru...';
        case 'mismatch':
          const remainingAttempts = this.maxMismatchAttempts - this.mismatchAttempts;
          const rescanContext = this.mismatchInfo?.rescanContext;
          const prefix = rescanContext ? 'Re-scan' : 'Nomor WhatsApp';
          return `${prefix} tidak sesuai! Sisa ${remainingAttempts} kesempatan`;
        case 'failed':
          return 'Gagal menghubungkan ke WhatsApp';
        default:
          return 'Memuat...';
      }
    },
    countdownMessage() {
      return `Kode QR akan kedaluwarsa dalam ${this.countdown} detik`;
    },
    instructionMessage() {
      if (this.connectionStatus === 'failed') {
        return 'Silakan tutup jendela ini dan coba lagi dari halaman "Platform Terhubung"';
      }
      if (this.expectedPhoneNumber) {
        const context = this.isRescanContext ? 're-scan QR code' : 'scan QR code';
        return `Pastikan Anda ${context} menggunakan WhatsApp dengan nomor ${this.expectedPhoneNumber}`;
      }
      const action = this.isRescanContext ? 're-scan kode ini' : 'pindai kode ini';
      return `Silakan ${action} menggunakan aplikasi WhatsApp Anda`;
    },
    failedMessage() {
      return 'Gagal menghubungkan ke WhatsApp.';
    },
    pageTitle() {
      return this.isRescanContext ? 'Re-scan QR Code WhatsApp' : this.$t('INBOX_MGMT.ADD.QRCODE.TITLE');
    },
    pageDescription() {
      return this.isRescanContext ? 'Scan ulang QR code untuk menghubungkan kembali WhatsApp Anda' : this.$t('INBOX_MGMT.ADD.QRCODE.DESC');
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
              // console.log('📡 WebSocket received:', data);
              this.handleWebSocketMessage(data);
            },
            connected: () => {
              // console.log('📡 WebSocket connected for inbox:', this.$route.params.inbox_id);
            },
            disconnected: () => {
              // console.log('📡 WebSocket disconnected for inbox:', this.$route.params.inbox_id);
            }
          }
        );

        // console.log('✅ WebSocket subscription setup complete');
      } catch (error) {
        console.error('Failed to setup WebSocket:', error);
      }
    },

    handleWebSocketMessage(data) {
      // console.log('🔄 Processing WebSocket message:', data);

      if (data.event === 'whatsapp_status_changed') {
        this.handleStatusUpdate(data);
      } else {
        // console.log('📡 Unhandled WebSocket message event:', data.event);
      }
    },

    handleStatusUpdate(data) {
      // console.log('📊 Status update received:', data);

      if (data.type === 'session_ready' || data.type === 'phone_validation_success') {
        // console.log('🎉 WhatsApp connected successfully!');
        
        // Prevent duplicate status handling
        if (this.connectionStatus === 'connected') {
          return; // Already handled
        }
        
        this.connectionStatus = 'connected';
        this.clearIntervals();
        
        // Show different success message based on context (only once)
        if (this.isRescanContext) {
          // Debounce success alerts - only show if more than 3 seconds since last alert
          const now = Date.now();
          if (now - this.lastSuccessAlertTime > 3000) {
            useAlert('WhatsApp berhasil terkoneksi kembali!');
            this.lastSuccessAlertTime = now;
          }
        }
        
        setTimeout(() => {
          this.redirectToInboxSettings();
        }, 2000);

      } else if (data.type === 'session_mismatch') {
        console.error('📱 Phone number mismatch detected!', data);
        console.log('📊 Rescan context:', {
          rescan_context: data.rescan_context,
          rescan_attempts: data.rescan_attempts,
          current_attempts: data.current_attempts,
          remaining_attempts: data.remaining_attempts
        });
        this.handlePhoneMismatch(data.expected_phone, data.connected_phone, data.current_attempts, data.remaining_attempts, data.rescan_context);

      } else if (data.type === 'session_failed') {
        console.error('📱 WhatsApp connection failed after maximum attempts!', data);
        this.handleConnectionFailed(data.expected_phone, data.connected_phone, data.failed_attempts, data);
      
      } else if (data.status === 'disconnected') {
        // console.log('❌ WhatsApp disconnected');
        if (this.connectionStatus !== 'mismatch' && this.connectionStatus !== 'connected' && this.connectionStatus !== 'failed') {
          this.connectionStatus = 'waiting';
        }
      }
    },

    disconnectWebSocket() {
      if (this.subscription) {
        this.subscription.unsubscribe();
        this.subscription = null;
        // console.log('📡 WebSocket subscription disconnected');
      }
    },

    async generateQRCode() {
      try {
        // Don't generate QR if connection already failed
        if (this.connectionStatus === 'failed') {
          // console.log('🚫 Cannot generate QR code - connection failed');
          return;
        }
        
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
      
      // Auto refresh QR code setelah 2 detik (lebih lama untuk stabilitas)
      setTimeout(async () => {
        if (this.connectionStatus === 'expired') {
          await this.refreshQRCode();
        }
      }, 2000);
    },

    async refreshQRCode() {
      // Jangan refresh QR code jika sudah failed
      if (this.connectionStatus === 'failed') {
        return;
      }
      
      this.countdown = 60;
      this.connectionStatus = 'waiting';
      await this.generateQRCode();
      this.startCountdown();
      this.checkConnectionStatus();
    },

    async checkConnectionStatus() {
      this.statusInterval = setInterval(async () => {

        const inboxId = this.$route.params.inbox_id;

        if (!inboxId || ['connected', 'expired', 'mismatch', 'failed'].includes(this.connectionStatus)) {
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
      // console.log('🚀 Redirecting based on context...');
      if (this.isRescanContext) {
        // For rescan, redirect back to inbox settings/status page
        this.redirectToInboxStatusPage();
      } else {
        // For initial scan, proceed to add agents page
        this.proceedToNextStep();
      }
    },

    redirectToInboxStatusPage() {
      // console.log('🚀 Redirecting to inbox status page (rescan context)...');
      const accountId = this.$route.params.accountId;
      const inboxId = this.$route.params.inbox_id;
      
      // Redirect to inbox detail/status page
      router.replace({
        name: 'settings_inbox_show',
        params: {
          accountId: accountId,
          inboxId: inboxId
        }
      });
    },

    clearIntervals() {
      if (this.countdownInterval) {
        clearInterval(this.countdownInterval);
        this.countdownInterval = null;
        // console.log('Countdown interval cleared.');
      }
      if (this.statusInterval) {
        clearInterval(this.statusInterval);
        this.statusInterval = null;
        // console.log('Status interval cleared.');
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

    handlePhoneMismatch(expectedPhone, connectedPhone, currentAttempts = null, remainingAttempts = null, rescanContext = false) {
      // Debounce mismatch events - ignore if less than 10 seconds since last mismatch
      const now = Date.now();
      if (now - this.lastMismatchTime < 10000) {
        // console.log('📱 Mismatch event ignored - too frequent');
        return;
      }
      this.lastMismatchTime = now;
      
      // Prevent duplicate mismatch handling
      if (this.connectionStatus === 'mismatch' || this.connectionStatus === 'failed') {
        // console.log('📱 Mismatch already handled, ignoring duplicate');
        return;
      }
      
      // Update attempts from server data
      if (currentAttempts !== null) {
        this.mismatchAttempts = currentAttempts;
      } else {
        // Fallback to local tracking
        this.mismatchAttempts++;
      }
      
      // console.log(`📱 Mismatch attempt ${this.mismatchAttempts}/${this.maxMismatchAttempts}`);
      
      this.connectionStatus = 'mismatch';
      this.mismatchInfo = {
        expected: expectedPhone,
        connected: connectedPhone,
        rescanContext: rescanContext
      };
      this.clearIntervals();
      
      const remaining = remainingAttempts !== null ? remainingAttempts : (this.maxMismatchAttempts - this.mismatchAttempts);
      const message = rescanContext 
        ? `Nomor WhatsApp tidak sesuai saat re-scan! Sisa ${remaining} kesempatan lagi.`
        : `Nomor WhatsApp tidak sesuai! Sisa ${remaining} kesempatan lagi.`;
      
      useAlert(message);
      
      setTimeout(async () => {
        if (this.connectionStatus === 'mismatch') {
          await this.refreshQRCode();
        }
      }, 10000);
    },

    handleConnectionFailed(expectedPhone, connectedPhone, failedAttempts, data = {}) {
      // console.log(`📱 Connection failed after ${failedAttempts} attempts`);
      
      this.connectionStatus = 'failed';
      this.mismatchAttempts = failedAttempts;
      this.mismatchInfo = {
        expected: expectedPhone,
        connected: connectedPhone
      };
      this.clearIntervals();
      
      if (data.auto_deleted) {
        useAlert('Platform WhatsApp telah dihapus otomatis setelah 3 kali percobaan gagal. Silakan buat platform baru dari halaman Platform Terhubung.');
        
        // Redirect to inbox list after auto-deletion
        setTimeout(() => {
          this.redirectToInboxList();
        }, 3000);
      } else {
        useAlert('Gagal menghubungkan ke WhatsApp setelah 3 kali percobaan. Silakan tutup jendela ini dan coba lagi.');
      }
    },

    async rescanQR() {
      if (this.connectionStatus === 'failed') {
        useAlert('Tidak dapat melakukan scan ulang. Platform telah dihapus.');
        return;
      }
      
      this.isLoading = true;
      this.connectionStatus = 'restarting';
      
      try {
        // console.log('🔄 Starting session restart...');
        
        // Restart session via API
        const response = await WhatsAppUnofficialChannels.restartSession(this.inboxId);
        
        // console.log('🔄 Restart response:', response);
        
        if (response.data?.success) {
          const method = response.data.method || 'logout_and_reset';
          let message = 'Session berhasil direset. Silakan scan QR code yang baru.';
          
          if (method === 'logout_and_reset') {
            message = 'Session berhasil di-logout. Silakan scan QR code yang baru.';
          } else if (method === 'force_reset') {
            message = 'Session di-reset paksa. Silakan scan QR code yang baru.';
          }
            
          useAlert(message);
          
          // Reset state and regenerate QR
          this.mismatchAttempts = 0;
          this.mismatchInfo = null;
          this.connectionStatus = 'waiting';
          this.countdown = 60;
          
          await this.generateQRCode();
          this.startCountdown();
          this.checkConnectionStatus();
        } else {
          const errorMsg = response.data?.message || 'Failed to restart session';
          console.error('❌ Restart failed:', response.data);
          throw new Error(errorMsg);
        }
      } catch (error) {
        console.error('❌ Failed to restart session:', error);
        
        let errorMessage = 'Gagal melakukan restart session.';
        
        if (error.response?.status === 500) {
          errorMessage = 'Server error saat restart session. Silakan coba lagi dalam beberapa saat.';
        } else if (error.response?.status === 404) {
          errorMessage = 'Endpoint restart tidak tersedia. Silakan refresh halaman.';
        } else if (error.message) {
          errorMessage = `Restart gagal: ${error.message}`;
        }
        
        useAlert(errorMessage);
        this.connectionStatus = 'disconnected';
      } finally {
        this.isLoading = false;
      }
    },

    redirectToInboxList() {
      const accountId = this.$route.params.accountId;
      router.replace({
        name: 'settings_inbox_list',
        params: { accountId }
      });
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
          :header-title="pageTitle"
          :header-content="pageDescription"
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
                <div v-else-if="connectionStatus === 'failed'" class="text-center p-6">
                  <div class="text-slate-600 dark:text-slate-400 text-sm">
                    {{ failedMessage }}
                  </div>
                </div>
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

              <p class="text-sm font-semibold text-slate-600 dark:text-slate-400 text-center mb-4">
                {{ instructionMessage }}
              </p>

              <div class="text-center">
                <div class="flex items-center justify-center space-x-3 mb-3">
                  <div 
                    class="w-3 h-3 rounded-full"
                    :class="{
                      'bg-green-500 animate-pulse': connectionStatus === 'waiting',
                      'bg-green-500': connectionStatus === 'connected',
                      'bg-orange-500 animate-pulse': connectionStatus === 'expired',
                      'bg-red-500 animate-pulse': connectionStatus === 'mismatch',
                      'bg-red-500': connectionStatus === 'failed'
                    }"
                  ></div>
                  <span 
                    class="text-sm font-medium"
                    :class="{
                      'text-green-600 dark:text-yellow-400': connectionStatus === 'waiting',
                      'text-green-600 dark:text-green-400': connectionStatus === 'connected',
                      'text-orange-600 dark:text-orange-400': connectionStatus === 'expired',
                      'text-red-600 dark:text-red-400': connectionStatus === 'mismatch' || connectionStatus === 'failed'
                    }"
                  >
                    {{ statusMessage }}
                  </span>
                </div>

                <div v-if="connectionStatus === 'waiting'" class="text-slate-600 dark:text-slate-400 text-xs">
                  {{ countdownMessage }}
                </div>

                <div v-if="connectionStatus === 'connected'" class="text-green-600 dark:text-green-400 text-xs">
                  {{ isRescanContext ? 'Mengarahkan kembali ke pengaturan...' : 'Mengarahkan ke langkah berikutnya...' }}
                </div>

                <div v-if="connectionStatus === 'expired'" class="text-orange-600 dark:text-orange-400 text-xs">
                  Kode QR akan diperbarui otomatis...
                </div>

                <div v-if="connectionStatus === 'mismatch'" class="text-red-600 dark:text-red-400 text-xs text-center">
                  <div class="mt-1">QR akan diperbarui dalam 10 detik...</div>
                  <div class="mt-2">
                    <button
                      @click="rescanQR"
                      :disabled="isLoading"
                      class="bg-blue-600 hover:bg-blue-700 disabled:bg-blue-400 text-white font-medium py-1 px-3 rounded-md text-xs transition-colors disabled:cursor-not-allowed"
                    >
                      {{ isLoading ? 'Memuat...' : 'Scan Ulang Sekarang' }}
                    </button>
                  </div>
                </div>

                <div v-if="connectionStatus === 'failed'" class="text-red-600 dark:text-red-400 text-xs text-center">
                  <div class="mt-2">
                    <button
                      @click="redirectToInboxList"
                      class="bg-blue-600 hover:bg-blue-700 text-white font-medium py-2 px-4 rounded-md text-sm transition-colors"
                    >
                      Kembali ke Platform Terhubung
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Instructions Section -->
          <div v-if="connectionStatus !== 'failed'" class="flex-1 max-w-md">
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