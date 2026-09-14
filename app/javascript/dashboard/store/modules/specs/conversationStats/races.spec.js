import axios from 'axios';
import { actions, mutations } from '../../conversationStats';
import conversationActions from '../../conversations/actions';

vi.mock('axios');
global.axios = axios;

describe('conversation count refresh races', () => {
  let state;
  let commit;
  let listContext;

  beforeEach(() => {
    vi.useFakeTimers();
    vi.setSystemTime(0);
    state = { allCount: 30 };
    commit = (type, payload) => mutations[type](state, payload);
    listContext = {
      commit: vi.fn(),
      dispatch: vi.fn((type, payload) => {
        if (type.startsWith('conversationStats/')) {
          return actions[type.split('/')[1]]({ commit, state }, payload);
        }
        return undefined;
      }),
      state: { conversationFilters: { status: 'open', page: 1 } },
    };
  });

  afterEach(() => {
    vi.clearAllTimers();
    vi.useRealTimers();
  });

  it('does not send a queued open-count request after filtered counts arrive', async () => {
    axios.get.mockResolvedValue({ data: { meta: { all_count: 30 } } });
    actions.get({ commit, state }, { status: 'open' });
    expect(axios.get).not.toHaveBeenCalled();

    axios.post.mockResolvedValue({
      data: { payload: [], meta: { all_count: 10757 } },
    });
    await conversationActions.fetchFilteredConversations(listContext, {
      queryData: {
        payload: [
          {
            attribute_key: 'status',
            filter_operator: 'equal_to',
            values: ['all'],
          },
        ],
      },
      page: 1,
    });
    await vi.runAllTimersAsync();

    expect(axios.get).not.toHaveBeenCalled();
    expect(state.allCount).toBe(10757);
  });

  it('ignores an in-flight open-count response after filtered counts arrive', async () => {
    let resolveResponse;
    axios.get.mockReturnValue(
      new Promise(resolve => {
        resolveResponse = resolve;
      })
    );
    actions.get({ commit, state }, { status: 'open' });
    await vi.runAllTimersAsync();
    expect(axios.get).toHaveBeenCalledOnce();

    axios.post.mockResolvedValue({
      data: { payload: [], meta: { all_count: 10757 } },
    });
    await conversationActions.fetchFilteredConversations(listContext, {
      queryData: {
        payload: [
          {
            attribute_key: 'status',
            filter_operator: 'equal_to',
            values: ['all'],
          },
        ],
      },
      page: 1,
    });
    resolveResponse({ data: { meta: { all_count: 30 } } });
    await vi.runAllTimersAsync();

    expect(state.allCount).toBe(10757);
  });

  it('continues refreshing counts after a list response', async () => {
    actions.set({ commit }, { all_count: 30 });
    axios.get.mockResolvedValue({ data: { meta: { all_count: 31 } } });
    actions.get({ commit, state }, { status: 'open' });
    await vi.runAllTimersAsync();

    expect(state.allCount).toBe(31);
  });

  it.each([1, 2])(
    'preserves an event refresh queued while list page %s is in flight',
    async page => {
      let resolveList;
      axios.get.mockReturnValueOnce(
        new Promise(resolve => {
          resolveList = resolve;
        })
      );
      listContext.state.conversationFilters.page = page;
      const listRequest =
        conversationActions.fetchAllConversations(listContext);

      axios.get.mockResolvedValue({ data: { meta: { all_count: 31 } } });
      actions.get({ commit, state }, { status: 'open' });
      resolveList({ data: { data: { payload: [], meta: { all_count: 30 } } } });
      await listRequest;
      await vi.runAllTimersAsync();

      expect(axios.get).toHaveBeenCalledTimes(2);
      expect(state.allCount).toBe(31);
    }
  );
});
