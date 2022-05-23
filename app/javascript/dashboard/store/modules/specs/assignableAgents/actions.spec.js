import axios from 'axios';
import { actions, types } from '../../assignableAgents';
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
        [types.CLEAR_ASSIGNABLE_AGENTS],
        [types.SET_ASSIGNABLE_AGENTS_UI_FLAGS, { isFetching: true }],
        [types.SET_ASSIGNABLE_AGENTS, agentsData],
        [types.SET_ASSIGNABLE_AGENTS_UI_FLAGS, { isFetching: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.fetch({ commit }, [1])).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.CLEAR_ASSIGNABLE_AGENTS],
        [types.SET_ASSIGNABLE_AGENTS_UI_FLAGS, { isFetching: true }],
        [types.SET_ASSIGNABLE_AGENTS_UI_FLAGS, { isFetching: false }],
      ]);
    });
  });
});
