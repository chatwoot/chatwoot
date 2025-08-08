<script>
import WhatsAppUnofficialChannels from 'dashboard/api/WhatsAppUnofficialChannels';
import { createConsumer } from '@rails/actioncable';
import { mapGetters } from 'vuex';

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
  computed: {
    ...mapGetters({
      currentUser: 'getCurrentUser',
      currentAccountId: 'getCurrentAccountId',
      currentUserId: 'getCurrentUserID',
    }),
    userPubsubToken() {
      return this.currentUser?.pubsub_token;
    },
  },
  async mounted() {
    await this.checkStatus();
    this.setupWebSocketSubscription();
    if (this.autoRefresh) {
      this.startAutoRefresh();
    }
    
    // Add a test method to manually trigger status check for debugging
    window[`testWhatsAppStatus_${this.inboxId}`] = () => {
      this.checkStatus();
    };
  },
  beforeUnmount() {
    this.stopAutoRefresh();
    this.disconnectWebSocket();
  },
  methods: {
    async checkStatus() {
      try {
        const response = await WhatsAppUnofficialChannels.getConnectionStatus(this.inboxId, true);
        const newConnected = response.data?.connected || false;
        const oldConnected = this.connected;
        
        this.connected = newConnected;
                
        this.$emit('status-changed', {
          connected: this.connected,
          inboxId: this.inboxId,
          lastChecked: Date.now(),
          statusChanged: oldConnected !== newConnected,
          source: 'real-time'
        });
      } catch (error) {
        console.error(`❌ Failed to check WhatsApp status for inbox ${this.inboxId}:`, error);
        this.connected = false;
        
        this.$emit('status-changed', {
          connected: false,
          inboxId: this.inboxId,
          lastChecked: Date.now(),
          error: true,
          source: 'real-time'
        });
      }
    },

    setupWebSocketSubscription() {
      try {
        // Use user's pubsub_token for authentication (same as BaseActionCableConnector)
        const pubsub_token = this.userPubsubToken;
        const cable = createConsumer();

        if (!pubsub_token || !this.currentUserId || !this.currentAccountId) {
          console.error(`❌ Cannot setup WebSocket: missing required data`);
          return;
        }
        
        this.subscription = cable.subscriptions.create(
          { 
            channel: 'RoomChannel',
            pubsub_token: pubsub_token,
            user_id: this.currentUserId,
            account_id: this.currentAccountId
          },
          {
            connected: () => {
            },
            disconnected: () => {
            },
            received: (data) => {              
              if (data.event === 'whatsapp_status_changed') {
                const isForOurInbox = data.inbox_id === parseInt(this.inboxId) || 
                                    (!data.inbox_id && data.phone_number); // fallback for old messages
                
                if (isForOurInbox) {
                  this.handleStatusUpdate(data);
                } else {
                }
              }
            },
          }
        );
      } catch (error) {
        console.error(`❌ Failed to setup WebSocket for inbox ${this.inboxId}:`, error);
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
          lastUpdated: Date.now(),
          updateSource: 'websocket',
          updateType: data.type || 'status'
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
        this.checkStatus();
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
