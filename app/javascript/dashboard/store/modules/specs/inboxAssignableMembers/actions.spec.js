import axios from 'axios';
import { actions, types } from '../../inboxAssignableAgents';
import agentsData from './fixtures';

const commit = jest.fn();
global.axios = axios;
jest.mock('axios');

describe('#actions', () => {
  describe('#fetch', () => {
    it('sends correct actions if API is success', async () => {
      axios.get.mockResolvedValue({
        data: { payload: agentsData },
      });
      await actions.fetch({ commit }, [1]);
      expect(commit.mock.calls).toEqual([
        [types.SET_INBOX_ASSIGNABLE_AGENTS_UI_FLAG, { isFetching: true }],
        [
          types.SET_INBOX_ASSIGNABLE_AGENTS,
          { inboxId: '1', members: agentsData },
        ],
        [types.SET_INBOX_ASSIGNABLE_AGENTS_UI_FLAG, { isFetching: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.fetch({ commit }, { inboxId: 1 })).rejects.toThrow(
        Error
      );
      expect(commit.mock.calls).toEqual([
        [types.SET_INBOX_ASSIGNABLE_AGENTS_UI_FLAG, { isFetching: true }],
        [types.SET_INBOX_ASSIGNABLE_AGENTS_UI_FLAG, { isFetching: false }],
      ]);
    });
  });
});
