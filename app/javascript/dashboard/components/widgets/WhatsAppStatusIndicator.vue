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
    console.log(`🔍 WhatsAppStatusIndicator mounted for inbox ${this.inboxId}`);
    await this.checkStatus();
    this.setupWebSocketSubscription();
    if (this.autoRefresh) {
      this.startAutoRefresh();
    }
    
    // Add a test method to manually trigger status check for debugging
    window[`testWhatsAppStatus_${this.inboxId}`] = () => {
      console.log(`🧪 Manual test triggered for inbox ${this.inboxId}`);
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
        console.log(`🔄 Checking WhatsApp status for inbox ${this.inboxId}...`);
        // Force real-time check for accurate red/green dot status
        const response = await WhatsAppUnofficialChannels.getConnectionStatus(this.inboxId, true);
        const newConnected = response.data?.connected || false;
        const oldConnected = this.connected;
        
        this.connected = newConnected;
        
        console.log(`📱 Inbox ${this.inboxId} status (real-time): ${newConnected ? '🟢 Connected' : '🔴 Disconnected'}`);
        
        // Always emit status change to parent, even if status hasn't changed
        // This helps parent component track that checking was performed
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
        
        console.log(`🔌 Setting up WebSocket subscription for inbox ${this.inboxId}`);
        console.log(`👤 User pubsub token: ${pubsub_token}`);
        console.log(`👤 Current user ID: ${this.currentUserId}, Account ID: ${this.currentAccountId}`);
        
        if (!pubsub_token || !this.currentUserId || !this.currentAccountId) {
          console.error(`❌ Cannot setup WebSocket: missing required data`);
          console.error(`   - User pubsub token: ${pubsub_token}`);
          console.error(`   - User ID: ${this.currentUserId}`);
          console.error(`   - Account ID: ${this.currentAccountId}`);
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
              console.log(`✅ WebSocket connected for inbox ${this.inboxId}`);
            },
            disconnected: () => {
              console.log(`❌ WebSocket disconnected for inbox ${this.inboxId}`);
            },
            received: (data) => {
              console.log(`📨 WebSocket message received:`, data);
              
              // Filter messages that are relevant to this specific inbox
              if (data.event === 'whatsapp_status_changed') {
                // Check if this message is for our inbox
                const isForOurInbox = data.inbox_id === parseInt(this.inboxId) || 
                                    (!data.inbox_id && data.phone_number); // fallback for old messages
                
                if (isForOurInbox) {
                  console.log(`� WhatsApp status change for our inbox ${this.inboxId}:`, data);
                  this.handleStatusUpdate(data);
                } else {
                  console.log(`📨 Ignoring WhatsApp status change for different inbox (${data.inbox_id})`);
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
      console.log(`🔄 Handling WebSocket status update for inbox ${this.inboxId}:`, data);
      
      const oldConnected = this.connected;
      
      if (data.type === 'session_ready' || data.type === 'phone_validation_success' || data.type === 'auto_reconnect') {
        this.connected = true;
        console.log(`📱 Inbox ${this.inboxId} status changed to: 🟢 Connected (${data.type})`);
      } else if (data.type === 'session_mismatch' || data.type === 'session_failed' || data.type === 'auto_disconnect') {
        this.connected = false;
        console.log(`📱 Inbox ${this.inboxId} status changed to: 🔴 Disconnected (${data.type})`);
      } else if (data.status) {
        this.connected = data.connected || false;
        console.log(`📱 Inbox ${this.inboxId} status update:`, this.connected ? '🟢 Connected' : '🔴 Disconnected');
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
        // Check status more frequently if not connected or status unknown
        if (this.connected !== true) {
          console.log(`⏰ Auto-refresh triggered for inbox ${this.inboxId} (status: ${this.connected})`);
          this.checkStatus();
        }
      }, this.refreshInterval);
      
      console.log(`⏰ Auto-refresh started for inbox ${this.inboxId} (interval: ${this.refreshInterval}ms)`);
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
