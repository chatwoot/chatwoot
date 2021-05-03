import types from '../../../mutation-types';
import campaignStoreModule from '../../campaigns';
import campaigns from './fixtures';
const { mutations } = campaignStoreModule;

describe('#mutations', () => {
  describe('#SET_CAMPAIGNS', () => {
    it('set campaign records', () => {
      const state = { records: [] };
      mutations[types.SET_CAMPAIGNS](state, campaigns);
      expect(state.records).toEqual(campaigns);
    });
  });

  describe('#ADD_CAMPAIGN', () => {
    it('push newly created campaign to the store', () => {
      const state = { records: [campaigns[0]] };
      mutations[types.ADD_CAMPAIGN](state, campaigns[1]);
      expect(state.records).toEqual([campaigns[0], campaigns[1]]);
    });
  });
});
