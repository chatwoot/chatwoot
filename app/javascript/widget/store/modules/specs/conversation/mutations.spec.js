import { mutations } from '../../conversation';

describe('#mutations', () => {
  describe('#pushMessageToConversation', () => {
    it('add message to conversation if outgoing', () => {
      const state = { conversations: {} };
      mutations.pushMessageToConversation(state, {
        content: 'hello',
        id: 1,
        message_type: 1,
        status: 'sent',
      });
      expect(state.conversations).toEqual({
        1: { content: 'hello', id: 1, message_type: 1, status: 'sent' },
      });
    });

    it('add message to conversation if message in undelivered', () => {
      const state = { conversations: {} };
      mutations.pushMessageToConversation(state, {
        content: 'hello',
        id: 1,
        message_type: 0,
        status: 'in_progress',
      });
      expect(state.conversations).toEqual({
        1: { content: 'hello', id: 1, message_type: 0, status: 'in_progress' },
      });
    });

    it('replaces temporary message in conversation with actual message', () => {
      const state = {
        conversations: {
          rand_id_123: {
            content: 'hello',
            id: 'rand_id_123',
            message_type: 0,
            status: 'in_progress',
          },
        },
      };
      mutations.pushMessageToConversation(state, {
        content: 'hello',
        id: 1,
        message_type: 0,
        status: 'sent',
      });
      expect(state.conversations).toEqual({
        1: { content: 'hello', id: 1, message_type: 0, status: 'sent' },
      });
    });

    it('adds message in conversation if it is a new message', () => {
      const state = { conversations: {} };
      mutations.pushMessageToConversation(state, {
        content: 'hello',
        id: 1,
        message_type: 0,
        status: 'sent',
      });
      expect(state.conversations).toEqual({
        1: { content: 'hello', id: 1, message_type: 0, status: 'sent' },
      });
    });
  });

  describe('#setConversationListLoading', () => {
    it('set status correctly', () => {
      const state = { uiFlags: { isFetchingList: false } };
      mutations.setConversationListLoading(state, true);
      expect(state.uiFlags.isFetchingList).toEqual(true);
    });
  });

  describe('#setMessagesInConversation', () => {
    it('sets allMessagesLoaded flag if payload is empty', () => {
      const state = { uiFlags: { allMessagesLoaded: false } };
      mutations.setMessagesInConversation(state, []);
      expect(state.uiFlags.allMessagesLoaded).toEqual(true);
    });

    it('sets messages if payload is not empty', () => {
      const state = {
        uiFlags: { allMessagesLoaded: false },
        conversations: {},
      };
      mutations.setMessagesInConversation(state, [{ id: 1, content: 'hello' }]);
      expect(state.conversations).toEqual({
        1: { id: 1, content: 'hello' },
      });
      expect(state.uiFlags.allMessagesLoaded).toEqual(false);
    });
  });
});
