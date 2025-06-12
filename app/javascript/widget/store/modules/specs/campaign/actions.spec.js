import { API } from 'widget/helpers/axios';
import { actions } from '../../campaign';
import { campaigns } from './data';
import { getFromCache, setCache } from 'shared/helpers/cache';

const commit = vi.fn();
const dispatch = vi.fn();
vi.mock('widget/helpers/axios');
vi.mock('shared/helpers/cache');

import campaignTimer from 'widget/helpers/campaignTimer';
vi.mock('widget/helpers/campaignTimer', () => ({
  default: {
    initTimers: vi.fn().mockReturnValue({ mock: true }),
  },
}));

describe('#actions', () => {
  describe('#fetchCampaigns', () => {
    beforeEach(() => {
      commit.mockClear();
      getFromCache.mockClear();
      setCache.mockClear();
      API.get.mockClear();
      campaignTimer.initTimers.mockClear();
    });

    it('uses cached data when available', async () => {
      getFromCache.mockReturnValue(campaigns);

      await actions.fetchCampaigns(
        { commit },
        {
          websiteToken: 'XDsafmADasd',
          currentURL: 'https://chatwoot.com',
          isInBusinessHours: true,
        }
      );

      expect(getFromCache).toHaveBeenCalledWith(
        'chatwoot_campaigns_XDsafmADasd',
        60 * 60 * 1000
      );
      expect(API.get).not.toHaveBeenCalled();
      expect(setCache).not.toHaveBeenCalled();
      expect(commit.mock.calls).toEqual([
        ['setCampaigns', campaigns],
        ['setError', false],
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

    it('fetches and caches data when cache is not available', async () => {
      getFromCache.mockReturnValue(null);
      API.get.mockResolvedValue({ data: campaigns });

      await actions.fetchCampaigns(
        { commit },
        {
          websiteToken: 'XDsafmADasd',
          currentURL: 'https://chatwoot.com',
          isInBusinessHours: true,
        }
      );

      expect(getFromCache).toHaveBeenCalledWith(
        'chatwoot_campaigns_XDsafmADasd',
        60 * 60 * 1000
      );
      expect(API.get).toHaveBeenCalled();
      expect(setCache).toHaveBeenCalledWith(
        'chatwoot_campaigns_XDsafmADasd',
        campaigns
      );
      expect(commit.mock.calls).toEqual([
        ['setCampaigns', campaigns],
        ['setError', false],
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
      getFromCache.mockReturnValue(null);
      API.get.mockRejectedValue({ message: 'Authentication required' });
      await actions.fetchCampaigns(
        { commit },
        {
          websiteToken: 'XDsafmADasd',
          currentURL: 'https://www.chatwoot.com',
          isInBusinessHours: true,
        }
      );
      expect(commit.mock.calls).toEqual([['setError', true]]);
    });
  });
  describe('#initCampaigns', () => {
    const actionParams = {
      websiteToken: 'XDsafmADasd',
      currentURL: 'https://chatwoot.com',
    };
    it('sends correct actions if campaigns are empty', async () => {
      await actions.initCampaigns(
        {
          dispatch,
          getters: { getCampaigns: [], getUIFlags: { hasFetched: false } },
        },
        actionParams
      );
      expect(dispatch.mock.calls).toEqual([['fetchCampaigns', actionParams]]);
      expect(campaignTimer.initTimers).not.toHaveBeenCalled();
    });

    it('do not refetch if the campaigns are fetched once', async () => {
      await actions.initCampaigns(
        {
          dispatch,
          getters: { getCampaigns: [], getUIFlags: { hasFetched: true } },
        },
        actionParams
      );
      expect(dispatch.mock.calls).toEqual([]);
      expect(campaignTimer.initTimers).not.toHaveBeenCalled();
    });

    it('resets time if campaigns are available', async () => {
      await actions.initCampaigns(
        {
          dispatch,
          getters: {
            getCampaigns: campaigns,
            getUIFlags: { hasFetched: true },
          },
        },
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
        {
          dispatch,
          getters: { getCampaigns: campaigns },
          commit,
          rootState: {
            appConfig: { isWidgetOpen: true },
          },
        },
        { campaignId: 32 }
      );
    });
    it('start campaign if campaign id passed', async () => {
      API.get.mockResolvedValue({ data: campaigns });
      await actions.startCampaign(
        {
          dispatch,
          getters: { getCampaigns: campaigns },
          commit,
          rootState: {
            appConfig: { isWidgetOpen: false },
          },
        },
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
      expect(commit.mock.calls).toEqual([
        [
          'conversation/setConversationUIFlag',
          {
            isCreating: true,
          },
          {
            root: true,
          },
        ],
        ['setCampaignExecuted', true],
        ['setActiveCampaign', {}],
        [
          'conversation/setConversationUIFlag',
          {
            isCreating: false,
          },
          {
            root: true,
          },
        ],
      ]);
    });
    it('sends correct actions if  execute campaign API is failed', async () => {
      const params = { campaignId: 12, websiteToken: 'XDsafmADasd' };
      API.post.mockRejectedValue({ message: 'Authentication required' });
      await actions.executeCampaign({ commit }, params);
      expect(commit.mock.calls).toEqual([
        [
          'conversation/setConversationUIFlag',
          {
            isCreating: true,
          },
          {
            root: true,
          },
        ],
        ['setError', true],
        [
          'conversation/setConversationUIFlag',
          {
            isCreating: false,
          },
          {
            root: true,
          },
        ],
      ]);
    });
  });

  describe('#resetCampaign', () => {
    it('sends correct actions if  execute campaign API is success', async () => {
      API.post.mockResolvedValue({});
      await actions.resetCampaign({ commit });
      expect(commit.mock.calls).toEqual([
        ['setCampaignExecuted', false],
        ['setActiveCampaign', {}],
      ]);
    });
  });
});
