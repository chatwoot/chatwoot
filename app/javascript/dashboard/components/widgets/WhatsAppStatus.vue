<script>
import WhatsAppUnofficialChannels from 'dashboard/api/WhatsAppUnofficialChannels';
import { createConsumer } from '@rails/actioncable';
import { useAlert } from 'dashboard/composables';

export default {
  props: {
    inboxId: {
      type: [Number, String],
      required: true,
    },
    accountId: {
      type: [Number, String],
      required: true,
    },
    autoRefresh: {
      type: Boolean,
      default: true,
    },
    refreshInterval: {
      type: Number,
      default: 10000, // 10 seconds
    },
  },
  data() {
    return {
      connectionStatus: 'checking',
      lastChecked: null,
      isLoading: false,
      refreshTimer: null,
      subscription: null,
      canRestart: true, // Default to true to show button initially
      isFromRestart: false, // Track if connection is from restart/re-scan
    };
  },
  computed: {
    statusColor() {
      switch (this.connectionStatus) {
        case 'connected':
        case 'logged_in':
          return 'text-green-600 dark:text-green-400';
        case 'disconnected':
        case 'not_logged_in':
          return 'text-red-600 dark:text-red-400';
        case 'pending_validation':
          return 'text-yellow-600 dark:text-yellow-400';
        case 'checking':
          return 'text-gray-600 dark:text-gray-400';
        default:
          return 'text-gray-600 dark:text-gray-400';
      }
    },
    statusText() {
      switch (this.connectionStatus) {
        case 'connected':
        case 'logged_in':
          return 'WhatsApp Terhubung';
        case 'disconnected':
        case 'not_logged_in':
          return 'WhatsApp Terputus';
        case 'pending_validation':
          return 'Menunggu validasi';
        case 'checking':
          return 'Memeriksa...';
        default:
          return 'Tidak diketahui';
      }
    },
    statusIcon() {
      switch (this.connectionStatus) {
        case 'connected':
        case 'logged_in':
          return 'check-circle';
        case 'disconnected':
        case 'not_logged_in':
          return 'x-circle';
        case 'pending_validation':
          return 'clock';
        case 'checking':
          return 'refresh-cw';
        default:
          return 'help-circle';
      }
    },
    lastCheckedText() {
      if (!this.lastChecked) return 'Belum pernah diperiksa';
      return `Terakhir diperbarui: ${this.lastChecked.toLocaleTimeString('id-ID')}`;
    },
    connectedStatusText() {
      if (this.connectionStatus === 'connected' || this.connectionStatus === 'logged_in') {
        if (this.lastChecked) {
          return `WhatsApp Terhubung\nTerakhir diperbarui: ${this.lastChecked.toLocaleTimeString('id-ID')}`;
        }
        return 'WhatsApp Terhubung';
      }
      return this.statusText;
    },
    showActionButton() {
      // Hide button when connected, show when disconnected
      return this.connectionStatus !== 'connected' && this.connectionStatus !== 'logged_in';
    },
  },
  async mounted() {
    await this.checkStatus(true); // Real-time check on mount
    this.setupWebSocketSubscription();
    if (this.autoRefresh) {
      this.startAutoRefresh();
    }
  },
  beforeUnmount() {
    this.stopAutoRefresh();
    this.disconnectWebSocket();
  },
  methods: {
    async checkStatus(realTime = false) {
      this.isLoading = true;
      try {
        const response = await WhatsAppUnofficialChannels.getConnectionStatus(
          this.inboxId,
          realTime
        );
        
        const status = response.data?.status || 'unknown';
        const connected = response.data?.connected || false;
                
        this.connectionStatus = connected ? 'connected' : status;
        this.lastChecked = new Date();
        this.canRestart = !connected && status !== 'checking';
        
        this.$emit('status-changed', {
          status: this.connectionStatus,
          connected,
          lastChecked: this.lastChecked,
        });
      } catch (error) {
        console.error('Failed to check WhatsApp status:', error);
        this.connectionStatus = 'disconnected';
        this.canRestart = true;
        
        this.$emit('status-error', error);
      } finally {
        this.isLoading = false;
      }
    },

    async restartSession() {
      if (!this.canRestart) return;
      
      this.isLoading = true;
      this.isFromRestart = true; // Mark as restart action
      
      try {
        const response = await WhatsAppUnofficialChannels.restartSession(this.inboxId);
        
        if (response.data?.success) {
          this.connectionStatus = 'pending_validation';
          this.$emit('session-restarted', response.data);
          
          // Langsung redirect ke halaman QR setelah restart
          this.goToQRPage();
        } else {
          throw new Error(response.data?.message || 'Failed to restart session');
        }
      } catch (error) {
        console.error('Failed to restart WhatsApp session:', error);
        this.$emit('restart-error', error);
        this.isFromRestart = false; // Reset flag on error
      } finally {
        this.isLoading = false;
      }
    },

    setupWebSocketSubscription() {
      try {
        const pubsub_token = `${this.accountId}_inbox_${this.inboxId}`;
        const cable = createConsumer();
        
        this.subscription = cable.subscriptions.create(
          { 
            channel: 'RoomChannel',
            pubsub_token: pubsub_token
          },
          {
            received: (data) => {
              if (data.event === 'whatsapp_status_changed') {
                this.handleStatusUpdate(data);
              } else {
              }
            },
            connected: () => {
            },
            disconnected: () => {
            }
          }
        );
      } catch (error) {
        console.error('Failed to setup WebSocket for status monitoring:', error);
      }
    },

    handleStatusUpdate(data) {
      const oldStatus = this.connectionStatus;
      
      if (data.type === 'session_ready' || data.type === 'phone_validation_success' || data.type === 'auto_reconnect') {
        this.connectionStatus = 'connected';
        this.canRestart = false;
        
        if (oldStatus !== 'connected') {
          const isOnQRPage = this.$route && this.$route.name === 'settings_inboxes_display_qrcode';
          
          if (!isOnQRPage) {
            if (this.isFromRestart) {
              useAlert('WhatsApp berhasil terkoneksi kembali!');
              this.isFromRestart = false;
            } else {
              useAlert('WhatsApp berhasil terkoneksi!');
            }
          }
        }
        
      } else if (data.type === 'session_mismatch') {
        this.connectionStatus = 'disconnected';
        this.canRestart = true;
      } else if (data.type === 'session_failed') {
        this.connectionStatus = 'disconnected';
        this.canRestart = !data.auto_deleted; // Can't restart if auto-deleted
      } else if (data.type === 'auto_disconnect') {
        // Handle auto-detected disconnect from status polling
        this.connectionStatus = 'disconnected';
        this.canRestart = true;
        
        // Show notification about disconnect
        if (oldStatus === 'connected') {
          useAlert('WhatsApp terputus dari perangkat. Silakan scan ulang untuk menghubungkan kembali.');
        }
      } else if (data.status) {
        this.connectionStatus = data.connected ? 'connected' : data.status;
        this.canRestart = !data.connected;
        
        // Show success alert when status changes to connected (without auto-redirect)
        if (data.connected && oldStatus !== 'connected') {
          // Check if user is currently on QR page to avoid duplicate alerts
          const isOnQRPage = this.$route && this.$route.name === 'settings_inboxes_display_qrcode';
          
          if (!isOnQRPage) {
            if (this.isFromRestart) {
              useAlert('WhatsApp berhasil terkoneksi kembali!');
              this.isFromRestart = false; // Reset flag
            } else {
              useAlert('WhatsApp berhasil terkoneksi!');
            }
          }
        }
      }
      
      this.lastChecked = new Date();
      
      if (oldStatus !== this.connectionStatus) {
        this.$emit('status-changed', {
          status: this.connectionStatus,
          connected: this.connectionStatus === 'connected',
          lastChecked: this.lastChecked,
        });
      } else {
      }
    },

    disconnectWebSocket() {
      if (this.subscription) {
        this.subscription.unsubscribe();
        this.subscription = null;
      }
    },

    startAutoRefresh() {
      this.refreshTimer = setInterval(() => {
        // Always refresh for real-time monitoring, regardless of connection status
        this.checkStatus(true);
      }, this.refreshInterval);
    },

    stopAutoRefresh() {
      if (this.refreshTimer) {
        clearInterval(this.refreshTimer);
        this.refreshTimer = null;
      }
    },

    async forceRefresh() {
      await this.checkStatus(true);
    },

    goToQRPage() {
      // Navigate to QR page for this inbox with rescan context
      this.$router.push({
        name: 'settings_inboxes_display_qrcode',
        params: {
          accountId: this.accountId,
          inbox_id: this.inboxId,
        },
        query: {
          rescan: 'true'
        }
      });
    },

    redirectToInboxListWithSuccess() {
      // Show success toast
      useAlert('WhatsApp berhasil terkoneksi kembali!');
      
      // Redirect to inbox list after short delay
      setTimeout(() => {
        this.$router.push({
          name: 'settings_inbox_list',
          params: {
            accountId: this.accountId,
          }
        });
      }, 1500);
    },
  },
};
</script>

<template>
  <div class="whatsapp-status-widget p-4 border rounded-lg bg-white dark:bg-slate-800 border-slate-200 dark:border-slate-700">
    <!-- Status Header -->
    <div class="flex items-center justify-between mb-3">
      <div class="flex items-center space-x-2">
        <svg
          class="w-5 h-5"
          :class="statusColor"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path
            v-if="statusIcon === 'check-circle'"
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
          />
          <path
            v-else-if="statusIcon === 'x-circle'"
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z"
          />
          <path
            v-else-if="statusIcon === 'clock'"
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
          />
          <path
            v-else-if="statusIcon === 'refresh-cw'"
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0V9a8 8 0 1115.356 2M15 15v5h-.582M4.582 15A8.001 8.001 0 0019.418 15M19.418 15V15a8 8 0 11-15.356-2"
          />
          <path
            v-else
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
          />
        </svg>
        <span class="font-medium text-gray-900 dark:text-slate-100">
          Status WhatsApp
        </span>
      </div>
      
      <!-- Action Buttons -->
      <div class="flex items-center space-x-2">
        <button
          @click="forceRefresh"
          :disabled="isLoading"
          class="p-1 text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200 disabled:opacity-50"
          title="Refresh status"
        >
          <svg
            class="w-4 h-4"
            :class="{ 'animate-spin': isLoading }"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0V9a8 8 0 1115.356 2M15 15v5h-.582M4.582 15A8.001 8.001 0 0019.418 15M19.418 15V15a8 8 0 11-15.356-2"
            />
          </svg>
        </button>
        
        <!-- Debug Button - Show only when not connected -->
        <button
          v-if="showActionButton"
          @click="restartSession"
          :disabled="isLoading"
          class="inline-flex items-center px-4 py-2 text-sm font-medium text-white bg-green-600 border border-green-600 rounded-md hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-green-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed"
          style="min-width: 100px;"
        >
          <span v-if="isLoading">Memuat...</span>
          <span v-else>Scan Ulang</span>
        </button>
      </div>
    </div>

    <!-- Status Info -->
    <div class="flex items-center justify-between">
      <div>
        <div class="flex items-center space-x-2">
          <!-- Connection Status Circle for better visual feedback -->
          <div
            class="w-3 h-3 rounded-full border border-white shadow-sm"
            :class="{
              'bg-green-500': connectionStatus === 'connected' || connectionStatus === 'logged_in',
              'bg-red-500': connectionStatus === 'disconnected' || connectionStatus === 'not_logged_in',
              'bg-yellow-500': connectionStatus === 'pending_validation',
              'bg-gray-500': connectionStatus === 'checking' || connectionStatus === 'unknown'
            }"
          ></div>
          <span :class="statusColor" class="font-medium">{{ statusText }}</span>
          <div
            v-if="isLoading"
            class="w-3 h-3 border-2 border-green-500 border-t-transparent rounded-full animate-spin"
          ></div>
        </div>
        <div class="text-xs text-gray-500 dark:text-gray-400 mt-1">
          {{ lastCheckedText }}
        </div>
      </div>
    </div>

    <!-- Connection Guide -->
        <!-- Connection Guide -->
    <div
      v-if="connectionStatus === 'disconnected' || connectionStatus === 'not_logged_in'"
      class="mt-3 p-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded"
    >
      <p class="text-sm text-red-700 dark:text-red-300">
        Koneksi WhatsApp terputus. Silakan klik tombol "Scan Ulang" untuk menyambung ulang channel ini.
      </p>
    </div>

    <div
      v-else-if="connectionStatus === 'pending_validation'"
      class="mt-3 p-3 bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded"
    >
      <p class="text-sm text-yellow-700 dark:text-yellow-300">
        Menunggu validasi QR code. Silakan scan kode QR dengan WhatsApp Anda.
      </p>
    </div>

    <!-- Note: Removed redundant green box when connected since status is already shown above -->
  </div>
</template>

<style scoped>
.animate-spin {
  animation: spin 1s linear infinite;
}

.animate-ping {
  animation: ping 1s cubic-bezier(0, 0, 0.2, 1) infinite;
}

@keyframes spin {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}

@keyframes ping {
  75%, 100% {
    transform: scale(2);
    opacity: 0;
  }
}
</style>
