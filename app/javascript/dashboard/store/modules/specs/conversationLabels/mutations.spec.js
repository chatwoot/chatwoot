import * as types from '../../../mutation-types';
import { mutations } from '../../conversationLabels';

describe('#mutations', () => {
  describe('#SET_CONVERSATION_LABELS_UI_FLAG', () => {
    it('set ui flags', () => {
      const state = { uiFlags: { isFetching: true } };
      mutations[types.default.SET_CONVERSATION_LABELS_UI_FLAG](state, {
        isFetching: false,
      });
      expect(state.uiFlags).toEqual({
        isFetching: false,
      });
    });
  });

  describe('#SET_CONVERSATION_LABELS', () => {
    it('set contact conversation records', () => {
      const state = { records: {} };
      mutations[types.default.SET_CONVERSATION_LABELS](state, {
        id: 1,
        data: ['customer-success', 'on-hold'],
      });
      expect(state.records).toEqual({
        1: ['customer-success', 'on-hold'],
      });
    });
  });
});
