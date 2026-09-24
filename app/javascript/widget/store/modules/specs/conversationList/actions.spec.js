import { actions } from '../../conversationList';
import { API } from 'widget/helpers/axios';

vi.mock('widget/helpers/axios');

const commit = vi.fn();
const dispatch = vi.fn();

const records = [
  { id: 3, status: 'resolved', contact_last_seen_at: 30, unread_count: 0 },
  { id: 2, status: 'open', contact_last_seen_at: 20, unread_count: 2 },
];

describe('#actions', () => {
  describe('#fetch', () => {
    it('stores the page returned by the API', async () => {
      API.get.mockResolvedValue({
        data: {
          payload: records,
          meta: { has_next_page: true, unread_count: 1 },
        },
      });
      await actions.fetch({ commit });
      expect(commit.mock.calls).toEqual([
        ['setFetching', true],
        [
          'setRecords',
          { payload: records, page: 1, hasNextPage: true, unreadCount: 1 },
        ],
        ['setFetching', false],
      ]);
    });

    it('clears the loading flag when the API fails', async () => {
      API.get.mockRejectedValue(new Error('offline'));
      await actions.fetch({ commit });
      expect(commit.mock.calls).toEqual([
        ['setFetching', true],
        ['setFetching', false],
      ]);
    });
  });

  describe('#fetchMore', () => {
    it('requests the next page', () => {
      actions.fetchMore({
        dispatch,
        state: { page: 1, hasNextPage: true, uiFlags: { isFetching: false } },
      });
      expect(dispatch).toBeCalledWith('fetch', { page: 2 });
    });

    it('does nothing when there is no next page or a fetch is running', () => {
      actions.fetchMore({
        dispatch,
        state: { page: 1, hasNextPage: false, uiFlags: { isFetching: false } },
      });
      actions.fetchMore({
        dispatch,
        state: { page: 1, hasNextPage: true, uiFlags: { isFetching: true } },
      });
      expect(dispatch).not.toBeCalled();
    });
  });

  describe('#load', () => {
    it('opens the most recent conversation that is not resolved', async () => {
      const state = { records };
      await actions.load({ state, dispatch });
      expect(dispatch.mock.calls).toEqual([
        ['startNew'],
        ['fetch'],
        ['open', 2],
      ]);
    });

    it('prefers the most recent conversation with unread messages, even when resolved', async () => {
      const state = {
        records: [
          { id: 4, status: 'open', unread_count: 0 },
          { id: 3, status: 'resolved', unread_count: 2 },
          { id: 2, status: 'open', unread_count: 1 },
        ],
      };
      await actions.load({ state, dispatch });
      expect(dispatch).toBeCalledWith('open', 3);
    });

    it('falls back to the most recent conversation when all are resolved', async () => {
      const state = { records: [records[0]] };
      await actions.load({ state, dispatch });
      expect(dispatch).toBeCalledWith('open', 3);
    });

    it('opens nothing for a visitor without conversations', async () => {
      await actions.load({ state: { records: [] }, dispatch });
      expect(dispatch.mock.calls).toEqual([['startNew'], ['fetch']]);
    });
  });

  describe('#open', () => {
    it('switches the thread to the selected conversation', async () => {
      const rootState = { conversationAttributes: { id: 3 } };
      await actions.open(
        { state: { records }, commit, dispatch, rootState },
        2
      );

      expect(dispatch.mock.calls).toEqual([
        ['conversation/clearConversations', {}, { root: true }],
        ['conversation/fetchOldConversations', {}, { root: true }],
      ]);
      expect(commit.mock.calls).toEqual([
        [
          'conversationAttributes/SET_CONVERSATION_ATTRIBUTES',
          records[1],
          { root: true },
        ],
        ['conversation/setMetaUserLastSeenAt', 20, { root: true }],
        ['markRead', 2],
      ]);
    });

    it('keeps the current thread when no conversation was open yet', async () => {
      const rootState = { conversationAttributes: { id: '' } };
      await actions.open(
        { state: { records }, commit, dispatch, rootState },
        2
      );

      expect(dispatch).not.toBeCalledWith(
        'conversation/clearConversations',
        {},
        { root: true }
      );
    });

    it('refreshes the list before opening a conversation it does not know yet', async () => {
      const rootState = { conversationAttributes: { id: '' } };
      const state = { records: [] };
      dispatch.mockImplementation(async action => {
        if (action === 'fetch') state.records = records;
      });

      await actions.open({ state, commit, dispatch, rootState }, 2);

      expect(commit.mock.calls[0]).toEqual([
        'conversationAttributes/SET_CONVERSATION_ATTRIBUTES',
        { id: 2 },
        { root: true },
      ]);
      expect(dispatch).toBeCalledWith('fetch');
      expect(commit).toBeCalledWith(
        'conversationAttributes/SET_CONVERSATION_ATTRIBUTES',
        records[1],
        { root: true }
      );
    });

    it('does nothing when the conversation is already open', async () => {
      const rootState = { conversationAttributes: { id: 2 } };
      await actions.open(
        { state: { records }, commit, dispatch, rootState },
        2
      );
      expect(commit).not.toBeCalled();
      expect(dispatch).not.toBeCalled();
    });
  });

  describe('#startNew', () => {
    it('clears the active conversation and its thread', async () => {
      await actions.startNew({ dispatch });
      expect(dispatch.mock.calls).toEqual([
        [
          'conversationAttributes/clearConversationAttributes',
          {},
          { root: true },
        ],
        ['conversation/clearConversations', {}, { root: true }],
      ]);
    });
  });
});
