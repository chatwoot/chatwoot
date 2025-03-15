import { mutations } from '../../campaign';
import { campaigns } from './data';
vi.mock('widget/store/index.js', () => ({
  default: {},
}));

describe('#mutations', () => {
  describe('#setCampaigns', () => {
    it('set campaign records', () => {
      const state = { records: [], uiFlags: {} };
      mutations.setCampaigns(state, campaigns);
      expect(state.records).toEqual(campaigns);
      expect(state.uiFlags.hasFetched).toEqual(true);
    });
  });

  describe('#setError', () => {
    it('set error flag', () => {
      const state = { records: [], uiFlags: {} };
      mutations.setError(state, true);
      expect(state.uiFlags.isError).toEqual(true);
    });
  });

  describe('#setActiveCampaign', () => {
    it('set active campaign', () => {
      const state = { records: [] };
      mutations.setActiveCampaign(state, campaigns[0]);
      expect(state.activeCampaign).toEqual(campaigns[0]);
    });
  });

  describe('#setCampaignExecuted', () => {
    it('set campaign executed flag', () => {
      const state = { records: [], uiFlags: {}, campaignHasExecuted: false };
      mutations.setCampaignExecuted(state, true);
      expect(state.campaignHasExecuted).toEqual(true);
    });
  });
});
