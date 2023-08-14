import { createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import { getters } from '../../conversationV3/getters';
import messageV3 from '../../messageV3';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Vuex getters', () => {
  // Mock state
  const state = {
    conversations: {
      byId: {
        1: {
          id: 1,
          messages: [1, 2, 3],
          status: 'open',
        },
        2: {
          id: 2,
          messages: [4, 5],
          status: 'closed',
        },
      },
      allIds: [1, 2],
      uiFlags: {
        byId: {
          1: { allFetched: true, isAgentTyping: false, isFetching: false },
          2: { allFetched: false, isAgentTyping: true, isFetching: true },
          4: { allFetched: false, isAgentTyping: true, isFetching: true },
        },
      },
      meta: {
        byId: {
          1: { userLastSeenAt: 1000, status: 'open' },
          2: { userLastSeenAt: 2000, status: 'closed' },
          3: { userLastSeenAt: 5000, status: 'closed' },
          4: { userLastSeenAt: 5000, status: 'closed' },
          5: { userLastSeenAt: 5000, status: 'closed' },
        },
      },
    },
    uiFlags: {
      allFetched: false,
      isFetching: false,
      isCreating: true,
    },
  };

  const store = new Vuex.Store({
    state,
    getters,
    modules: {
      messageV3: {
        ...messageV3,
        state: {
          messages: {
            byId: {
              1: { id: 1, created_at: 1000, message_type: 1 },
              2: { id: 2, created_at: 2000, message_type: 1 },
              3: { id: 3, created_at: 3000, message_type: 1 },
            },
            allIds: [],
            uiFlags: {
              byId: {
                // 1: { isCreating: false, isPending: false, isDeleting: false, isUpdating: false },
              },
            },
          },
        },
      },
    },
  });

  it('uiFlagsIn returns correct UI flags', () => {
    const uiFlags = store.getters.uiFlagsIn(1);
    expect(uiFlags).toEqual({
      allFetched: true,
      isAgentTyping: false,
      isFetching: false,
    });
  });

  it('metaIn returns correct meta', () => {
    const meta = store.getters.metaIn(1);
    expect(meta).toEqual({ userLastSeenAt: 1000, status: 'open' });
  });

  it('isAllMessagesFetchedIn returns correct value', () => {
    const isAllMessagesFetched = store.getters.isAllMessagesFetchedIn(1);
    expect(isAllMessagesFetched).toBe(true);
  });

  it('isCreating returns correct value', () => {
    expect(store.getters.isCreating).toBe(true);
  });

  it('isAgentTypingIn returns correct value', () => {
    const isAgentTyping = store.getters.isAgentTypingIn(2);
    expect(isAgentTyping).toBe(true);
  });

  it('isFetchingConversationsList returns correct value', () => {
    expect(store.getters.isFetchingConversationsList).toBe(false);
  });

  it('allConversations returns all conversations with their respective messages', () => {
    const allConversations = store.getters.allConversations;
    expect(allConversations.length).toBe(2);
    expect(allConversations[0].messages.length).toBe(3);
    expect(allConversations[1].messages.length).toBe(2);
  });

  it('allActiveConversations returns only active conversations', () => {
    const activeConversations = store.getters.allActiveConversations;
    expect(activeConversations.length).toBe(1);
    expect(activeConversations[0].id).toBe(1);
  });

  it('totalConversationsLength returns correct total number of conversations', () => {
    expect(store.getters.totalConversationsLength).toBe(2);
  });

  it('firstMessageIn returns the first message of the conversation', () => {
    const firstMessage = store.getters.firstMessageIn(1);
    expect(firstMessage).toEqual({
      id: 1,
      created_at: 1000,
      message_type: 1,
    });
  });

  // Other tests go here...

  it('getConversationById returns correct conversation with messages', () => {
    const conversation = store.getters.getConversationById(1);
    expect(conversation).toEqual({
      id: 1,
      messages: [
        { id: 1, created_at: 1000, message_type: 1 },
        { id: 2, created_at: 2000, message_type: 1 },
        { id: 3, created_at: 3000, message_type: 1 },
      ],
      status: 'open',
    });
  });

  it('unreadTextMessagesIn returns unread messages for a conversation', () => {
    const unreadMessages = store.getters.unreadTextMessagesIn(1);
    expect(unreadMessages.length).toBe(2);
    expect(unreadMessages[0].id).toBe(2);
  });

  it('unreadTextMessagesCountIn returns the count of unread messages in a conversation', () => {
    const unreadCount = store.getters.unreadTextMessagesCountIn(1);
    expect(unreadCount).toBe(2);
  });

  it('lastActiveConversationId returns the id of the last active conversation', () => {
    const lastActiveId = store.getters.lastActiveConversationId;
    expect(lastActiveId).toBe(1);
  });
});
