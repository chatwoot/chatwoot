import { mutations } from '../../conversationV3/mutations';
import Vue from 'vue';

describe('Vuex mutations', () => {
  let state;

  beforeEach(() => {
    state = {
      conversations: {
        byId: {},
        allIds: [],
        uiFlags: {
          byId: {},
        },
        meta: {
          byId: {},
        },
      },
      uiFlags: {
        allFetched: false,
        isFetching: false,
        isCreating: true,
      },
    };

    Vue.set = jest.fn();
  });

  it('setUIFlag updates UI flags', () => {
    const uiFlags = { allFetched: true, isFetching: true };
    mutations.setUIFlag(state, uiFlags);
    expect(state.uiFlags).toEqual({ ...state.uiFlags, ...uiFlags });
  });

  it('addConversationEntry adds a new conversation', () => {
    Vue.set = jest.fn();
    const conversation = { id: 1, messages: [] };
    mutations.addConversationEntry(state, conversation);
    expect(Vue.set).toHaveBeenCalledWith(
      state.conversations.byId,
      1,
      conversation
    );
  });

  it('addConversationId adds a new conversation ID', () => {
    const conversationId = 1;
    mutations.addConversationId(state, conversationId);
    expect(state.conversations.allIds).toContain(conversationId);
  });

  it('updateConversationEntry updates an existing conversation', () => {
    const conversation = { id: 1, messages: [] };
    state.conversations.allIds.push(1);
    state.conversations.byId[1] = conversation;
    const content_attributes = { attr: 'value' };
    mutations.updateConversationEntry(state, conversation, content_attributes);
    expect(Vue.set).toHaveBeenCalledWith(state.conversations.byId, 1, {
      ...conversation,
      content_attributes,
    });
  });

  it('removeConversationEntry removes a conversation', () => {
    const conversationId = 1;
    mutations.removeConversationEntry(state, conversationId);
    expect(Vue.set).toHaveBeenCalledWith(
      state.conversations.byId,
      1,
      undefined
    );
  });

  it('removeConversationId removes a conversation ID', () => {
    const conversationId = 1;
    state.conversations.allIds = [1, 2, 3];
    mutations.removeConversationId(state, conversationId);
    expect(state.conversations.allIds).toEqual([2, 3]);
  });

  it('setConversationUIFlag sets UI flags for a conversation', () => {
    const conversationId = 1;
    const uiFlags = { allFetched: true };
    mutations.setConversationUIFlag(state, { conversationId, uiFlags });
    expect(Vue.set).toHaveBeenCalledWith(
      state.conversations.uiFlags.byId,
      conversationId,
      { allFetched: false, isAgentTyping: false, isFetching: false, ...uiFlags }
    );
  });

  it('setConversationMeta sets meta for a conversation', () => {
    const conversationId = 1;
    const meta = { status: 'closed' };
    mutations.setConversationMeta(state, { conversationId, meta });
    expect(Vue.set).toHaveBeenCalledWith(
      state.conversations.meta.byId,
      conversationId,
      { userLastSeenAt: undefined, status: 'open', ...meta }
    );
  });

  it('prependMessageIdsToConversation prepends message IDs to conversation', () => {
    const conversationId = 1;
    const messages = [{ id: 4 }, { id: 5 }];
    state.conversations.byId[1] = { messages: [1, 2, 3] };
    mutations.prependMessageIdsToConversation(state, {
      conversationId,
      messages,
    });
    expect(Vue.set).toHaveBeenCalledWith(
      state.conversations.byId[1],
      'messages',
      [4, 5, 1, 2, 3]
    );
  });

  it('appendMessageIdsToConversation appends message IDs to conversation', () => {
    const conversationId = 1;
    const messages = [{ id: 4 }, { id: 5 }];
    state.conversations.byId[1] = { messages: [1, 2, 3] };
    mutations.appendMessageIdsToConversation(state, {
      conversationId,
      messages,
    });
    expect(Vue.set).toHaveBeenCalledWith(
      state.conversations.byId[1],
      'messages',
      [1, 2, 3, 4, 5]
    );
  });

  it('addMessageIdsToConversation sets message IDs to conversation', () => {
    const conversationId = 1;
    const messages = [{ id: 4 }, { id: 5 }];
    state.conversations.byId[1] = { messages: [1, 2, 3] };
    mutations.addMessageIdsToConversation(state, { conversationId, messages });
    expect(Vue.set).toHaveBeenCalledWith(
      state.conversations.byId[1],
      'messages',
      [4, 5]
    );
  });

  it('removeMessageIdFromConversation removes a message ID from conversation', () => {
    const conversationId = 1;
    const messageId = 2;
    state.conversations.byId[1] = { messages: [1, 2, 3] };
    mutations.removeMessageIdFromConversation(state, {
      conversationId,
      messageId,
    });
    expect(state.conversations.byId[1].messages).toEqual([1, 3]);
  });

  it('setMetaUserLastSeenIn sets user last seen in a conversation', () => {
    const conversationId = 1;
    const lastSeen = new Date();
    state.conversations.byId[1] = { meta: {} };
    mutations.setMetaUserLastSeenIn(state, { conversationId, lastSeen });
    expect(Vue.set).toHaveBeenCalledWith(
      state.conversations.byId[1].meta,
      'userLastSeenAt',
      lastSeen
    );
  });

  it('addConversationEntry does nothing if id is missing', () => {
    const conversation = { messages: [] };
    mutations.addConversationEntry(state, conversation);
    expect(state.conversations.byId).toEqual({});
  });

  it('updateConversationEntry does nothing if id is missing', () => {
    const conversation = { messages: [] };
    mutations.updateConversationEntry(state, conversation);
    expect(state.conversations.byId).toEqual({});
  });

  it('updateConversationEntry does nothing if id is not in allIds', () => {
    const conversation = { id: 1, messages: [] };
    mutations.updateConversationEntry(state, conversation);
    expect(state.conversations.byId).toEqual({});
  });

  it('removeConversationEntry does nothing if id is missing', () => {
    mutations.removeConversationEntry(state);
    expect(state.conversations.byId).toEqual({});
  });

  it('removeConversationId removes a conversation ID', () => {
    const conversationId = 1;
    state.conversations.allIds = [1, 2, 3];
    mutations.removeConversationId(state, conversationId);
    expect(state.conversations.allIds).toEqual([2, 3]);
  });

  it('setConversationUIFlag sets UI flags for a conversation', () => {
    const conversationId = 1;
    const uiFlags = { isFetching: true };
    mutations.setConversationUIFlag(state, { conversationId, uiFlags });

    expect(Vue.set).toHaveBeenCalledWith(
      state.conversations.uiFlags.byId,
      conversationId,
      {
        allFetched: false,
        isAgentTyping: false,
        isFetching: true,
      }
    );
  });

  it('setConversationMeta sets metadata for a conversation', () => {
    const conversationId = 1;
    const meta = { status: 'closed' };
    mutations.setConversationMeta(state, { conversationId, meta });

    expect(Vue.set).toHaveBeenCalledWith(
      state.conversations.meta.byId,
      conversationId,
      {
        userLastSeenAt: undefined,
        status: 'closed',
      }
    );
  });

  // Edge cases

  it('removeConversationId does nothing if id is not present', () => {
    const conversationId = 4;
    state.conversations.allIds = [1, 2, 3];
    mutations.removeConversationId(state, conversationId);
    expect(state.conversations.allIds).toEqual([1, 2, 3]);
  });

  it('prependMessageIdsToConversation does nothing if conversation is not found', () => {
    const conversationId = 4;
    const messages = [{ id: 4 }, { id: 5 }];
    mutations.prependMessageIdsToConversation(state, {
      conversationId,
      messages,
    });
    expect(state.conversations.byId[4]).toBeUndefined();
  });

  it('appendMessageIdsToConversation does nothing if conversation is not found', () => {
    const conversationId = 4;
    const messages = [{ id: 4 }, { id: 5 }];
    mutations.appendMessageIdsToConversation(state, {
      conversationId,
      messages,
    });
    expect(state.conversations.byId[4]).toBeUndefined();
  });

  it('removeMessageIdFromConversation removes a message ID from conversation', () => {
    const conversationId = 1;
    const messageId = 2;
    state.conversations.byId[1] = { messages: [1, 2, 3] };
    mutations.removeMessageIdFromConversation(state, {
      conversationId,
      messageId,
    });
    expect(state.conversations.byId[1].messages).toEqual([1, 3]);
  });

  it('removeMessageIdFromConversation does nothing if conversation is not found', () => {
    const conversationId = 4;
    const messageId = 2;
    mutations.removeMessageIdFromConversation(state, {
      conversationId,
      messageId,
    });
    expect(state.conversations.byId[4]).toBeUndefined();
  });

  it('removeMessageIdFromConversation does nothing if messageId is not present', () => {
    const conversationId = 1;
    const messageId = 4;
    state.conversations.byId[1] = { messages: [1, 2, 3] };
    mutations.removeMessageIdFromConversation(state, {
      conversationId,
      messageId,
    });
    expect(state.conversations.byId[1].messages).toEqual([1, 2, 3]);
  });

  it('setMetaUserLastSeenIn sets user last seen in metadata for a conversation', () => {
    const conversationId = 1;
    const lastSeen = new Date();
    state.conversations.byId[1] = { meta: {} };
    mutations.setMetaUserLastSeenIn(state, { conversationId, lastSeen });

    expect(Vue.set).toHaveBeenCalledWith(
      state.conversations.byId[1].meta,
      'userLastSeenAt',
      lastSeen
    );
  });

  it('setMetaUserLastSeenIn does nothing if conversation is not found', () => {
    const conversationId = 4;
    const lastSeen = new Date();
    mutations.setMetaUserLastSeenIn(state, { conversationId, lastSeen });
    expect(state.conversations.byId[4]).toBeUndefined();
  });
});
