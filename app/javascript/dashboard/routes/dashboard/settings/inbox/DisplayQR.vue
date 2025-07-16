<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import router from '../../../index';
import PageHeader from '../SettingsSubPageHeader.vue';

export default {
  components: {
    PageHeader,
  },
  data() {
    return {
      qrCodeData: null,
      connectionStatus: 'waiting', // waiting, connected, expired
      countdown: 30,
      countdownInterval: null,
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
          return 'Status: Menunggu pemindaian...';
        case 'connected':
          return 'Status: Berhasil terhubung!';
        case 'expired':
          return 'Status: Menghasilkan kode QR baru...';
        default:
          return 'Status: Memuat...';
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
    if (this.countdownInterval) {
      clearInterval(this.countdownInterval);
    }
  },
  methods: {
    async generateQRCode() {
      try {
        this.isLoading = true;
        const inboxId = this.$route.params.inbox_id;
        
        // Simulasi API call untuk generate QR code
        // Ganti dengan actual API call
        // const response = await fetch(`/api/v1/accounts/${this.$route.params.accountId}/inboxes/${inboxId}/whatsapp/qr`, {
        //   method: 'POST',
        //   headers: {
        //     'Content-Type': 'application/json',
        //   },
        // });
        
        // if (response.ok) {
        //   const data = await response.json();
        //   this.qrCodeData = data.qr_code; // Base64 QR code atau URL
        // } else {
        //   throw new Error('Failed to generate QR code');
        // }
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
      clearInterval(this.countdownInterval);
      
      // Auto refresh QR code setelah 1 detik
      setTimeout(async () => {
        await this.refreshQRCode();
      }, 1000);
    },

    async refreshQRCode() {
      this.countdown = 30;
      this.connectionStatus = 'waiting';
      // await this.generateQRCode();
      this.startCountdown();
      this.checkConnectionStatus();
    },

    async checkConnectionStatus() {
      // Poll untuk check status koneksi setiap 2 detik
      const statusInterval = setInterval(async () => {
        if (this.connectionStatus === 'connected') {
          clearInterval(statusInterval);
          return;
        }

        // Skip status check jika sedang expired (dalam proses refresh)
        if (this.connectionStatus === 'expired') {
          return;
        }

        try {
          const inboxId = this.$route.params.inbox_id;
          const response = await fetch(`/api/v1/accounts/${this.$route.params.accountId}/inboxes/${inboxId}/whatsapp/status`);
          
          if (response.ok) {
            const data = await response.json();
            if (data.connected) {
              this.connectionStatus = 'connected';
              clearInterval(statusInterval);
              clearInterval(this.countdownInterval);
              
              // Auto redirect ke next step setelah 2 detik
              setTimeout(() => {
                this.proceedToNextStep();
              }, 2000);
            }
          }
        } catch (error) {
          console.error('Status check error:', error);
        }
      }, 2000);
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
          <!-- QR Code Section -->
          <div class="flex-shrink-0 text-center">
            <div class="bg-white p-6 rounded-lg shadow-md inline-block mb-4">
              <div class="w-64 h-64 flex items-center justify-center">
                <div v-if="isLoading" class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
                <img 
                  v-else-if="qrCodeData" 
                  :src="qrCodeData" 
                  alt="WhatsApp QR Code" 
                  class="w-full h-full object-contain"
                />
                <div v-else class="text-slate-500 text-center">
                  Gagal memuat QR Code
                </div>
              </div>
            </div>
            
            <p class="text-sm font-medium text-slate-700 dark:text-slate-300 mb-4">
              Pindai Kode Ini Menggunakan Aplikasi WhatsApp Anda
            </p>

            <!-- Status Section Below QR Code -->
            <div class="text-center">
              <div class="flex items-center justify-center space-x-3 mb-3">
                <div 
                  class="w-3 h-3 rounded-full"
                  :class="{
                    'bg-yellow-500 animate-pulse': connectionStatus === 'waiting',
                    'bg-green-500': connectionStatus === 'connected',
                    'bg-orange-500 animate-pulse': connectionStatus === 'expired'
                  }"
                ></div>
                <span 
                  class="text-lg font-medium"
                  :class="{
                    'text-yellow-400': connectionStatus === 'waiting',
                    'text-green-400': connectionStatus === 'connected',
                    'text-orange-400': connectionStatus === 'expired'
                  }"
                >
                  {{ statusMessage }}
                </span>
              </div>

              <div v-if="connectionStatus === 'waiting'" class="text-slate-400">
                {{ countdownMessage }}
              </div>

              <div v-if="connectionStatus === 'connected'" class="text-green-400">
                Mengarahkan ke langkah berikutnya...
              </div>

              <div v-if="connectionStatus === 'expired'" class="text-orange-400">
                Kode QR akan diperbarui otomatis...
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