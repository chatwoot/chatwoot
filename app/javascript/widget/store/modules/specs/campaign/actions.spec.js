import { API } from 'widget/helpers/axios';
import { actions } from '../../campaign';
import { campaigns } from './data';

const commit = jest.fn();
const dispatch = jest.fn();
jest.mock('widget/helpers/axios');

import campaignTimer from 'widget/helpers/campaignTimer';
jest.mock('widget/helpers/campaignTimer');

describe('#actions', () => {
  describe('#fetchCampaigns', () => {
    it('sends correct actions if API is success', async () => {
      API.get.mockResolvedValue({ data: campaigns });
      await actions.fetchCampaigns(
        { commit },
        {
          websiteToken: 'XDsafmADasd',
          currentURL: 'https://chatwoot.com',
          isInBusinessHours: true,
        }
      );
      expect(commit.mock.calls).toEqual([
        ['setCampaigns', campaigns],
        ['setError', false],
        ['setHasFetched', true],
      ]);
      expect(campaignTimer.initTimers).toHaveBeenCalledWith(
        {
          campaigns: [
            {
              id: 11,
              timeOnPage: '20',
              url: 'https://chatwoot.com',
              triggerOnlyDuringBusinessHours: false,
            },
          ],
        },
        'XDsafmADasd'
      );
    });
    it('sends correct actions if API is error', async () => {
      API.get.mockRejectedValue({ message: 'Authentication required' });
      await actions.fetchCampaigns(
        { commit },
        {
          websiteToken: 'XDsafmADasd',
          currentURL: 'https://www.chatwoot.com',
          isInBusinessHours: true,
        }
      );
      expect(commit.mock.calls).toEqual([
        ['setError', true],
        ['setHasFetched', true],
      ]);
    });
  });
  describe('#initCampaigns', () => {
    const actionParams = {
      websiteToken: 'XDsafmADasd',
      currentURL: 'https://chatwoot.com',
    };
    it('sends correct actions if campaigns are empty', async () => {
      await actions.initCampaigns(
        { dispatch, getters: { getCampaigns: [] } },
        actionParams
      );
      expect(dispatch.mock.calls).toEqual([['fetchCampaigns', actionParams]]);
      expect(campaignTimer.initTimers).not.toHaveBeenCalled();
    });
    it('resets time if campaigns are available', async () => {
      await actions.initCampaigns(
        { dispatch, getters: { getCampaigns: campaigns } },
        actionParams
      );
      expect(dispatch.mock.calls).toEqual([]);
      expect(campaignTimer.initTimers).toHaveBeenCalledWith(
        {
          campaigns: [
            {
              id: 11,
              timeOnPage: '20',
              url: 'https://chatwoot.com',
              triggerOnlyDuringBusinessHours: false,
            },
          ],
        },
        'XDsafmADasd'
      );
    });
  });
  describe('#startCampaign', () => {
    it('reset campaign if campaign id is not present in the campaign list', async () => {
      API.get.mockResolvedValue({ data: campaigns });
      await actions.startCampaign(
        { dispatch, getters: { getCampaigns: campaigns }, commit },
        { campaignId: 32 }
      );
    });
    it('start campaign if campaign id passed', async () => {
      API.get.mockResolvedValue({ data: campaigns });
      await actions.startCampaign(
        { dispatch, getters: { getCampaigns: campaigns }, commit },
        { campaignId: 1 }
      );
      expect(commit.mock.calls).toEqual([['setActiveCampaign', campaigns[0]]]);
    });
  });
  describe('#executeCampaign', () => {
    it('sends correct actions if  execute campaign API is success', async () => {
      const params = { campaignId: 12, websiteToken: 'XDsafmADasd' };
      API.post.mockResolvedValue({});
      await actions.executeCampaign({ commit }, params);
      expect(commit.mock.calls).toEqual([['setActiveCampaign', {}]]);
    });
    it('sends correct actions if  execute campaign API is failed', async () => {
      const params = { campaignId: 12, websiteToken: 'XDsafmADasd' };
      API.post.mockRejectedValue({ message: 'Authentication required' });
      await actions.executeCampaign({ commit }, params);
      expect(commit.mock.calls).toEqual([['setError', true]]);
    });
  });
});
