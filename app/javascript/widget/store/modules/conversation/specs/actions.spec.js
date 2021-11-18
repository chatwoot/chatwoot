import { actions } from '../../conversation/actions';
import getUuid from '../../../../helpers/uuid';
import { API } from 'widget/helpers/axios';

jest.mock('../../../../helpers/uuid');
jest.mock('widget/helpers/axios');

const commit = jest.fn();

describe('#actions', () => {
  describe('#fetchAllConversations', () => {
    it('sends correct mutations', async () => {
      API.get.mockResolvedValue({
        data: [
          {
            id: 1,
            messages: [{ id: 12 }],
            status: 'open',
            contact_last_seen_at: 12345,
          },
        ],
      });

      await actions.fetchAllConversations({ commit });
      expect(commit.mock.calls).toEqual([
        ['setUIFlag', { isFetching: true }],
        [
          'addConversationEntry',
          {
            id: 1,
            messages: [{ id: 12 }],
            status: 'open',
            contact_last_seen_at: 12345,
          },
        ],
        ['addConversationId', 1],
        ['setConversationUIFlag', { uiFlags: {}, conversationId: 1 }],
        [
          'setConversationMeta',
          {
            meta: { userLastSeenAt: 12345, status: 'open' },
            conversationId: 1,
          },
        ],
        [
          'message/addMessagesEntry',
          { conversationId: 1, messages: [{ id: 12 }] },
          { root: true },
        ],
        [
          'addMessageIdsToConversation',
          { conversationId: 1, messages: [{ id: 12 }] },
        ],
        ['setUIFlag', { isFetching: false }],
      ]);
    });
  });
});
