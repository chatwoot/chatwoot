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
        [types.default.SET_INTEGRATIONS_UI_FLAG, { isFetching: true }],
        [types.default.SET_INTEGRATIONS, integrationsList.payload],
        [types.default.SET_INTEGRATIONS_UI_FLAG, { isFetching: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });
      await actions.get({ commit });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_INTEGRATIONS_UI_FLAG, { isFetching: true }],
        [types.default.SET_INTEGRATIONS_UI_FLAG, { isFetching: false }],
      ]);
    });
  });

  describe('#connectSlack:', () => {
    it('sends correct actions if API is success', async () => {
      let data = { id: 'slack', enabled: true };
      axios.post.mockResolvedValue({ data: data });
      await actions.connectSlack({ commit });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_INTEGRATIONS_UI_FLAG, { isUpdating: true }],
        [types.default.ADD_INTEGRATION, data],
        [types.default.SET_INTEGRATIONS_UI_FLAG, { isUpdating: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.post.mockRejectedValue({ message: 'Incorrect header' });
      await actions.connectSlack({ commit });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_INTEGRATIONS_UI_FLAG, { isUpdating: true }],
        [types.default.SET_INTEGRATIONS_UI_FLAG, { isUpdating: false }],
      ]);
    });
  });

  describe('#deleteIntegration:', () => {
    it('sends correct actions if API is success', async () => {
      let data = { id: 'slack', enabled: false };
      axios.delete.mockResolvedValue({ data: data });
      await actions.deleteIntegration({ commit }, data.id);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_INTEGRATIONS_UI_FLAG, { isDeleting: true }],
        [types.default.DELETE_INTEGRATION, data],
        [types.default.SET_INTEGRATIONS_UI_FLAG, { isDeleting: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.delete.mockRejectedValue({ message: 'Incorrect header' });
      await actions.deleteIntegration({ commit });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_INTEGRATIONS_UI_FLAG, { isDeleting: true }],
        [types.default.SET_INTEGRATIONS_UI_FLAG, { isDeleting: false }],
      ]);
    });
  });
});
