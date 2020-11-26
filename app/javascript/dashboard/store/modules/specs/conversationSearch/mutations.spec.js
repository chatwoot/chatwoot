import types from '../../../mutation-types';
import { mutations } from '../../conversationSearch';

describe('#mutations', () => {
  describe('#SEARCH_CONVERSATIONS_SET', () => {
    it('set records correctly', () => {
      const state = { records: [] };
      mutations[types.SEARCH_CONVERSATIONS_SET](state, [{ id: 1 }]);
      expect(state.records).toEqual([{ id: 1 }]);
    });
  });

  describe('#SEARCH_CONVERSATIONS_SET', () => {
    it('set uiFlags correctly', () => {
      const state = { uiFlags: { isFetching: true } };
      mutations[types.SEARCH_CONVERSATIONS_SET_UI_FLAG](state, {
        isFetching: false,
      });
      expect(state.uiFlags).toEqual({ isFetching: false });
    });
  });
});
