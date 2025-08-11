import { defineStore } from 'pinia';
import { useAuthStore } from './auth';
// We will need to create these API client methods
// import conversationsAPI from '../api/conversations';

export const useConversationStore = defineStore('conversations', {
  state: () => ({
    conversations: [],
    activeConversationId: null,
    messages: {}, // Dictionary to hold messages for each conversation
    websocket: null,
    isLoading: false,
    error: null,
  }),

  actions: {
    // --- REST API Actions ---
    async fetchConversations() {
      this.isLoading = true;
      this.error = null;
      try {
        // const response = await conversationsAPI.list();
        // this.conversations = response.data;

        // Placeholder data for now
        this.conversations = [
          { id: 'conv_1', account_id: 'acc_123', status: 'open', last_activity_at: new Date().toISOString(), participants: [{ name: 'Customer 1' }] },
          { id: 'conv_2', account_id: 'acc_123', status: 'open', last_activity_at: new Date().toISOString(), participants: [{ name: 'User 2' }] },
        ];
      } catch (error) {
        this.error = 'Failed to fetch conversations.';
        console.error(error);
      } finally {
        this.isLoading = false;
      }
    },

    async fetchMessages(conversationId) {
      if (this.messages[conversationId]) return; // Already fetched

      this.isLoading = true;
      try {
        // const response = await conversationsAPI.getMessages(conversationId);
        // this.messages[conversationId] = response.data;

        // Placeholder data
         this.messages[conversationId] = [
            { id: 'msg_1', conversation_id: conversationId, content: 'Hello there!', sender_id: 'user1', sender_type: 'user', created_at: new Date().toISOString() },
            { id: 'msg_2', conversation_id: conversationId, content: 'Hi! How can I help?', sender_id: 'contact1', sender_type: 'contact', created_at: new Date().toISOString() },
         ];
      } catch (error) {
        this.error = 'Failed to fetch messages.';
        console.error(error);
      } finally {
        this.isLoading = false;
      }
    },

    // --- WebSocket Actions ---
    setActiveConversation(conversationId) {
      if (this.activeConversationId === conversationId) return;

      this.disconnect(); // Disconnect from the previous conversation
      this.activeConversationId = conversationId;
      this.connect();
      this.fetchMessages(conversationId);
    },

    connect() {
      if (!this.activeConversationId || this.websocket) return;

      const authStore = useAuthStore();
      if (!authStore.token) {
        this.error = 'Authentication token not found.';
        return;
      }

      // The WebSocket URL needs the token as a query parameter
      const wsURL = `ws://localhost:8000/ws/${this.activeConversationId}?token=${authStore.token}`;

      this.websocket = new WebSocket(wsURL);

      this.websocket.onopen = () => {
        console.log(`WebSocket connected for conversation ${this.activeConversationId}`);
      };

      this.websocket.onmessage = (event) => {
        const message = JSON.parse(event.data);
        // Add the new message to the state
        if (this.messages[this.activeConversationId]) {
            this.messages[this.activeConversationId].push(message);
        }
      };

      this.websocket.onerror = (error) => {
        console.error('WebSocket error:', error);
        this.error = 'WebSocket connection failed.';
      };

      this.websocket.onclose = () => {
        console.log('WebSocket disconnected.');
        this.websocket = null;
      };
    },

    disconnect() {
      if (this.websocket) {
        this.websocket.close();
      }
    },

    sendMessage(content) {
      if (!this.websocket || this.websocket.readyState !== WebSocket.OPEN) {
        this.error = 'WebSocket is not connected.';
        return;
      }
      this.websocket.send(JSON.stringify({ content }));
    },
  },

  getters: {
    activeConversationMessages: (state) => {
      return state.messages[state.activeConversationId] || [];
    },
  },
});
