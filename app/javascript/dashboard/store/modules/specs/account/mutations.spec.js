import * as types from '../../../mutation-types';
import { mutations } from '../../accounts';

const accountData = {
  id: 1,
  name: 'Company one',
  locale: 'en',
};

describe('#mutations', () => {
  describe('#ADD_ACCOUNT', () => {
    it('push contact data to the store', () => {
      const state = {
        records: [],
      };
      mutations[types.default.ADD_ACCOUNT](state, accountData);
      expect(state.records).toEqual([accountData]);
    });
  });

  describe('#EDIT_ACCOUNT', () => {
    it('update contact', () => {
      const state = {
        records: [{ ...accountData, locale: 'fr' }],
      };
      mutations[types.default.EDIT_ACCOUNT](state, accountData);
      expect(state.records).toEqual([accountData]);
    });
  });
});
