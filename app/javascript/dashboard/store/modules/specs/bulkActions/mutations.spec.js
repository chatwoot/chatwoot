import types from '../../../mutation-types';
import { mutations } from '../../bulkActions';

describe('#mutations', () => {
  describe('#toggleUiFlag', () => {
    it('set update flags', () => {
      const state = { uiFlags: { isUpdating: false } };
      mutations[types.SET_BULK_ACTIONS_FLAG](state, { isUpdating: true });
      expect(state.uiFlags.isUpdating).toEqual(true);
    });
  });
});
