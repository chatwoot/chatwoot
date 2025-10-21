import axios from 'axios';
import { actions } from '../../SLAReports';
import appliedSlas from './fixtures';
import types from '../../../mutation-types';

const commit = vi.fn();
global.axios = axios;
vi.mock('axios');

describe('#actions', () => {
  describe('#get', () => {
    it('sends correct actions if API is success', async () => {
      axios.get.mockResolvedValue({
        data: { payload: appliedSlas, meta: { count: 1 } },
      });
      await actions.get({ commit }, {});
      expect(commit.mock.calls).toEqual([
        [types.SET_SLA_REPORTS_UI_FLAG, { isFetching: true }],
        [types.SET_SLA_REPORTS, appliedSlas],
        [types.SET_SLA_REPORTS_META, { count: 1 }],
        [types.SET_SLA_REPORTS_UI_FLAG, { isFetching: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.get({ commit }, { teamId: 1 })).rejects.toThrow(
        Error
      );
      expect(commit.mock.calls).toEqual([
        [types.SET_SLA_REPORTS_UI_FLAG, { isFetching: true }],
        [types.SET_SLA_REPORTS_UI_FLAG, { isFetching: false }],
      ]);
    });
  });

  describe('#getMetrics', () => {
    it('sends correct actions if API is success', async () => {
      axios.get.mockResolvedValue({ data: { metrics: { count: 1 } } });
      await actions.getMetrics({ commit }, {});
      expect(commit.mock.calls).toEqual([
        [types.SET_SLA_REPORTS_UI_FLAG, { isFetchingMetrics: true }],
        [types.SET_SLA_REPORTS_METRICS, { metrics: { count: 1 } }],
        [types.SET_SLA_REPORTS_UI_FLAG, { isFetchingMetrics: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });
      await actions.getMetrics({ commit }, { teamId: 1 });
      expect(commit.mock.calls).toEqual([
        [types.SET_SLA_REPORTS_UI_FLAG, { isFetchingMetrics: true }],
        [types.SET_SLA_REPORTS_UI_FLAG, { isFetchingMetrics: false }],
      ]);
    });
  });
});
