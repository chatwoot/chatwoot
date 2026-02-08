import types from '../../../mutation-types';
import { mutations } from '../../csat';

describe('#mutations', () => {
  describe('#SET_CSAT_RESPONSE_UI_FLAG', () => {
    it('set uiFlags correctly', () => {
      const state = { uiFlags: { isFetching: true } };
      mutations[types.SET_CSAT_RESPONSE_UI_FLAG](state, { isFetching: false });
      expect(state.uiFlags).toEqual({ isFetching: false });
    });
  });

  describe('#SET_CSAT_RESPONSE', () => {
    it('set records correctly', () => {
      const state = { records: [] };
      mutations[types.SET_CSAT_RESPONSE](state, [
        { id: 1, rating: 1, feedback_text: 'Bad' },
      ]);
      expect(state.records).toEqual([
        { id: 1, rating: 1, feedback_text: 'Bad' },
      ]);
    });
  });

  describe('#SET_CSAT_RESPONSE_METRICS', () => {
    it('set metrics correctly', () => {
      const state = { metrics: {} };
      mutations[types.SET_CSAT_RESPONSE_METRICS](state, {
        total_count: 29,
        ratings_count: { 1: 10, 2: 10, 3: 3, 4: 3, 5: 3 },
        total_sent_messages_count: 120,
      });
      expect(state.metrics).toEqual({
        totalResponseCount: 29,
        ratingsCount: { 1: 10, 2: 10, 3: 3, 4: 3, 5: 3 },
        totalSentMessagesCount: 120,
      });
    });

    it('set ratingsCount correctly', () => {
      const state = { metrics: {} };
      mutations[types.SET_CSAT_RESPONSE_METRICS](state, {
        ratings_count: { 1: 5 },
      });
      expect(state.metrics).toEqual({
        totalResponseCount: 0,
        ratingsCount: { 1: 5, 2: 0, 3: 0, 4: 0, 5: 0 },
        totalSentMessagesCount: 0,
      });
    });
  });
});
