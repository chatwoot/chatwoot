import axios from 'axios';
import { actions, types } from '../../inboxAssignableAgents';
import agentsData from './fixtures';

const commit = vi.fn();
global.axios = axios;
vi.mock('axios');

describe('#actions', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('#fetch', () => {
    it('sends correct actions if API is success', async () => {
      axios.get.mockResolvedValue({
        data: { payload: agentsData },
      });
      await actions.fetch({ commit }, [1]);
      expect(axios.get).toHaveBeenCalledWith('/api/v1/assignable_agents', {
        params: {
          inbox_ids: [1],
        },
      });
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
      await expect(actions.fetch({ commit }, [1])).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.SET_INBOX_ASSIGNABLE_AGENTS_UI_FLAG, { isFetching: true }],
        [types.SET_INBOX_ASSIGNABLE_AGENTS_UI_FLAG, { isFetching: false }],
      ]);
    });

    it('requests agent bots only when opted in', async () => {
      axios.get.mockResolvedValue({
        data: { payload: agentsData },
      });

      await actions.fetch(
        { commit },
        { inboxIds: [1], includeAgentBots: true }
      );

      expect(axios.get).toHaveBeenCalledWith('/api/v1/assignable_agents', {
        params: {
          inbox_ids: [1],
          include_agent_bots: true,
        },
      });
      expect(commit).toHaveBeenCalledWith(types.SET_INBOX_ASSIGNABLE_AGENTS, {
        inboxId: '1',
        members: agentsData,
      });
      expect(commit).toHaveBeenCalledWith(types.SET_INBOX_ASSIGNABLE_AGENTS, {
        inboxId: '1:with_agent_bots',
        members: agentsData,
      });
    });
  });
});
