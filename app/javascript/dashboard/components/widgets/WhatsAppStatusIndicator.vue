<script>
import WhatsAppUnofficialChannels from 'dashboard/api/WhatsAppUnofficialChannels';
import { createConsumer } from '@rails/actioncable';

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
      default: 15000, // 15 seconds
    },
  },
  data() {
    return {
      connected: null, // null = unknown, true = connected, false = disconnected
      subscription: null,
      refreshTimer: null,
    };
  },
  async mounted() {
    await this.checkStatus();
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
    async checkStatus() {
      try {
        const response = await WhatsAppUnofficialChannels.getConnectionStatus(this.inboxId, false);
        this.connected = response.data?.connected || false;
        
        this.$emit('status-changed', {
          connected: this.connected,
          inboxId: this.inboxId,
        });
      } catch (error) {
        console.error('Failed to check WhatsApp status:', error);
        this.connected = false;
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
              }
            },
          }
        );
      } catch (error) {
        console.error('Failed to setup WebSocket for status monitoring:', error);
      }
    },

    handleStatusUpdate(data) {
      const oldConnected = this.connected;
      
      if (data.type === 'session_ready' || data.type === 'phone_validation_success' || data.type === 'auto_reconnect') {
        this.connected = true;
      } else if (data.type === 'session_mismatch' || data.type === 'session_failed' || data.type === 'auto_disconnect') {
        this.connected = false;
      } else if (data.status) {
        this.connected = data.connected || false;
      }
      
      if (oldConnected !== this.connected) {
        this.$emit('status-changed', {
          connected: this.connected,
          inboxId: this.inboxId,
        });
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
        if (this.connected !== true) {
          this.checkStatus();
        }
      }, this.refreshInterval);
    },

    stopAutoRefresh() {
      if (this.refreshTimer) {
        clearInterval(this.refreshTimer);
        this.refreshTimer = null;
      }
    },
  },
};
</script>

<template>
  <div class="relative flex items-center">
    <div
      class="w-4 h-4 rounded-full border-2 shadow-md"
      :class="{
        'bg-green-500 border-white dark:border-slate-800': connected === true,
        'bg-red-500 border-white dark:border-slate-800': connected === false,
        'bg-gray-400 border-white dark:border-slate-800': connected === null
      }"
      :title="connected === true ? 'WhatsApp Terhubung' : connected === false ? 'WhatsApp Terputus' : 'Status tidak diketahui'"
    ></div>
    <!-- Pulse animation for connected status -->
    <div
      v-if="connected === true"
      class="absolute inset-0 w-4 h-4 rounded-full bg-green-500 animate-ping opacity-75"
    ></div>
  </div>
</template>

<style scoped>
.animate-ping {
  animation: ping 1s cubic-bezier(0, 0, 0.2, 1) infinite;
}

@keyframes ping {
  75%, 100% {
    transform: scale(2);
    opacity: 0;
  }
}
</style>
