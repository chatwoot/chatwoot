import axios from 'axios';
import { actions } from '../../conversationStats';
import * as types from '../../../mutation-types';

const commit = vi.fn();
global.axios = axios;
vi.mock('axios');

vi.mock('@chatwoot/utils', () => ({
  debounce: vi.fn(fn => {
    return fn;
  }),
}));

describe('#actions', () => {
  beforeEach(() => {
    vi.useFakeTimers(); // Set up fake timers
    commit.mockClear();
  });

  afterEach(() => {
    vi.useRealTimers(); // Reset to real timers after each test
  });

  describe('#get', () => {
    it('sends correct mutations if API is success', async () => {
      axios.get.mockResolvedValue({ data: { meta: { mine_count: 1 } } });
      actions.get(
        { commit, state: { allCount: 0 } },
        { inboxId: 1, assigneeTpe: 'me', status: 'open' }
      );

      await vi.runAllTimersAsync();
      await vi.waitFor(() => expect(commit).toHaveBeenCalled());

      expect(commit.mock.calls).toEqual([
        [types.default.SET_CONV_TAB_META, { mine_count: 1 }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });
      actions.get(
        { commit, state: { allCount: 0 } },
        { inboxId: 1, assigneeTpe: 'me', status: 'open' }
      );
      expect(commit.mock.calls).toEqual([]);
    });
  });

  describe('#set', () => {
    it('sends correct mutations', async () => {
      actions.set(
        { commit },
        { mine_count: 1, unassigned_count: 1, all_count: 2 }
      );
      expect(commit.mock.calls).toEqual([
        [
          types.default.SET_CONV_TAB_META,
          { mine_count: 1, unassigned_count: 1, all_count: 2 },
        ],
      ]);
    });
  });
});
