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
    it('should handle successful conversation search', async () => {
      axios.get.mockResolvedValue({
        data: { payload: { conversations: [{ id: 1 }] } },
      });

      await actions.conversationSearch({ commit }, { q: 'test', page: 1 });
      expect(commit.mock.calls).toEqual([
        [types.CONVERSATION_SEARCH_SET_UI_FLAG, { isFetching: true }],
        [types.CONVERSATION_SEARCH_SET, [{ id: 1 }]],
        [types.CONVERSATION_SEARCH_SET_UI_FLAG, { isFetching: false }],
      ]);
    });

    it('should handle failed conversation search', async () => {
      axios.get.mockRejectedValue({});
      await actions.conversationSearch({ commit }, { q: 'test' });
      expect(commit.mock.calls).toEqual([
        [types.CONVERSATION_SEARCH_SET_UI_FLAG, { isFetching: true }],
        [types.CONVERSATION_SEARCH_SET_UI_FLAG, { isFetching: false }],
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
        [types.MESSAGE_SEARCH_SET_UI_FLAG, { isFetching: false }],
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
  });

  describe('#clearSearchResults', () => {
    it('should commit clear search results mutation', () => {
      actions.clearSearchResults({ commit });
      expect(commit).toHaveBeenCalledWith(types.CLEAR_SEARCH_RESULTS);
    });
  });
});
