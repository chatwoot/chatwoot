import { actions } from '../../conversationSearch';
import types from '../../../mutation-types';
import axios from 'axios';

const commit = vi.fn();
const dispatch = vi.fn();
global.axios = axios;
vi.mock('axios');

describe('#actions', () => {
  beforeEach(() => {
    commit.mockClear();
    dispatch.mockClear();
    axios.get.mockClear();
  });

  describe('#get', () => {
    it('sends correct actions if no query param is provided', () => {
      actions.get({ commit }, { q: '' });
      expect(commit.mock.calls).toEqual([[types.SEARCH_CONVERSATIONS_SET, []]]);
    });

    it('sends correct actions if query param is provided and API call is success', async () => {
      axios.get.mockResolvedValue({
        data: {
          payload: [{ messages: [{ id: 1, content: 'value testing' }], id: 1 }],
        },
      });

      await actions.get({ commit }, { q: 'value' });
      expect(commit.mock.calls).toEqual([
        [types.SEARCH_CONVERSATIONS_SET, []],
        [types.SEARCH_CONVERSATIONS_SET_UI_FLAG, { isFetching: true }],
        [
          types.SEARCH_CONVERSATIONS_SET,
          [{ messages: [{ id: 1, content: 'value testing' }], id: 1 }],
        ],
        [types.SEARCH_CONVERSATIONS_SET_UI_FLAG, { isFetching: false }],
      ]);
    });

    it('sends correct actions if query param is provided and API call is errored', async () => {
      axios.get.mockRejectedValue({});
      await actions.get({ commit }, { q: 'value' });
      expect(commit.mock.calls).toEqual([
        [types.SEARCH_CONVERSATIONS_SET, []],
        [types.SEARCH_CONVERSATIONS_SET_UI_FLAG, { isFetching: true }],
        [types.SEARCH_CONVERSATIONS_SET_UI_FLAG, { isFetching: false }],
      ]);
    });
  });

  describe('#fullSearch', () => {
    it('should not dispatch any actions if no query provided', async () => {
      await actions.fullSearch({ commit, dispatch }, { q: '' });
      expect(dispatch).not.toHaveBeenCalled();
    });

    it('should dispatch all search actions and set UI flags correctly', async () => {
      await actions.fullSearch({ commit, dispatch }, { q: 'test' });

      expect(commit.mock.calls).toEqual([
        [
          types.FULL_SEARCH_SET_UI_FLAG,
          { isFetching: true, isSearchCompleted: false },
        ],
        [
          types.FULL_SEARCH_SET_UI_FLAG,
          { isFetching: false, isSearchCompleted: true },
        ],
      ]);

      expect(dispatch).toHaveBeenCalledWith('contactSearch', { q: 'test' });
      expect(dispatch).toHaveBeenCalledWith('conversationSearch', {
        q: 'test',
      });
      expect(dispatch).toHaveBeenCalledWith('messageSearch', { q: 'test' });
      expect(dispatch).toHaveBeenCalledWith('articleSearch', { q: 'test' });
    });

    it('should pass filters to all search actions including articleSearch', async () => {
      const payload = { q: 'test', since: 1700000000, until: 1732000000 };
      await actions.fullSearch({ commit, dispatch }, payload);

      expect(dispatch).toHaveBeenCalledWith('contactSearch', payload);
      expect(dispatch).toHaveBeenCalledWith('conversationSearch', payload);
      expect(dispatch).toHaveBeenCalledWith('messageSearch', payload);
      expect(dispatch).toHaveBeenCalledWith('articleSearch', payload);
    });
  });

  describe('#contactSearch', () => {
    it('should handle successful contact search', async () => {
      axios.get.mockResolvedValue({
        data: { payload: { contacts: [{ id: 1 }] } },
      });

      await actions.contactSearch({ commit }, { q: 'test', page: 1 });
      expect(commit.mock.calls).toEqual([
        [types.CONTACT_SEARCH_SET_UI_FLAG, { isFetching: true }],
        [types.CONTACT_SEARCH_SET, [{ id: 1 }]],
        [types.CONTACT_SEARCH_SET_UI_FLAG, { hasMore: false }],
        [types.CONTACT_SEARCH_SET_UI_FLAG, { isFetching: false }],
      ]);
    });

    it('should handle failed contact search', async () => {
      axios.get.mockRejectedValue({});
      await actions.contactSearch({ commit }, { q: 'test' });
      expect(commit.mock.calls).toEqual([
        [types.CONTACT_SEARCH_SET_UI_FLAG, { isFetching: true }],
        [types.CONTACT_SEARCH_SET_UI_FLAG, { isFetching: false }],
      ]);
    });
  });

  describe('#conversationSearch', () => {
    it('keeps the current ranked page when the engine reports an error', async () => {
      axios.get.mockResolvedValue({
        data: { payload: { conversations: [] }, meta: { error: true } },
      });
      await expect(
        actions.conversationSearch({ commit }, { q: 'test', cursor: '25' })
      ).resolves.toBe(false);
      expect(commit).toHaveBeenCalledWith(
        types.CONVERSATION_SEARCH_SET_UI_FLAG,
        { hasError: true }
      );
      expect(commit).not.toHaveBeenCalledWith(
        types.CONVERSATION_SEARCH_REPLACE,
        []
      );
    });

    it('ignores a stale response and its cursor after a new search starts', async () => {
      let finishOld;
      axios.get.mockImplementationOnce(
        () =>
          new Promise(resolve => {
            finishOld = resolve;
          })
      );
      const oldRequest = actions.conversationSearch({ commit }, { q: 'old' });
      axios.get.mockResolvedValueOnce({
        data: {
          payload: { conversations: [{ id: 2 }] },
          meta: { has_more: false },
        },
      });
      await actions.conversationSearch({ commit }, { q: 'new' });
      finishOld({
        data: {
          payload: { conversations: [{ id: 1 }] },
          meta: { has_more: true, next_cursor: '123' },
        },
      });
      await oldRequest;
      expect(commit).not.toHaveBeenCalledWith(types.CONVERSATION_SEARCH_SET, [
        { id: 1 },
      ]);
      expect(commit).not.toHaveBeenCalledWith(
        types.CONVERSATION_SEARCH_SET_UI_FLAG,
        { hasMore: true, nextCursor: '123' }
      );
    });

    it('should handle successful conversation search', async () => {
      axios.get.mockResolvedValue({
        data: { payload: { conversations: [{ id: 1 }] } },
      });

      await actions.conversationSearch({ commit }, { q: 'test', page: 1 });
      expect(commit.mock.calls).toEqual([
        [
          types.CONVERSATION_SEARCH_SET_UI_FLAG,
          { isFetching: true, hasError: false },
        ],
        [types.CONVERSATION_SEARCH_SET, [{ id: 1 }]],
        [
          types.CONVERSATION_SEARCH_SET_UI_FLAG,
          { hasMore: false, nextCursor: null, ranked: false },
        ],
        [types.CONVERSATION_SEARCH_SET_UI_FLAG, { isFetching: false }],
      ]);
    });

    it('keeps continuation available when a candidate batch has no visible rows', async () => {
      axios.get.mockResolvedValue({
        data: {
          payload: { conversations: [] },
          meta: { next_cursor: '123', has_more: true },
        },
      });
      await actions.conversationSearch(
        { commit },
        { q: 'test', page: 2, cursor: '456' }
      );
      expect(commit).toHaveBeenCalledWith(
        types.CONVERSATION_SEARCH_SET_UI_FLAG,
        {
          hasMore: true,
          nextCursor: '123',
          ranked: true,
        }
      );
      expect(axios.get).toHaveBeenCalledWith(
        expect.stringContaining('/conversations'),
        expect.objectContaining({
          params: expect.objectContaining({ conversation_cursor: '456' }),
        })
      );
    });

    it('honors an exhausted engine page even if it contains fifteen rows', async () => {
      axios.get.mockResolvedValue({
        data: {
          payload: {
            conversations: Array.from({ length: 15 }, (_, id) => ({ id })),
          },
          meta: { next_cursor: null, has_more: false },
        },
      });
      await actions.conversationSearch({ commit }, { q: 'test' });
      expect(commit).toHaveBeenCalledWith(
        types.CONVERSATION_SEARCH_SET_UI_FLAG,
        {
          hasMore: false,
          nextCursor: null,
          ranked: true,
        }
      );
    });

    it('should handle failed conversation search', async () => {
      axios.get.mockRejectedValue({});
      await actions.conversationSearch({ commit }, { q: 'test' });
      expect(commit.mock.calls).toEqual([
        [
          types.CONVERSATION_SEARCH_SET_UI_FLAG,
          { isFetching: true, hasError: false },
        ],
        [types.CONVERSATION_SEARCH_SET_UI_FLAG, { isFetching: false }],
        [types.CONVERSATION_SEARCH_SET_UI_FLAG, { hasError: true }],
      ]);
    });
  });

  describe('#messageSearch', () => {
    it('should handle successful message search', async () => {
      axios.get.mockResolvedValue({
        data: { payload: { messages: [{ id: 1 }] } },
      });

      await actions.messageSearch({ commit }, { q: 'test', page: 1 });
      expect(commit.mock.calls).toEqual([
        [types.MESSAGE_SEARCH_SET_UI_FLAG, { isFetching: true }],
        [types.MESSAGE_SEARCH_SET, [{ id: 1 }]],
        [types.MESSAGE_SEARCH_SET_UI_FLAG, { hasMore: false }],
        [types.MESSAGE_SEARCH_SET_UI_FLAG, { isFetching: false }],
      ]);
    });

    it('should mark hasMore when the API returns a full page', async () => {
      const fullPage = Array.from({ length: 15 }, (_, i) => ({ id: i + 1 }));
      axios.get.mockResolvedValue({
        data: { payload: { messages: fullPage } },
      });

      await actions.messageSearch({ commit }, { q: 'test', page: 1 });
      expect(commit.mock.calls).toContainEqual([
        types.MESSAGE_SEARCH_SET_UI_FLAG,
        { hasMore: true },
      ]);
    });

    it('should handle failed message search', async () => {
      axios.get.mockRejectedValue({});
      await actions.messageSearch({ commit }, { q: 'test' });
      expect(commit.mock.calls).toEqual([
        [types.MESSAGE_SEARCH_SET_UI_FLAG, { isFetching: true }],
        [types.MESSAGE_SEARCH_SET_UI_FLAG, { isFetching: false }],
      ]);
    });

    it('should report success so callers can keep the page counter', async () => {
      axios.get.mockResolvedValue({
        data: { payload: { messages: [{ id: 1 }] } },
      });
      await expect(
        actions.messageSearch({ commit }, { q: 'test', page: 2 })
      ).resolves.toBe(true);
    });

    it('should report failure so callers can roll the page counter back', async () => {
      axios.get.mockRejectedValue({});
      await expect(
        actions.messageSearch({ commit }, { q: 'test', page: 2 })
      ).resolves.toBe(false);
    });
  });

  describe('#articleSearch', () => {
    it('should handle successful article search', async () => {
      axios.get.mockResolvedValue({
        data: { payload: { articles: [{ id: 1 }] } },
      });

      await actions.articleSearch({ commit }, { q: 'test', page: 1 });
      expect(commit.mock.calls).toEqual([
        [types.ARTICLE_SEARCH_SET_UI_FLAG, { isFetching: true }],
        [types.ARTICLE_SEARCH_SET, [{ id: 1 }]],
        [types.ARTICLE_SEARCH_SET_UI_FLAG, { hasMore: false }],
        [types.ARTICLE_SEARCH_SET_UI_FLAG, { isFetching: false }],
      ]);
    });

    it('should handle article search with date filters', async () => {
      axios.get.mockResolvedValue({
        data: { payload: { articles: [{ id: 1 }] } },
      });

      await actions.articleSearch(
        { commit },
        { q: 'test', page: 1, since: 1700000000, until: 1732000000 }
      );
      expect(commit.mock.calls).toEqual([
        [types.ARTICLE_SEARCH_SET_UI_FLAG, { isFetching: true }],
        [types.ARTICLE_SEARCH_SET, [{ id: 1 }]],
        [types.ARTICLE_SEARCH_SET_UI_FLAG, { hasMore: false }],
        [types.ARTICLE_SEARCH_SET_UI_FLAG, { isFetching: false }],
      ]);
    });

    it('should handle failed article search', async () => {
      axios.get.mockRejectedValue({});
      await actions.articleSearch({ commit }, { q: 'test' });
      expect(commit.mock.calls).toEqual([
        [types.ARTICLE_SEARCH_SET_UI_FLAG, { isFetching: true }],
        [types.ARTICLE_SEARCH_SET_UI_FLAG, { isFetching: false }],
      ]);
    });
  });

  describe('#clearSearchResults', () => {
    it('should commit clear search results mutation', () => {
      actions.clearSearchResults({ commit });
      expect(commit).toHaveBeenCalledWith(types.CLEAR_SEARCH_RESULTS);
    });
  });
});
