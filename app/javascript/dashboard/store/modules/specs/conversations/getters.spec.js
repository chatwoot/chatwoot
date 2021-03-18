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
});
