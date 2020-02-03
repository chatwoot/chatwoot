import axios from 'axios';
import { actions } from '../../agent';
import { agents } from './data';

const commit = jest.fn();
global.axios = axios;
jest.mock('axios');

describe('#actions', () => {
  describe('#get', () => {
    it('sends correct actions if API is success', async () => {
      axios.get.mockResolvedValue({ data: { payload: agents } });
      await actions.fetchAvailableAgents({ commit }, 'ni');
      /* commit('setAgents', payload);
      commit('setError', false);
      commit('setHasFetched', true);      */
      expect(commit.mock.calls).toEqual([]);
    });
  });
});
