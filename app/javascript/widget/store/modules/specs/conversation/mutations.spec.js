import { mutations } from '../../conversation';

const temporaryMessagePayload = {
  content: 'hello',
  id: 1,
  message_type: 0,
  status: 'in_progress',
};

const incomingMessagePayload = {
  content: 'hello',
  id: 1,
  message_type: 0,
  status: 'sent',
};

const outgoingMessagePayload = {
  content: 'hello',
  id: 1,
  message_type: 1,
  status: 'sent',
};

describe('#mutations', () => {
  describe('#pushMessageToConversation', () => {
    it('add message to conversation if outgoing', () => {
      const state = { conversations: {} };
      mutations.pushMessageToConversation(state, outgoingMessagePayload);
      expect(state.conversations).toEqual({
        1: outgoingMessagePayload,
      });
    });

    it('add message to conversation if message in undelivered', () => {
      const state = { conversations: {} };
      mutations.pushMessageToConversation(state, temporaryMessagePayload);
      expect(state.conversations).toEqual({
        1: temporaryMessagePayload,
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
      mutations.pushMessageToConversation(state, incomingMessagePayload);
      expect(state.conversations).toEqual({
        1: incomingMessagePayload,
      });
    });

    it('adds message in conversation if it is a new message', () => {
      const state = { conversations: {} };
      mutations.pushMessageToConversation(state, incomingMessagePayload);
      expect(state.conversations).toEqual({
        1: incomingMessagePayload,
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
