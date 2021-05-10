import { API } from 'widget/helpers/axios';
import { actions } from '../../campaign';
import { campaigns } from './data';

const commit = jest.fn();
jest.mock('widget/helpers/axios');

describe('#actions', () => {
  describe('#fetchCampaigns', () => {
    it('sends correct actions if API is success', async () => {
      API.get.mockResolvedValue({ data: campaigns });
      await actions.fetchCampaigns({ commit }, 'XDsafmADasd');
      expect(commit.mock.calls).toEqual([
        ['setCampaigns', campaigns],
        ['setError', false],
        ['setHasFetched', true],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      API.get.mockRejectedValue({ message: 'Authentication required' });
      await actions.fetchCampaigns({ commit }, 'XDsafmADasd');
      expect(commit.mock.calls).toEqual([
        ['setError', true],
        ['setHasFetched', true],
      ]);
    });
  });
});
