import axios from 'axios';
import { actions, mutations } from '../../conversationStats';

vi.mock('axios');
global.axios = axios;

describe('conversation count refresh races', () => {
  let state;
  let commit;

  beforeEach(() => {
    vi.useFakeTimers();
    vi.setSystemTime(0);
    state = { allCount: 30 };
    commit = (type, payload) => mutations[type](state, payload);
  });

  afterEach(() => {
    vi.clearAllTimers();
    vi.useRealTimers();
  });

  it('does not send a queued open-count request after filtered counts arrive', async () => {
    axios.get.mockResolvedValue({ data: { meta: { all_count: 30 } } });
    actions.get({ commit, state }, { status: 'open' });
    expect(axios.get).not.toHaveBeenCalled();

    actions.set({ commit }, { all_count: 10757 });
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

    actions.set({ commit }, { all_count: 10757 });
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
});
