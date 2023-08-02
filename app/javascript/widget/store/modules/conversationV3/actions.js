import ConversationAPI from 'widget/api/conversationPublic';
import MessageAPI from 'widget/api/messagePublic';
import { getNonDeletedMessages } from './helpers';

export const actions = {
  fetchAllConversations: async ({ commit }) => {
    try {
      commit('setUIFlag', { isFetching: true });
      const { data } = await ConversationAPI.get();

      const conv = {
        ...data,
        messages: [
          {
            id: 25170501,
            content: 'Ingonre',
            message_type: 0,
            content_type: 'text',
            content_attributes: {},
            created_at: 1690799086,
            conversation_id: 26453,
            sender: {
              additional_attributes: {
                city: 'Bengaluru',
                country: 'India',
                source_id:
                  'email:01000184cceb6518-6cc32623-0a31-4883-8e9b-5ffbc37ca4e8-000000@email.amazonses.com',
                country_code: 'IN',
                created_at_ip: '122.179.4.26',
              },
              custom_attributes: {},
              email: 'finance@chatwoot.com',
              id: 32709310,
              identifier: null,
              name: 'Chatwoot Inc',
              phone_number: null,
              thumbnail: '',
              type: 'contact',
            },
          },
          {
            id: 25170502,
            content:
              'Thanks for reaching out to us. We are unavailable at the moment. We will respond back to you as soon as possible.',
            message_type: 3,
            content_type: 'text',
            content_attributes: {},
            created_at: 1690799086,
            conversation_id: 26453,
          },
        ],
      };
      const fakeData = [conv, conv];
      fakeData.forEach(conversation => {
        const { id: conversationId, messages } = conversation;
        const { contact_last_seen_at: userLastSeenAt, status } = conversation;
        const lastMessage = messages[messages.length - 1];
        commit('addConversationEntry', conversation);
        commit('addConversationId', conversationId);
        commit('setConversationUIFlag', {
          uiFlags: {},
          conversationId,
        });
        commit('setConversationMeta', {
          meta: { userLastSeenAt, status },
          conversationId,
        });
        commit(
          'messageV3/addMessagesEntry',
          { conversationId, messages: [lastMessage] },
          { root: true }
        );
        commit('addMessageIdsToConversation', {
          conversationId,
          messages: [lastMessage],
        });
      });
    } catch (error) {
      throw new Error(error);
    } finally {
      commit('setUIFlag', { isFetching: false });
    }
  },

  fetchOldMessagesIn: async ({ commit }, params) => {
    const { conversationId, beforeId } = params;

    try {
      commit('setConversationUIFlag', {
        uiFlags: { isFetching: true },
        conversationId,
      });
      const { data } = await MessageAPI.get(conversationId, beforeId);
      const messages = getNonDeletedMessages({ messages: data });

      commit(
        'messageV3/addMessagesEntry',
        { conversationId, messages },
        { root: true }
      );
      commit('prependMessageIdsToConversation', {
        conversationId,
        messages,
      });

      if (data.length < 20) {
        commit('setConversationUIFlag', {
          conversationId,
          uiFlags: { allFetched: true },
        });
      }
    } catch (error) {
      throw new Error(error);
    } finally {
      commit('setConversationUIFlag', {
        conversationId,
        uiFlags: { isFetching: false },
      });
    }
  },

  addConversation: async ({ commit }, data) => {
    const { id: conversationId, messages } = data;
    const { contact_last_seen_at: userLastSeenAt } = data;

    commit('addConversationEntry', data);
    commit('addConversationId', conversationId);
    commit('setConversationUIFlag', {
      uiFlags: { isAgentTyping: false },
      conversationId,
    });
    commit('setConversationMeta', {
      meta: { userLastSeenAt },
      conversationId,
    });
    commit(
      'messageV3/addMessagesEntry',
      { conversationId, messages },
      { root: true }
    );
    commit('addMessageIdsToConversation', {
      conversationId,
      messages,
    });
    return conversationId;
  },

  createConversationWithMessage: async ({ commit }, params) => {
    const { content, contact } = params;
    commit('setUIFlag', { isCreating: true });
    try {
      const { data } = await ConversationAPI.createWithMessage(
        content,
        contact
      );
      const { id: conversationId, messages } = data;
      const { contact_last_seen_at: userLastSeenAt } = data;

      commit('addConversationEntry', data);
      commit('addConversationId', conversationId);
      commit('setConversationUIFlag', {
        uiFlags: { isAgentTyping: false },
        conversationId,
      });
      commit('setConversationMeta', {
        meta: { userLastSeenAt },
        conversationId,
      });
      commit(
        'messageV3/addMessagesEntry',
        { conversationId, messages },
        { root: true }
      );
      commit('addMessageIdsToConversation', {
        conversationId,
        messages,
      });
      return conversationId;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit('setUIFlag', { isCreating: false });
    }
  },

  toggleAgentTypingIn({ commit }, data) {
    const { status, conversationId } = data;
    const isAgentTyping = status === 'on';

    commit('setConversationUIFlag', {
      uiFlags: { isAgentTyping },
      conversationId,
    });
  },

  toggleUserTypingIn: async ({ commit }, data) => {
    try {
      await ConversationAPI.toggleTypingIn(data);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit('setConversationUIFlag', {
        uiFlags: { isUserTyping: false },
        conversationId: undefined,
      });
    }
  },

  sendEmailTranscriptIn: async (_, data) => {
    try {
      await ConversationAPI.sendEmailTranscriptIn(data);
    } catch (error) {
      // IgnoreError
    }
  },

  setUserLastSeenIn: async ({ commit, getters }, params) => {
    const { conversationId } = params;
    if (!getters.allMessagesCountIn(conversationId)) {
      return;
    }

    const userLastSeenAt = Date.now() / 1000;
    try {
      commit('setConversationMeta', {
        meta: { userLastSeenAt },
        conversationId,
      });
      await ConversationAPI.setUserLastSeenIn({
        lastSeen: userLastSeenAt,
        conversationId,
      });
    } catch (error) {
      // IgnoreError
    }
  },

  setConversationStatusIn: async ({ commit }, params) => {
    const { conversationId, status } = params;

    commit('setConversationMeta', {
      meta: { status },
      conversationId,
    });
  },
};
