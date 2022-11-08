import types from '../../../mutation-types';
import { mutations } from '../../conversationWatchers';

describe('#mutations', () => {
  describe('#SET_CONVERSATION_WATCHERS', () => {
    it('sets an individual record', () => {
      let state = {
        records: {},
      };

      mutations[types.SET_CONVERSATION_WATCHERS](state, {
        data: [],
        conversationId: 1,
      });
      expect(state.records).toEqual({ 1: [] });
    });
  });

  describe('#SET_CONVERSATION_WATCHERS_UI_FLAG', () => {
    it('set ui flags', () => {
      let state = {
        uiFlags: {
          isFetching: true,
          isUpdating: false,
        },
      };

      mutations[types.SET_CONVERSATION_WATCHERS_UI_FLAG](state, {
        isFetching: false,
      });
      expect(state.uiFlags).toEqual({
        isFetching: false,
        isUpdating: false,
      });
    });
  });
});
