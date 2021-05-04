import types from '../../../mutation-types';
import { mutations } from '../../campaigns';
import campaigns from './fixtures';

describe('#mutations', () => {
  describe('#SET_CAMPAIGNS', () => {
    it('set campaigns records', () => {
      const state = { records: [] };
      mutations[types.SET_CAMPAIGNS](state, campaigns);
      expect(state.records).toEqual(campaigns);
    });
  });

  describe('#ADD_CAMPAIGN', () => {
    it('push newly created campaigns to the store', () => {
      const state = { records: [campaigns[0]] };
      mutations[types.ADD_CAMPAIGN](state, campaigns[1]);
      expect(state.records).toEqual([campaigns[0], campaigns[1]]);
    });
  });
});
