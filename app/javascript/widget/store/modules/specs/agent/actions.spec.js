import { actions } from '../../agent';
import { agents } from './data';
import { getFromCache, setCache } from 'shared/helpers/cache';
import { getAvailableAgents } from 'widget/api/agent';

let commit = vi.fn();
vi.mock('widget/helpers/axios');

vi.mock('widget/api/agent');
vi.mock('shared/helpers/cache');

describe('#actions', () => {
  describe('#fetchAvailableAgents', () => {
    const websiteToken = 'test-token';

    beforeEach(() => {
      commit = vi.fn();
      vi.clearAllMocks();
    });

    it('returns cached data if available', async () => {
      getFromCache.mockReturnValue(agents);
      await actions.fetchAvailableAgents({ commit }, websiteToken);

      expect(getFromCache).toHaveBeenCalledWith(
        `chatwoot_available_agents_${websiteToken}`
      );
      expect(getAvailableAgents).not.toHaveBeenCalled();
      expect(setCache).not.toHaveBeenCalled();
      expect(commit).toHaveBeenCalledWith('setAgents', agents);
      expect(commit).toHaveBeenCalledWith('setError', false);
      expect(commit).toHaveBeenCalledWith('setHasFetched', true);
    });

    it('fetches and caches data if no cache available', async () => {
      getFromCache.mockReturnValue(null);
      getAvailableAgents.mockReturnValue({ data: { payload: agents } });

      await actions.fetchAvailableAgents({ commit }, websiteToken);

      expect(getFromCache).toHaveBeenCalledWith(
        `chatwoot_available_agents_${websiteToken}`
      );
      expect(getAvailableAgents).toHaveBeenCalledWith(websiteToken);
      expect(setCache).toHaveBeenCalledWith(
        `chatwoot_available_agents_${websiteToken}`,
        agents
      );
      expect(commit).toHaveBeenCalledWith('setAgents', agents);
      expect(commit).toHaveBeenCalledWith('setError', false);
      expect(commit).toHaveBeenCalledWith('setHasFetched', true);
    });

    it('sends correct actions if API is success', async () => {
      getFromCache.mockReturnValue(null);

      getAvailableAgents.mockReturnValue({ data: { payload: agents } });
      await actions.fetchAvailableAgents({ commit }, 'Hi');
      expect(commit.mock.calls).toEqual([
        ['setAgents', agents],
        ['setError', false],
        ['setHasFetched', true],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      getFromCache.mockReturnValue(null);

      getAvailableAgents.mockRejectedValue({
        message: 'Authentication required',
      });
      await actions.fetchAvailableAgents({ commit }, 'Hi');
      expect(commit.mock.calls).toEqual([
        ['setError', true],
        ['setHasFetched', true],
      ]);
    });
  });

  describe('#updatePresence', () => {
    it('commits the correct presence value', () => {
      actions.updatePresence({ commit }, { 1: 'online' });
      expect(commit.mock.calls).toEqual([['updatePresence', { 1: 'online' }]]);
    });
  });
});
