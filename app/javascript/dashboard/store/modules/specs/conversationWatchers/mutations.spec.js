import types from '../../../mutation-types';
import { mutations } from '../../conversationWatchers';
import watchersData from './fixtures';

describe('#mutations', () => {
  describe('#SET_CONVERSATION_WATCHERS', () => {
    it('sets an individual record', () => {
      const state = { records: {} };

      mutations[types.SET_CONVERSATION_WATCHERS](state, {
        data: watchersData,
        conversationId: 1,
      });
      expect(state.records).toEqual({ 1: watchersData });
    });
  });

  describe('#SET_CONVERSATION_WATCHERS_UI_FLAG', () => {
    it('set ui flags', () => {
      const state = { uiFlags: { isFetching: true } };

      mutations[types.SET_CONVERSATION_WATCHERS_UI_FLAG](state, {
        isFetching: false,
      });
      expect(state.uiFlags).toEqual({
        isFetching: false,
      });
    });
  });
});
