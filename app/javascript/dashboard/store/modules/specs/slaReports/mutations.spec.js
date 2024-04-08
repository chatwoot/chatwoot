import { mutations } from '../../SLAReports';
import appliedSlas from './fixtures';
import types from '../../../mutation-types';

describe('#mutations', () => {
  describe('#SET_SLA_REPORTS', () => {
    it('Adds sla reports', () => {
      const state = { records: {} };
      mutations[types.SET_SLA_REPORTS](state, appliedSlas);
      expect(state.records).toEqual(appliedSlas);
    });
  });

  describe('#SET_SLA_REPORTS_UI_FLAG', () => {
    it('set ui flags', () => {
      const state = { uiFlags: {} };
      mutations[types.SET_SLA_REPORTS_UI_FLAG](state, { isFetching: true });
      expect(state.uiFlags).toEqual({ isFetching: true });
    });
  });

  describe('#SET_SLA_REPORTS_METRICS', () => {
    it('set metrics', () => {
      const state = { metrics: {} };
      mutations[types.SET_SLA_REPORTS_METRICS](state, {
        number_of_sla_misses: 1,
        hit_rate: '100%',
        total_applied_slas: 1,
      });
      expect(state.metrics).toEqual({
        numberOfSLAMisses: 1,
        hitRate: '100%',
        numberOfConversations: 1,
      });
    });
  });

  describe('#SET_SLA_REPORTS_META', () => {
    it('set meta', () => {
      const state = { meta: {} };
      mutations[types.SET_SLA_REPORTS_META](state, {
        count: 1,
        current_page: 1,
      });
      expect(state.meta).toEqual({
        count: 1,
        currentPage: 1,
      });
    });
  });
});
