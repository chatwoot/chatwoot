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
    it('set contact labels', () => {
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

  describe('#SET_BULK_CONVERSATION_LABELS', () => {
    it('set contact labels in bulk', () => {
      const state = { records: {} };
      mutations[types.default.SET_BULK_CONVERSATION_LABELS](state, [
        {
          id: 1,
          labels: ['customer-success', 'on-hold'],
        },
        {
          id: 2,
          labels: ['customer-success'],
        },
      ]);
      expect(state.records).toEqual({
        1: ['customer-success', 'on-hold'],
        2: ['customer-success'],
      });
    });
  });
});
