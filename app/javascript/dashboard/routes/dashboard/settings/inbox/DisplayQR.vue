<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import router from '../../../index';
import PageHeader from '../SettingsSubPageHeader.vue';
import WhatsAppUnofficialChannels from 'dashboard/api/WhatsAppUnofficialChannels';

export default {
  components: {
    PageHeader,
  },
  data() {
    return {
      qrCodeData: null,
      connectionStatus: 'waiting', // waiting, connected, expired
      countdown: 60,
      countdownInterval: null,
      statusInterval: null,
      isLoading: true,
      isConnecting: false,
    };
  },
  computed: {
    ...mapGetters({
      globalConfig: 'globalConfig/get',
    }),
    statusMessage() {
      switch (this.connectionStatus) {
        case 'waiting':
          return 'Menunggu pemindaian...';
        case 'connected':
          return 'Berhasil terhubung!';
        case 'expired':
          return 'Menghasilkan kode QR baru...';
        default:
          return 'Memuat...';
      }
    },
    countdownMessage() {
      return `Kode QR akan kedaluwarsa dalam ${this.countdown} detik`;
    }
  },
  async mounted() {
    await this.generateQRCode();
    this.startCountdown();
    this.checkConnectionStatus();
  },
  beforeUnmount() {
    this.clearIntervals();
  },
  methods: {
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
        if (this.connectionStatus === 'connected') {
          this.clearIntervals();
          return;
        }

        if (this.connectionStatus === 'expired') {
          return;
        }

        try {
          const inboxId = this.$route.params.inbox_id;
          const accountId = this.$route.params.accountId;
          
          const response = await WhatsAppUnofficialChannels.getConnectionStatus(inboxId);
          
          console.log('Status check response:', response.data); // Debug log
          
          // Fix: Check the correct nested structure
          if (response.data.success && response.data.data && response.data.data.connected) {
            console.log('WhatsApp connected! Proceeding to next step...');
            this.connectionStatus = 'connected';
            this.clearIntervals();
            
            setTimeout(() => {
              this.proceedToNextStep();
            }, 5000);
          } else {
            console.log('Still waiting for connection. Status:', response.data.data?.status);
          }
        } catch (error) {
          console.error('Status check error:', error);
        }
      }, 5000);
    },

    clearIntervals() {
      if (this.countdownInterval) {
        clearInterval(this.countdownInterval);
        this.countdownInterval = null;
      }
      if (this.statusInterval) {
        clearInterval(this.statusInterval);
        this.statusInterval = null;
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
                Pindai kode ini menggunakan aplikasi WhatsApp Anda
              </p>

              <!-- Status Display -->
              <div class="text-center">
                <div class="flex items-center justify-center space-x-3 mb-3">
                  <div 
                    class="w-3 h-3 rounded-full"
                    :class="{
                      'bg-green-500 animate-pulse': connectionStatus === 'waiting',
                      'bg-green-500': connectionStatus === 'connected',
                      'bg-green-500 animate-pulse': connectionStatus === 'expired'
                    }"
                  ></div>
                  <span 
                    class="text-sm font-medium"
                    :class="{
                      'text-green-600 dark:text-yellow-400': connectionStatus === 'waiting',
                      'text-green-600 dark:text-green-400': connectionStatus === 'connected',
                      'text-green-600 dark:text-orange-400': connectionStatus === 'expired'
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
              </div>
            </div>
          </div>

          <!-- Instructions Section -->
          <div class="flex-1 max-w-md">
            <div class="p-6 pt-0 rounded-lg">
              <h4 class="font-semibold text-slate-800 dark:text-slate-200 mb-4">
                Cara Memindai:
              </h4>
              <ol class="list-decimal list-inside space-y-3 text-slate-600 dark:text-slate-400">
                <li>Buka WhatsApp di ponsel Anda.</li>
                <li>Masuk ke Setelan > Perangkat Tertaut.</li>
                <li>Pilih "Tautkan Perangkat" dan arahkan kamera ponsel Anda ke kode ini.</li>
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