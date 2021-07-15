import { mutations } from '../../conversation/mutations';

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

  describe('#setConversationUIFlag', () => {
    it('set uiFlags correctly', () => {
      const state = { uiFlags: { isFetchingList: false } };
      mutations.setConversationUIFlag(state, { isCreating: true });
      expect(state.uiFlags).toEqual({
        isFetchingList: false,
        isCreating: true,
      });
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

  describe('#toggleAgentTypingStatus', () => {
    it('sets isAgentTyping flag to true', () => {
      const state = { uiFlags: { isAgentTyping: false } };
      mutations.toggleAgentTypingStatus(state, { status: 'on' });
      expect(state.uiFlags.isAgentTyping).toEqual(true);
    });

    it('sets isAgentTyping flag to false', () => {
      const state = { uiFlags: { isAgentTyping: true } };
      mutations.toggleAgentTypingStatus(state, { status: 'off' });
      expect(state.uiFlags.isAgentTyping).toEqual(false);
    });
  });

  describe('#updateAttachmentMessageStatus', () => {
    it('Updates status of loading messages if payload is not empty', () => {
      const state = {
        conversations: {
          rand_id_123: {
            content: '',
            id: 'rand_id_123',
            message_type: 0,
            status: 'in_progress',
            attachment: {
              file: '',
              file_type: 'image',
            },
          },
        },
      };
      const message = {
        id: '1',
        content: '',
        status: 'sent',
        message_type: 0,
        attachments: [
          {
            file: '',
            file_type: 'image',
          },
        ],
      };
      mutations.updateAttachmentMessageStatus(state, {
        message,
        tempId: 'rand_id_123',
      });

      expect(state.conversations).toEqual({
        1: {
          id: '1',
          content: '',
          message_type: 0,
          status: 'sent',
          attachments: [
            {
              file: '',
              file_type: 'image',
            },
          ],
        },
      });
    });
  });

  describe('#clearConversations', () => {
    it('clears the state', () => {
      const state = { conversations: { 1: { id: 1 } } };
      mutations.clearConversations(state);
      expect(state.conversations).toEqual({});
    });
  });

  describe('#deleteMessage', () => {
    it('delete the message from conversation', () => {
      const state = { conversations: { 1: { id: 1 } } };
      mutations.deleteMessage(state, 1);
      expect(state.conversations).toEqual({});
    });
  });
});
