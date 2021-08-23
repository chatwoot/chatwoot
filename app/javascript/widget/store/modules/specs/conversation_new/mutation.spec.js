import { mutations } from '../../conversation_new/mutations';

describe('#mutations', () => {
  describe('#setUIFlag', () => {
    it('it sets UI flags correctly', () => {
      const state = {
        uiFlags: { allConversationsLoaded: false, isFetching: false },
      };
      mutations.setUIFlag(state, { isFetching: true });
      expect(state.uiFlags).toEqual({
        allConversationsLoaded: false,
        isFetching: true,
      });
    });
  });

  describe('#addConversationEntry', () => {
    it('it creates a conversation in store', () => {
      const state = {
        conversations: {
          byId: {},
          allIds: [],
        },
      };
      mutations.addConversationEntry(state, { id: 420, messages: [] });
      expect(state.conversations).toEqual({
        byId: {
          420: { id: 420, messages: [] },
        },
        allIds: [],
      });
    });
    it('it creates conversation with empty messages in store', () => {
      const state = {
        conversations: {
          byId: { 120: { id: 120 } },
          allIds: [120],
        },
      };
      mutations.addConversationEntry(state, { id: 420, messages: [] });
      expect(state.conversations.allIds).toEqual([120]);
    });
    it('it does not create a conversation if conversation id is missing', () => {
      const state = {
        conversations: {
          byId: { 120: { id: 120 } },
          allIds: [120],
        },
      };
      mutations.addConversationEntry(state, {});
      expect(state.conversations.allIds).toEqual([120]);
    });
  });

  describe('#addConversationId', () => {
    it('it adds conversation id in store', () => {
      const state = {
        conversations: {
          byId: {},
          allIds: [],
        },
      };
      mutations.addConversationId(state, 420);
      expect(state.conversations).toEqual({
        byId: {},
        allIds: [420],
      });
    });
  });

  describe('#updateConversationEntry', () => {
    it('it updates an existing conversation in store', () => {
      const state = {
        conversations: {
          byId: { 120: { id: 120, channel: 'email' } },
          allIds: [120],
        },
      };
      mutations.updateConversationEntry(state, {
        id: 120,
        channel: 'facebook',
      });
      expect(state.conversations).toEqual({
        byId: {
          120: { id: 120, channel: 'facebook' },
        },
        allIds: [120],
      });
    });
    it('it does not clears messages in conversation', () => {
      const state = {
        conversations: {
          byId: { 120: { id: 120, channel: 'email', messages: [10] } },
          allIds: [120],
        },
        messages: {
          byId: {
            10: {
              id: 10,
              content: 'hi',
            },
          },
          allIds: [10],
        },
      };
      mutations.updateConversationEntry(state, {
        id: 120,
        channel: 'facebook',
      });
      expect(state.messages).toEqual({
        byId: {
          10: {
            id: 10,
            content: 'hi',
          },
        },
        allIds: [10],
      });
    });
    it('it does not create a new conversation if conversation id is missing', () => {
      const state = {
        conversations: {
          byId: { 120: { id: 120 } },
          allIds: [120],
        },
      };
      mutations.updateConversationEntry(state, {});
      expect(state).toEqual({
        conversations: {
          byId: { 120: { id: 120 } },
          allIds: [120],
        },
      });
    });
  });

  describe('#removeConversationEntry', () => {
    it('it removes conversation from store', () => {
      const state = {
        conversations: {
          byId: { 120: { id: 120 } },
          allIds: [120],
        },
      };
      mutations.removeConversationEntry(state, 120);
      expect(state).toEqual({
        conversations: {
          byId: {},
          allIds: [120],
        },
      });
    });
  });

  describe('#removeConversationId', () => {
    it('it removes conversation id from store', () => {
      const state = {
        conversations: {
          byId: { 120: { id: 120 } },
          allIds: [120],
        },
      };
      mutations.removeConversationId(state, 120);
      expect(state).toEqual({
        conversations: {
          byId: { 120: { id: 120 } },
          allIds: [],
        },
      });
    });
  });

  describe('#setConversationUIFlag', () => {
    it('it sets UI flag for conversation correctly', () => {
      const state = {
        conversations: {
          byId: {},
          allIds: [],
          uiFlags: {
            byId: {
              1: {
                allMessagesLoaded: false,
                isAgentTyping: false,
                isFetching: false,
              },
            },
          },
        },
      };
      mutations.setConversationUIFlag(state, {
        conversationId: 1,
        uiFlags: { isFetching: true },
      });
      expect(state.conversations.uiFlags.byId[1]).toEqual({
        allMessagesLoaded: false,
        isAgentTyping: false,
        isFetching: true,
      });
    });
  });

  describe('#addMessageIds', () => {
    it('it adds a list of message ids to existing conversation entry', () => {
      const state = {
        conversations: {
          byId: { 120: { id: 120, messages: [] } },
          allIds: [120],
        },
        messages: { byId: {}, allIds: [] },
      };
      const messages = [
        { id: 2, content: 'hi' },
        { id: 3, content: 'hello' },
      ];
      mutations.addMessageIds(state, {
        conversationId: 120,
        messages,
      });
      expect(state.conversations.byId[120].messages).toEqual([2, 3]);
    });
    it('it does not clear existing messages in a conversation', () => {});
    it('new message id is added as last in allIds message in a conversation', () => {});
    it('it does not add messages if conversation is not present in store', () => {});
  });

  describe('#addMessageIds', () => {
    it('it adds a list of message ids to existing conversation entry', () => {
      const state = {
        conversations: {
          byId: { 120: { id: 120, messages: [] } },
          allIds: [120],
        },
        messages: { byId: {}, allIds: [] },
      };
      const messages = [
        { id: 2, content: 'hi' },
        { id: 3, content: 'hello' },
      ];
      mutations.addMessageIds(state, {
        conversationId: 120,
        messages,
      });
      expect(state.conversations.byId[120].messages).toEqual([2, 3]);
    });
    it('it does not clear existing messages in a conversation', () => {
      const state = {
        conversations: {
          byId: { 120: { id: 120, messages: [2] } },
          allIds: [120],
        },
        messages: { byId: { 2: { id: 2, content: 'hi' } }, allIds: [2] },
      };
      const messages = [{ id: 3, content: 'hello' }];
      mutations.addMessageIds(state, {
        conversationId: 120,
        messages,
      });
      expect(state.conversations.byId[120].messages).toEqual([2, 3]);
    });
    it('it does not add messages if conversation is not present in store', () => {
      const state = {
        conversations: {
          byId: { 12: { id: 12, messages: [2] } },
          allIds: [12],
        },
        messages: { byId: { 2: { id: 2, content: 'hi' } }, allIds: [2] },
      };
      const messages = [{ id: 3, content: 'hello' }];
      mutations.addMessageIds(state, {
        conversationId: 120,
        messages,
      });
      expect(state.conversations.byId[120]).toEqual(undefined);
    });
  });

  describe('#updateMessageEntry', () => {
    it('it updates message in conversation correctly', () => {
      const state = {
        conversations: {
          byId: { 12: { id: 12, messages: [2] } },
          allIds: [12],
        },
        messages: { byId: { 2: { id: 2, content: 'hi' } }, allIds: [2] },
      };
      const message = { id: 2, content: 'hello' };
      mutations.updateMessageEntry(state, message);
      expect(state.messages.byId[2].content).toEqual('hello');
    });
    it('it does not create message if message does not exist in conversation', () => {
      const state = {
        conversations: {
          byId: { 12: { id: 12, messages: [2] } },
          allIds: [12],
        },
        messages: { byId: { 2: { id: 2, content: 'hi' } }, allIds: [2] },
      };
      const message = { id: 23, content: 'hello' };
      mutations.updateMessageEntry(state, message);
      expect(state.messages.byId[23]).toEqual(undefined);
    });
  });
  describe('#removeMessageEntry', () => {
    it('it deletes message in conversation correctly', () => {
      const state = {
        conversations: {
          byId: { 12: { id: 12, messages: [2] } },
          allIds: [12],
        },
        messages: { byId: { 2: { id: 2, content: 'hi' } }, allIds: [2] },
      };
      const messageId = 2;
      mutations.removeMessageEntry(state, messageId);
      expect(state.messages.byId[2]).toEqual(undefined);
    });
  });

  describe('#removeMessageId', () => {
    it('it deletes message id in conversation correctly', () => {
      const state = {
        conversations: {
          byId: { 12: { id: 12, messages: [2] } },
          allIds: [12],
        },
        messages: { byId: { 2: { id: 2, content: 'hi' } }, allIds: [2] },
      };
      const messageId = 2;
      mutations.removeMessageId(state, messageId);
      expect(state.messages.allIds).toEqual([]);
    });
  });

  describe('#removeMessageIdFromConversation', () => {
    it('it deletes message id in conversation correctly', () => {
      const state = {
        conversations: {
          byId: { 12: { id: 12, messages: [2] } },
          allIds: [12],
        },
        messages: { byId: { 2: { id: 2, content: 'hi' } }, allIds: [2] },
      };
      const messageId = 2;
      const conversationId = 12;
      mutations.removeMessageIdFromConversation(state, {
        conversationId,
        messageId,
      });
      expect(state.conversations.byId[12].messages).toEqual([]);
    });
  });

  describe('#setMessageUIFlag', () => {
    it('it sets UI flag for conversation correctly', () => {
      const state = {
        messages: {
          byId: {},
          allIds: [],
          uiFlags: {
            byId: {
              1: {
                isCreating: false,
                isPending: false,
                isDeleting: false,
              },
            },
          },
        },
      };
      mutations.setMessageUIFlag(state, {
        messageId: 1,
        uiFlags: { isCreating: true },
      });
      expect(state.messages.uiFlags.byId[1]).toEqual({
        isCreating: true,
        isPending: false,
        isDeleting: false,
      });
    });
  });
});
