import commonHelpers from '../../../../helper/commons';
import getters from '../../conversations/getters';

// loads .last() helper
commonHelpers();

describe('#getters', () => {
  describe('#getAllConversations', () => {
    it('order conversations based on last message date', () => {
      const state = {
        allConversations: [
          {
            id: 1,
            messages: [
              {
                created_at: 1466424480,
              },
            ],
          },
          {
            id: 2,
            messages: [
              {
                created_at: 2466424490,
              },
            ],
          },
        ],
      };
      expect(getters.getAllConversations(state)).toEqual([
        {
          id: 2,
          messages: [
            {
              created_at: 2466424490,
            },
          ],
        },
        {
          id: 1,
          messages: [
            {
              created_at: 1466424480,
            },
          ],
        },
      ]);
    });
  });
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
        selectedChatId: 1,
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
        selectedChatId: 1,
      };
      expect(getters.getNextChatConversation(state)).toBeNull();
    });
  });
});
