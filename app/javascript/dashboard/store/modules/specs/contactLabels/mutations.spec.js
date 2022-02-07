import * as types from '../../../mutation-types';
import { mutations } from '../../contactLabels';

describe('#mutations', () => {
  describe('#SET_CONTACT_LABELS_UI_FLAG', () => {
    it('set ui flags', () => {
      const state = { uiFlags: { isFetching: true } };
      mutations[types.default.SET_CONTACT_LABELS_UI_FLAG](state, {
        isFetching: false,
      });
      expect(state.uiFlags).toEqual({
        isFetching: false,
      });
    });
  });

  describe('#SET_CONTACT_LABELS', () => {
    it('set contact labels', () => {
      const state = { records: {} };
      mutations[types.default.SET_CONTACT_LABELS](state, {
        id: 1,
        data: ['customer-success', 'on-hold'],
      });
      expect(state.records).toEqual({
        1: ['customer-success', 'on-hold'],
      });
    });
  });
});
