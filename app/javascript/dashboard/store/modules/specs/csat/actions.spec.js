import axios from 'axios';
import { actions } from '../../csat';
import types from '../../../mutation-types';

const commit = vi.fn();
global.axios = axios;
vi.mock('axios');

describe('#actions', () => {
  describe('#get', () => {
    it('sends correct mutations if API is success', async () => {
      axios.get.mockResolvedValue({
        data: [{ id: 1, rating: 1, feedback_text: 'Bad' }],
      });
      await actions.get({ commit }, { page: 1 });
      expect(commit.mock.calls).toEqual([
        [types.SET_CSAT_RESPONSE_UI_FLAG, { isFetching: true }],
        [types.SET_CSAT_RESPONSE, [{ id: 1, rating: 1, feedback_text: 'Bad' }]],
        [types.SET_CSAT_RESPONSE_UI_FLAG, { isFetching: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });
      await actions.get({ commit }, { page: 1 });
      expect(commit.mock.calls).toEqual([
        [types.SET_CSAT_RESPONSE_UI_FLAG, { isFetching: true }],
        [types.SET_CSAT_RESPONSE_UI_FLAG, { isFetching: false }],
      ]);
    });
  });

  describe('#getMetrics', () => {
    it('sends correct mutations if API is success', async () => {
      axios.get.mockResolvedValue({
        data: {
          total_count: 29,
          ratings_count: { 1: 10, 2: 10, 3: 3, 4: 3, 5: 3 },
          total_sent_messages_count: 120,
        },
      });
      await actions.getMetrics({ commit }, { page: 1 });
      expect(commit.mock.calls).toEqual([
        [types.SET_CSAT_RESPONSE_UI_FLAG, { isFetchingMetrics: true }],
        [
          types.SET_CSAT_RESPONSE_METRICS,
          {
            total_count: 29,
            ratings_count: { 1: 10, 2: 10, 3: 3, 4: 3, 5: 3 },
            total_sent_messages_count: 120,
          },
        ],
        [types.SET_CSAT_RESPONSE_UI_FLAG, { isFetchingMetrics: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });
      await actions.getMetrics({ commit }, { page: 1 });
      expect(commit.mock.calls).toEqual([
        [types.SET_CSAT_RESPONSE_UI_FLAG, { isFetchingMetrics: true }],
        [types.SET_CSAT_RESPONSE_UI_FLAG, { isFetchingMetrics: false }],
      ]);
    });
  });
});
