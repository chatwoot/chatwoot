import axios from 'axios';
import { actions } from '../../dashboardApps';
import types from '../../../mutation-types';

const commit = jest.fn();
global.axios = axios;
jest.mock('axios');

describe('#actions', () => {
  describe('#get', () => {
    it('sends correct actions if API is success', async () => {
      axios.get.mockResolvedValue({ data: [{ title: 'Title 1' }] });
      await actions.get({ commit });
      expect(commit.mock.calls).toEqual([
        [types.SET_DASHBOARD_APPS_UI_FLAG, { isFetching: true }],
        [types.SET_DASHBOARD_APPS, [{ title: 'Title 1' }]],
        [types.SET_DASHBOARD_APPS_UI_FLAG, { isFetching: false }],
      ]);
    });
  });
});
