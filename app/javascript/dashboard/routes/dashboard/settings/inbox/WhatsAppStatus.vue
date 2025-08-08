<script>
import { mapGetters } from 'vuex';
import WhatsAppStatus from 'dashboard/components/widgets/WhatsAppStatus.vue';
import WhatsAppUnofficialChannels from 'dashboard/api/WhatsAppUnofficialChannels';
import { useAlert } from 'dashboard/composables';

export default {
  components: {
    WhatsAppStatus,
  },
  data() {
    return {
      inbox: null,
      isLoading: true,
      showQRModal: false,
      qrCodeData: null,
      isGeneratingQR: false,
    };
  },
  computed: {
    ...mapGetters({
      currentUser: 'getCurrentUser',
    }),
    inboxId() {
      return this.$route.params.inboxId;
    },
    accountId() {
      return this.$route.params.accountId;
    },
    isWhatsAppUnofficial() {
      return this.inbox?.channel_type === 'Channel::WhatsappUnofficial';
    },
  },
  async mounted() {
    await this.fetchInboxData();
  },
  methods: {
    async fetchInboxData() {
      try {
        const response = await this.$http.get(`inboxes/${this.inboxId}`);
        this.inbox = response.data;
      } catch (error) {
        console.error('Failed to fetch inbox data:', error);
        useAlert('Gagal memuat data inbox');
      } finally {
        this.isLoading = false;
      }
    },

    onStatusChanged(statusData) {
      // Update local state or trigger other actions if needed
    },

    onStatusError(error) {
      console.error('WhatsApp status error:', error);
      useAlert('Gagal memeriksa status WhatsApp');
    },

    onSessionRestarted(data) {
      useAlert('Session WhatsApp berhasil direstart');
    },

    onRestartError(error) {
      console.error('WhatsApp restart error:', error);
      useAlert('Gagal restart session WhatsApp');
    },

    async showQRCode() {
      this.isGeneratingQR = true;
      this.showQRModal = true;
      
      try {
        const response = await WhatsAppUnofficialChannels.generateQR(this.inboxId);
        
        if (response.data.success && response.data.qr_code) {
          this.qrCodeData = `data:image/png;base64,${response.data.qr_code}`;
        } else {
          throw new Error(response.data.message || 'Failed to generate QR code');
        }
      } catch (error) {
        console.error('Failed to generate QR code:', error);
        useAlert('Gagal menghasilkan QR code');
        this.closeQRModal();
      } finally {
        this.isGeneratingQR = false;
      }
    },

    closeQRModal() {
      this.showQRModal = false;
      this.qrCodeData = null;
    },

    goToInboxSettings() {
      this.$router.push({
        name: 'settings_inbox_show',
        params: {
          accountId: this.accountId,
          inboxId: this.inboxId,
        },
      });
    },
  },
};
</script>

<template>
  <div class="max-w-4xl mx-auto p-6">
    <!-- Header -->
    <div class="mb-6">
      <div class="flex items-center justify-between">
        <div>
          <h1 class="text-2xl font-bold text-gray-900 dark:text-gray-100">
            Status WhatsApp
          </h1>
          <p class="text-gray-600 dark:text-gray-400 mt-1">
            Monitor dan kelola koneksi WhatsApp Anda
          </p>
        </div>
        <button
          @click="goToInboxSettings"
          class="px-4 py-2 text-sm bg-gray-100 hover:bg-gray-200 dark:bg-gray-700 dark:hover:bg-gray-600 text-gray-700 dark:text-gray-200 rounded-lg transition-colors"
        >
          Pengaturan Inbox
        </button>
      </div>
    </div>

    <!-- Loading State -->
    <div v-if="isLoading" class="flex items-center justify-center py-12">
      <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      <span class="ml-2 text-gray-600 dark:text-gray-400">Memuat data inbox...</span>
    </div>

    <!-- Content -->
    <div v-else-if="inbox" class="space-y-6">
      <!-- Inbox Info -->
      <div class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6">
        <h2 class="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-4">
          Informasi Inbox
        </h2>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
              Nama Inbox
            </label>
            <p class="mt-1 text-gray-900 dark:text-gray-100">{{ inbox.name }}</p>
          </div>
          <div v-if="isWhatsAppUnofficial">
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
              Nomor WhatsApp
            </label>
            <p class="mt-1 text-gray-900 dark:text-gray-100">{{ inbox.phone_number }}</p>
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
              Tipe Channel
            </label>
            <p class="mt-1 text-gray-900 dark:text-gray-100">{{ inbox.channel_type }}</p>
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
              Status
            </label>
            <span
              class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium"
              :class="inbox.status === 'active' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'"
            >
              {{ inbox.status === 'active' ? 'Aktif' : 'Tidak Aktif' }}
            </span>
          </div>
        </div>
      </div>

      <!-- WhatsApp Status Widget -->
      <div v-if="isWhatsAppUnofficial">
        <WhatsAppStatus
          :inbox-id="inboxId"
          :account-id="accountId"
          :auto-refresh="true"
          :refresh-interval="10000"
          @status-changed="onStatusChanged"
          @status-error="onStatusError"
          @session-restarted="onSessionRestarted"
          @restart-error="onRestartError"
        />
      </div>

      <!-- Actions -->
      <div v-if="isWhatsAppUnofficial" class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6">
        <h2 class="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-4">
          Aksi Cepat
        </h2>
        <div class="flex flex-wrap gap-3">
          <button
            @click="showQRCode"
            class="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors"
          >
            Tampilkan QR Code
          </button>
          <button
            @click="$refs.whatsappStatus?.forceRefresh()"
            class="px-4 py-2 bg-green-600 hover:bg-green-700 text-white rounded-lg transition-colors"
          >
            Refresh Status
          </button>
        </div>
      </div>

      <!-- Non-WhatsApp Message -->
      <div v-else class="bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg p-6">
        <div class="flex">
          <svg class="w-6 h-6 text-yellow-600 dark:text-yellow-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L4.082 15.5c-.77.833.192 2.5 1.732 2.5z" />
          </svg>
          <div class="ml-3">
            <h3 class="text-sm font-medium text-yellow-800 dark:text-yellow-200">
              Status monitoring tidak tersedia
            </h3>
            <p class="mt-2 text-sm text-yellow-700 dark:text-yellow-300">
              Fitur monitoring status real-time hanya tersedia untuk channel WhatsApp (Unofficial).
            </p>
          </div>
        </div>
      </div>
    </div>

    <!-- Error State -->
    <div v-else class="text-center py-12">
      <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L4.082 15.5c-.77.833.192 2.5 1.732 2.5z" />
      </svg>
      <h3 class="mt-2 text-sm font-medium text-gray-900 dark:text-gray-100">Gagal memuat data</h3>
      <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
        Tidak dapat memuat informasi inbox. Silakan coba lagi.
      </p>
      <div class="mt-6">
        <button
          @click="fetchInboxData"
          class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700"
        >
          Coba Lagi
        </button>
      </div>
    </div>

    <!-- QR Code Modal -->
    <div
      v-if="showQRModal"
      class="fixed inset-0 z-50 overflow-y-auto"
      aria-labelledby="modal-title"
      role="dialog"
      aria-modal="true"
    >
      <div class="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
        <!-- Overlay -->
        <div
          class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity"
          @click="closeQRModal"
        ></div>

        <!-- Modal -->
        <div class="inline-block align-bottom bg-white dark:bg-gray-800 rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full">
          <div class="bg-white dark:bg-gray-800 px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
            <div class="sm:flex sm:items-start">
              <div class="mt-3 text-center sm:mt-0 sm:text-left w-full">
                <h3 class="text-lg leading-6 font-medium text-gray-900 dark:text-gray-100 mb-4">
                  QR Code WhatsApp
                </h3>
                
                <!-- QR Code Display -->
                <div class="flex justify-center">
                  <div v-if="isGeneratingQR" class="flex items-center justify-center w-64 h-64 bg-gray-100 dark:bg-gray-700 rounded-lg">
                    <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
                  </div>
                  <img 
                    v-else-if="qrCodeData" 
                    :src="qrCodeData" 
                    alt="WhatsApp QR Code" 
                    class="w-64 h-64 object-contain border rounded-lg"
                  />
                </div>

                <p class="text-sm text-gray-600 dark:text-gray-400 text-center mt-4">
                  Scan QR code ini dengan aplikasi WhatsApp Anda untuk menghubungkan.
                </p>
              </div>
            </div>
          </div>
          <div class="bg-gray-50 dark:bg-gray-700 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse">
            <button
              @click="closeQRModal"
              type="button"
              class="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-blue-600 text-base font-medium text-white hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 sm:ml-3 sm:w-auto sm:text-sm"
            >
              Tutup
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.animate-spin {
  animation: spin 1s linear infinite;
}

@keyframes spin {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}
</style>
