import * as types from '../../../mutation-types';
import { mutations } from '../../integrations';

describe('#mutations', () => {
  describe('#GET_INTEGRATIONS', () => {
    it('set integrations records', () => {
      const state = { records: [] };
      mutations[types.default.SET_INTEGRATIONS](state, [
        {
          id: 1,
          name: 'test1',
          logo: 'test',
          enabled: true,
        },
      ]);
      expect(state.records).toEqual([
        {
          id: 1,
          name: 'test1',
          logo: 'test',
          enabled: true,
        },
      ]);
    });
  });
});
