import commonHelpers from '../../../../helper/commons';
import getters from '../../conversations/getters';

describe('#getters', () => {
  describe('#getNextChatConversation', () => {
    it('return the next chat', () => {
      const state = {
        allConversations: [
          {
            id: 1,
          },
          {
            id: 2,
          },
        ],
        selectedChat: {
          id: 1,
        },
      };
      expect(getters.getNextChatConversation(state)).toEqual({
        id: 2,
      });
    });
    it('return null when there is only one chat', () => {
      const state = {
        allConversations: [
          {
            id: 1,
          },
        ],
        selectedChat: {
          id: 1,
        },
      };
      expect(getters.getNextChatConversation(state)).toBeNull();
    });
  });
});
