import { mutations } from '../../messageV2/mutations';

describe('#mutations', () => {
  describe('#updateMessageEntry', () => {
    it('it updates message in conversation correctly', () => {
      const state = {
        messages: { byId: { 2: { id: 2, content: 'hi' } }, allIds: [2] },
      };
      const message = { id: 2, content: 'hello' };
      mutations.updateMessageEntry(state, message);
      expect(state.messages.byId[2].content).toEqual('hello');
    });
    it('it does not create message if message does not exist in conversation', () => {
      const state = {
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
        messages: { byId: { 2: { id: 2, content: 'hi' } }, allIds: [2] },
      };
      const messageId = 2;
      mutations.removeMessageEntry(state, messageId);
      expect(state.messages.byId[2]).toEqual(undefined);
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
