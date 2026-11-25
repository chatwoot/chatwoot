import { actions } from '../../conversationSearch';
import types from '../../../mutation-types';
import axios from 'axios';

const commit = vi.fn();
global.axios = axios;
vi.mock('axios');

const withMinimum = messageSearchMinQueryLength => ({
  'globalConfig/get': { messageSearchMinQueryLength },
});

describe('#messageSearch with MESSAGE_SEARCH_MIN_QUERY_LENGTH', () => {
  beforeEach(() => {
    commit.mockClear();
    axios.get.mockClear();
    axios.get.mockResolvedValue({
      data: { payload: { messages: [{ id: 1 }] } },
    });
  });

  it('does not request messages for a term shorter than the minimum', async () => {
    const result = await actions.messageSearch(
      { commit, rootGetters: withMinimum(3) },
      { q: ' 16 ', page: 1 }
    );

    expect(axios.get).not.toHaveBeenCalled();
    expect(result).toBe(true);
    expect(commit.mock.calls).toEqual([
      [types.MESSAGE_SEARCH_SET_UI_FLAG, { hasMore: false }],
    ]);
  });

  it('requests messages for a term of exactly the minimum length', async () => {
    await actions.messageSearch(
      { commit, rootGetters: withMinimum(3) },
      { q: '169', page: 1 }
    );

    expect(axios.get).toHaveBeenCalledTimes(1);
    expect(commit.mock.calls).toContainEqual([
      types.MESSAGE_SEARCH_SET,
      [{ id: 1 }],
    ]);
  });

  it('requests messages for a filter-only search with no term', async () => {
    await actions.messageSearch(
      { commit, rootGetters: withMinimum(3) },
      { q: '', inboxId: 2, page: 1 }
    );

    expect(axios.get).toHaveBeenCalledTimes(1);
  });

  it('requests messages for a one digit term when the minimum is 0', async () => {
    await actions.messageSearch(
      { commit, rootGetters: withMinimum(0) },
      { q: '1', page: 1 }
    );

    expect(axios.get).toHaveBeenCalledTimes(1);
  });
});
