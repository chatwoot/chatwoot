import axios from 'axios';
import { actions } from '../../integrations';
import * as types from '../../../mutation-types';
import integrationsList from './fixtures';

const commit = jest.fn();
global.axios = axios;
jest.mock('axios');

describe('#actions', () => {
  describe('#get', () => {
    it('sends correct actions if API is success', async () => {
      axios.get.mockResolvedValue({ data: integrationsList });
      await actions.get({ commit });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_AGENT_FETCHING_STATUS, true],
        [types.default.SET_AGENT_FETCHING_STATUS, false],
        [types.default.SET_AGENTS, integrationsList],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });
      await actions.get({ commit });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_INTEGRATIONS_FETCHING_STATUS, true],
        [types.default.SET_INTEGRATIONS_FETCHING_STATUS, false],
      ]);
    });
  });
});
