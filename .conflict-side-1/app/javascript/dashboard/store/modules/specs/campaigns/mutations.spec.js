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
  describe('#EDIT_CAMPAIGN', () => {
    it('update campaign record', () => {
      const state = { records: [campaigns[0]] };
      mutations[types.EDIT_CAMPAIGN](state, {
        id: 1,
        title: 'Welcome',
        account_id: 1,
        message: 'Hey, What brings you today',
      });
      expect(state.records[0].message).toEqual('Hey, What brings you today');
    });
  });

  describe('#DELETE_LABEL', () => {
    it('delete campaign record', () => {
      const state = { records: [campaigns[0]] };
      mutations[types.DELETE_CAMPAIGN](state, 1);
      expect(state.records).toEqual([]);
    });
  });
});
