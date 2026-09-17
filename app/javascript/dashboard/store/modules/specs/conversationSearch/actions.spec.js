import { actions, initialState } from '../../conversationSearch';
import types from '../../../mutation-types';
import axios from 'axios';

let state;
const commit = vi.fn();
global.axios = axios;
vi.mock('axios');

describe('#actions', () => {
  beforeEach(() => {
    state = structuredClone(initialState);
    commit.mockClear();
    axios.get.mockClear();
  });

  describe('#get', () => {
    it('sends correct actions if no query param is provided', () => {
      actions.get({ commit, state }, { q: '' });
      expect(commit.mock.calls).toEqual([[types.SEARCH_CONVERSATIONS_SET, []]]);
    });

    it('sends correct actions if query param is provided and API call is success', async () => {
      axios.get.mockResolvedValue({
        data: {
          payload: [{ messages: [{ id: 1, content: 'value testing' }], id: 1 }],
        },
      });

      await actions.get({ commit, state }, { q: 'value' });
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
      await actions.get({ commit, state }, { q: 'value' });
      expect(commit.mock.calls).toEqual([
        [types.SEARCH_CONVERSATIONS_SET, []],
        [types.SEARCH_CONVERSATIONS_SET_UI_FLAG, { isFetching: true }],
        [types.SEARCH_CONVERSATIONS_SET_UI_FLAG, { isFetching: false }],
      ]);
    });
  });

  describe('#contactSearch', () => {
    it('should handle successful contact search', async () => {
      axios.get.mockResolvedValue({
        data: { payload: { contacts: [{ id: 1 }] } },
      });

      await actions.contactSearch({ commit, state }, { q: 'test', page: 1 });
      expect(commit.mock.calls).toEqual([
        [
          types.CONTACT_SEARCH_SET_UI_FLAG,
          { isFetching: true, hasError: false },
        ],
        [
          types.SEARCH_RESULTS_RECEIVED,
          {
            type: 'contacts',
            records: [{ id: 1 }],
            page: 1,
            perPage: 15,
            backend: undefined,
          },
        ],
        [types.CONTACT_SEARCH_SET_UI_FLAG, { hasMore: false }],
        [types.CONTACT_SEARCH_SET_UI_FLAG, { isFetching: false }],
      ]);
    });

    it('should handle failed contact search', async () => {
      axios.get.mockRejectedValue({});
      await actions.contactSearch({ commit, state }, { q: 'test' });
      expect(commit.mock.calls).toEqual([
        [
          types.CONTACT_SEARCH_SET_UI_FLAG,
          { isFetching: true, hasError: false },
        ],
        [types.CONTACT_SEARCH_SET_UI_FLAG, { hasError: true }],
        [types.CONTACT_SEARCH_SET_UI_FLAG, { isFetching: false }],
      ]);
    });
  });

  describe('#conversationSearch', () => {
    it('should handle successful conversation search', async () => {
      axios.get.mockResolvedValue({
        data: { payload: { conversations: [{ id: 1 }] } },
      });

      await actions.conversationSearch(
        { commit, state },
        { q: 'test', page: 1 }
      );
      expect(commit.mock.calls).toEqual([
        [
          types.CONVERSATION_SEARCH_SET_UI_FLAG,
          { isFetching: true, hasError: false },
        ],
        [
          types.SEARCH_RESULTS_RECEIVED,
          {
            type: 'conversations',
            records: [{ id: 1 }],
            page: 1,
            perPage: 15,
            backend: undefined,
          },
        ],
        [types.CONVERSATION_SEARCH_SET_UI_FLAG, { hasMore: false }],
        [types.CONVERSATION_SEARCH_SET_UI_FLAG, { isFetching: false }],
      ]);
    });

    it('should handle failed conversation search', async () => {
      axios.get.mockRejectedValue({});
      await actions.conversationSearch({ commit, state }, { q: 'test' });
      expect(commit.mock.calls).toEqual([
        [
          types.CONVERSATION_SEARCH_SET_UI_FLAG,
          { isFetching: true, hasError: false },
        ],
        [types.CONVERSATION_SEARCH_SET_UI_FLAG, { hasError: true }],
        [types.CONVERSATION_SEARCH_SET_UI_FLAG, { isFetching: false }],
      ]);
    });
  });

  describe('#messageSearch', () => {
    it('should handle successful message search', async () => {
      axios.get.mockResolvedValue({
        data: { payload: { messages: [{ id: 1 }] } },
      });

      await actions.messageSearch({ commit, state }, { q: 'test', page: 1 });
      expect(commit.mock.calls).toEqual([
        [
          types.MESSAGE_SEARCH_SET_UI_FLAG,
          { isFetching: true, hasError: false },
        ],
        [
          types.SEARCH_RESULTS_RECEIVED,
          {
            type: 'messages',
            records: [{ id: 1 }],
            page: 1,
            perPage: 15,
            backend: undefined,
          },
        ],
        [types.MESSAGE_SEARCH_SET_UI_FLAG, { hasMore: false }],
        [types.MESSAGE_SEARCH_SET_UI_FLAG, { isFetching: false }],
      ]);
    });

    it('should mark hasMore when the API returns a full page', async () => {
      const fullPage = Array.from({ length: 15 }, (_, i) => ({ id: i + 1 }));
      axios.get.mockResolvedValue({
        data: { payload: { messages: fullPage } },
      });

      await actions.messageSearch({ commit, state }, { q: 'test', page: 1 });
      expect(commit.mock.calls).toContainEqual([
        types.MESSAGE_SEARCH_SET_UI_FLAG,
        { hasMore: true },
      ]);
    });

    it('should handle failed message search', async () => {
      axios.get.mockRejectedValue({});
      await actions.messageSearch({ commit, state }, { q: 'test' });
      expect(commit.mock.calls).toEqual([
        [
          types.MESSAGE_SEARCH_SET_UI_FLAG,
          { isFetching: true, hasError: false },
        ],
        [types.MESSAGE_SEARCH_SET_UI_FLAG, { hasError: true }],
        [types.MESSAGE_SEARCH_SET_UI_FLAG, { isFetching: false }],
      ]);
    });

    it('should report success so callers can keep the page counter', async () => {
      axios.get.mockResolvedValue({
        data: { payload: { messages: [{ id: 1 }] } },
      });
      await expect(
        actions.messageSearch({ commit, state }, { q: 'test', page: 2 })
      ).resolves.toBe(true);
    });

    it('should report failure so callers can roll the page counter back', async () => {
      axios.get.mockRejectedValue({});
      await expect(
        actions.messageSearch({ commit, state }, { q: 'test', page: 2 })
      ).resolves.toBe(false);
    });
  });

  describe('#articleSearch', () => {
    it('should handle successful article search', async () => {
      axios.get.mockResolvedValue({
        data: { payload: { articles: [{ id: 1 }] } },
      });

      await actions.articleSearch({ commit, state }, { q: 'test', page: 1 });
      expect(commit.mock.calls).toEqual([
        [
          types.ARTICLE_SEARCH_SET_UI_FLAG,
          { isFetching: true, hasError: false },
        ],
        [
          types.SEARCH_RESULTS_RECEIVED,
          {
            type: 'articles',
            records: [{ id: 1 }],
            page: 1,
            perPage: 15,
            backend: undefined,
          },
        ],
        [types.ARTICLE_SEARCH_SET_UI_FLAG, { hasMore: false }],
        [types.ARTICLE_SEARCH_SET_UI_FLAG, { isFetching: false }],
      ]);
    });

    it('should handle article search with date filters', async () => {
      axios.get.mockResolvedValue({
        data: { payload: { articles: [{ id: 1 }] } },
      });

      await actions.articleSearch(
        { commit, state },
        { q: 'test', page: 1, since: 1700000000, until: 1732000000 }
      );
      expect(commit.mock.calls).toEqual([
        [
          types.ARTICLE_SEARCH_SET_UI_FLAG,
          { isFetching: true, hasError: false },
        ],
        [
          types.SEARCH_RESULTS_RECEIVED,
          {
            type: 'articles',
            records: [{ id: 1 }],
            page: 1,
            perPage: 15,
            backend: undefined,
          },
        ],
        [types.ARTICLE_SEARCH_SET_UI_FLAG, { hasMore: false }],
        [types.ARTICLE_SEARCH_SET_UI_FLAG, { isFetching: false }],
      ]);
    });

    it('should handle failed article search', async () => {
      axios.get.mockRejectedValue({});
      await actions.articleSearch({ commit, state }, { q: 'test' });
      expect(commit.mock.calls).toEqual([
        [
          types.ARTICLE_SEARCH_SET_UI_FLAG,
          { isFetching: true, hasError: false },
        ],
        [types.ARTICLE_SEARCH_SET_UI_FLAG, { hasError: true }],
        [types.ARTICLE_SEARCH_SET_UI_FLAG, { isFetching: false }],
      ]);
    });
  });

  describe('#clearSearchResults', () => {
    it('should commit clear search results mutation', () => {
      actions.clearSearchResults({ commit, state });
      expect(commit).toHaveBeenCalledWith(types.CLEAR_SEARCH_RESULTS);
    });
  });
});
