import { defineStore } from 'pinia';
import { useAuthStore } from './auth';
// import conversationsAPI from '../api/conversations';

export const useConversationStore = defineStore('conversations', {
  state: () => ({
    conversations: [],
    activeConversationId: null,
    messages: {},
    websocket: null,
    isLoading: false,
    error: null,
  }),

  actions: {
    async fetchConversations() {
      this.isLoading = true;
      this.error = null;
      try {
        // Placeholder data
        this.conversations = [
          { id: 'conv_1', account_id: 'acc_123', status: 'open', last_activity_at: new Date().toISOString(), participants: [{ name: 'AI Assistant' }] },
        ];
        // For simplicity, we'll auto-select the first conversation
        if (this.conversations.length > 0) {
            this.setActiveConversation(this.conversations[0].id);
        }
      } catch (error) {
        this.error = 'Failed to fetch conversations.';
      } finally {
        this.isLoading = false;
      }
    },

    async fetchMessages(conversationId) {
      if (this.messages[conversationId]) return;
      // In a real app, we'd fetch history here. For now, we start fresh.
      this.messages[conversationId] = [];
    },

    setActiveConversation(conversationId) {
      if (this.activeConversationId === conversationId) return;
      this.disconnect();
      this.activeConversationId = conversationId;
      this.fetchMessages(conversationId);
      this.connect();
    },

    connect() {
      if (!this.activeConversationId || this.websocket) return;
      const authStore = useAuthStore();
      if (!authStore.token) return;

      const wsURL = `ws://localhost:8000/ws/${this.activeConversationId}?token=${authStore.token}`;
      this.websocket = new WebSocket(wsURL);

      this.websocket.onmessage = (event) => {
        const message = JSON.parse(event.data);
        if (this.messages[this.activeConversationId]) {
            // Find if this message is an echo of one we sent and are waiting for persistence on
            const optimisticMessageIndex = this.messages[this.activeConversationId].findIndex(m => m.id === 'optimistic-message');
            if (optimisticMessageIndex > -1 && message.sender_type === 'user') {
                // The backend confirmed our message, replace the optimistic one
                this.messages[this.activeConversationId][optimisticMessageIndex] = message;
            } else {
                // It's a new message (e.g., from the AI)
                this.messages[this.activeConversationId].push(message);
            }
        }
      };
    },

    disconnect() {
      if (this.websocket) {
        this.websocket.close();
        this.websocket = null;
      }
    },

    sendMessage(content) {
      if (!this.websocket || this.websocket.readyState !== WebSocket.OPEN) return;

      const authStore = useAuthStore();
      // Optimistically add the user's message to the UI for instant feedback
      const optimisticMessage = {
        id: 'optimistic-message', // A temporary ID
        conversation_id: this.activeConversationId,
        content: content,
        sender_id: authStore.user?.email || 'me',
        sender_type: 'user',
        created_at: new Date().toISOString(),
      };
      if (this.messages[this.activeConversationId]) {
        this.messages[this.activeConversationId].push(optimisticMessage);
      }

      // Send the message over the websocket
      this.websocket.send(JSON.stringify({ content }));
    },
  },

  getters: {
    activeConversationMessages: (state) => {
      return state.messages[state.activeConversationId] || [];
    },
  },
});
