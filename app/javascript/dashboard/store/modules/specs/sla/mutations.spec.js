import types from '../../../mutation-types';
import { mutations } from '../../sla';
import SLAs from './fixtures';

describe('#mutations', () => {
  describe('#SET_SLA_UI_FLAG', () => {
    it('set sla ui flags', () => {
      const state = { uiFlags: {} };
      mutations[types.SET_SLA_UI_FLAG](state, { isFetching: true });
      expect(state.uiFlags).toEqual({ isFetching: true });
    });
  });
  describe('#SET_SLA', () => {
    it('set sla records', () => {
      const state = { records: [] };
      mutations[types.SET_SLA](state, SLAs);
      expect(state.records).toEqual(SLAs);
    });
  });
  describe('#ADD_SLA', () => {
    it('push newly created sla to the store', () => {
      const state = { records: [SLAs[0]] };
      mutations[types.ADD_SLA](state, SLAs[1]);
      expect(state.records).toEqual([SLAs[0], SLAs[1]]);
    });
  });
  describe('#DELETE_SLA', () => {
    it('delete sla record', () => {
      const state = { records: [SLAs[0]] };
      mutations[types.DELETE_SLA](state, 1);
      expect(state.records).toEqual([]);
    });
  });
});
