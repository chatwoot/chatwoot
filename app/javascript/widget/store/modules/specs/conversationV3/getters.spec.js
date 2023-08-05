import { getters } from '../../conversationV3/getters';

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

  // Mock rootGetters
  const rootGetters = {
    'messageV3/messageById': id => ({
      id,
      created_at: id * 1000,
      message_type: 1,
    }),
  };

  it('uiFlagsIn returns correct UI flags', () => {
    const uiFlags = getters.uiFlagsIn(state)(1);
    expect(uiFlags).toEqual({
      allFetched: true,
      isAgentTyping: false,
      isFetching: false,
    });
  });

  it('metaIn returns correct meta', () => {
    const meta = getters.metaIn(state)(1);
    expect(meta).toEqual({ userLastSeenAt: 1000, status: 'open' });
  });

  it('isAllMessagesFetchedIn returns correct value', () => {
    const isAllMessagesFetched = getters.isAllMessagesFetchedIn(
      state,
      getters
    )(1);
    expect(isAllMessagesFetched).toBe(true);
  });

  it('isCreating returns correct value', () => {
    expect(getters.isCreating(state)).toBe(true);
  });

  it('isAgentTypingIn returns correct value', () => {
    const isAgentTyping = getters.isAgentTypingIn(state, getters)(2);
    expect(isAgentTyping).toBe(true);
  });

  it('isFetchingConversationsList returns correct value', () => {
    expect(getters.isFetchingConversationsList(state)).toBe(false);
  });

  it('allConversations returns all conversations with their respective messages', () => {
    const allConversations = getters.allConversations(
      state,
      null,
      null,
      rootGetters
    );
    expect(allConversations.length).toBe(2);
    expect(allConversations[0].messages.length).toBe(3);
    expect(allConversations[1].messages.length).toBe(2);
  });

  it('allActiveConversations returns only active conversations', () => {
    const activeConversations = getters.allActiveConversations(
      state,
      getters,
      null,
      rootGetters
    );
    expect(activeConversations.length).toBe(1);
    expect(activeConversations[0].id).toBe(1);
  });

  it('totalConversationsLength returns correct total number of conversations', () => {
    expect(getters.totalConversationsLength(state)).toBe(2);
  });

  it('firstMessageIn returns the first message of the conversation', () => {
    const firstMessage = getters.firstMessageIn(
      state,
      null,
      null,
      rootGetters
    )(1);
    expect(firstMessage).toEqual({
      id: 1,
      created_at: 1000,
      message_type: 1,
    });
  });

  // Other tests go here...

  it('getConversationById returns correct conversation with messages', () => {
    const conversation = getters.getConversationById(
      state,
      null,
      null,
      rootGetters
    )(1);
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
    const unreadMessages = getters.unreadTextMessagesIn(
      state,
      getters,
      undefined,
      rootGetters
    )(1);
    expect(unreadMessages.length).toBe(2);
    expect(unreadMessages[0].id).toBe(2);
  });

  it('unreadTextMessagesCountIn returns the count of unread messages in a conversation', () => {
    const unreadCount = getters.unreadTextMessagesCountIn(state, getters)(2);
    expect(unreadCount).toBe(1);
  });

  it('lastActiveConversationId returns the id of the last active conversation', () => {
    const lastActiveId = getters.lastActiveConversationId(
      state,
      getters,
      undefined,
      rootGetters
    );
    expect(lastActiveId).toBe(1);
  });
});
