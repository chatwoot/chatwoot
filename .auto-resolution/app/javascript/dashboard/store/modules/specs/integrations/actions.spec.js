import axios from 'axios';
import { actions } from '../../integrations';
import types from '../../../mutation-types';
import integrationsList from './fixtures';

const commit = vi.fn();
global.axios = axios;
vi.mock('axios');

const errorMessage = { message: 'Incorrect header' };
describe('#actions', () => {
  describe('#get', () => {
    it('sends correct actions if API is success', async () => {
      axios.get.mockResolvedValue({ data: integrationsList });
      await actions.get({ commit });
      expect(commit.mock.calls).toEqual([
        [types.SET_INTEGRATIONS_UI_FLAG, { isFetching: true }],
        [types.SET_INTEGRATIONS, integrationsList.payload],
        [types.SET_INTEGRATIONS_UI_FLAG, { isFetching: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue(errorMessage);
      await actions.get({ commit });
      expect(commit.mock.calls).toEqual([
        [types.SET_INTEGRATIONS_UI_FLAG, { isFetching: true }],
        [types.SET_INTEGRATIONS_UI_FLAG, { isFetching: false }],
      ]);
    });
  });

  describe('#connectSlack:', () => {
    it('sends correct actions if API is success', async () => {
      let data = { hooks: [{ id: 'slack', enabled: false }] };
      axios.post.mockResolvedValue({ data: data });
      await actions.connectSlack({ commit });
      expect(commit.mock.calls).toEqual([
        [types.SET_INTEGRATIONS_UI_FLAG, { isCreatingSlack: true }],
        [types.ADD_INTEGRATION, data],
        [types.SET_INTEGRATIONS_UI_FLAG, { isCreatingSlack: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.post.mockRejectedValue(errorMessage);
      await expect(actions.connectSlack({ commit })).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.SET_INTEGRATIONS_UI_FLAG, { isCreatingSlack: true }],
        [types.SET_INTEGRATIONS_UI_FLAG, { isCreatingSlack: false }],
      ]);
    });
  });

  describe('#updateSlack', () => {
    it('sends correct actions if API is success', async () => {
      let data = { hooks: [{ id: 'slack', enabled: false }] };
      axios.patch.mockResolvedValue({ data: data });
      await actions.updateSlack({ commit }, { referenceId: '12345' });
      expect(commit.mock.calls).toEqual([
        [types.SET_INTEGRATIONS_UI_FLAG, { isUpdatingSlack: true }],
        [types.ADD_INTEGRATION, data],
        [types.SET_INTEGRATIONS_UI_FLAG, { isUpdatingSlack: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.patch.mockRejectedValue(errorMessage);
      await expect(actions.updateSlack({ commit })).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.SET_INTEGRATIONS_UI_FLAG, { isUpdatingSlack: true }],
        [types.SET_INTEGRATIONS_UI_FLAG, { isUpdatingSlack: false }],
      ]);
    });
  });

  describe('#deleteIntegration:', () => {
    it('sends correct actions if API is success', async () => {
      let data = { id: 'slack', enabled: false };
      axios.delete.mockResolvedValue({ data: data });
      await actions.deleteIntegration({ commit }, data.id);
      expect(commit.mock.calls).toEqual([
        [types.SET_INTEGRATIONS_UI_FLAG, { isDeleting: true }],
        [types.DELETE_INTEGRATION, data],
        [types.SET_INTEGRATIONS_UI_FLAG, { isDeleting: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.delete.mockRejectedValue(errorMessage);
      await actions.deleteIntegration({ commit });
      expect(commit.mock.calls).toEqual([
        [types.SET_INTEGRATIONS_UI_FLAG, { isDeleting: true }],
        [types.SET_INTEGRATIONS_UI_FLAG, { isDeleting: false }],
      ]);
    });
  });

  describe('#createHooks', () => {
    it('sends correct actions if API is success', async () => {
      let data = { id: 'slack', enabled: false };
      axios.post.mockResolvedValue({ data: data });
      await actions.createHook({ commit }, data);
      expect(commit.mock.calls).toEqual([
        [types.SET_INTEGRATIONS_UI_FLAG, { isCreatingHook: true }],
        [types.ADD_INTEGRATION_HOOKS, data],
        [types.SET_INTEGRATIONS_UI_FLAG, { isCreatingHook: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.post.mockRejectedValue(errorMessage);
      await expect(actions.createHook({ commit })).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.SET_INTEGRATIONS_UI_FLAG, { isCreatingHook: true }],
        [types.SET_INTEGRATIONS_UI_FLAG, { isCreatingHook: false }],
      ]);
    });
  });

  describe('#deleteHook', () => {
    it('sends correct actions if API is success', async () => {
      let data = { appId: 'dialogflow', hookId: 2 };
      axios.delete.mockResolvedValue({ data });
      await actions.deleteHook({ commit }, data);
      expect(commit.mock.calls).toEqual([
        [types.SET_INTEGRATIONS_UI_FLAG, { isDeletingHook: true }],
        [types.DELETE_INTEGRATION_HOOKS, { appId: 'dialogflow', hookId: 2 }],
        [types.SET_INTEGRATIONS_UI_FLAG, { isDeletingHook: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.delete.mockRejectedValue(errorMessage);
      await expect(actions.deleteHook({ commit }, {})).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.SET_INTEGRATIONS_UI_FLAG, { isDeletingHook: true }],
        [types.SET_INTEGRATIONS_UI_FLAG, { isDeletingHook: false }],
      ]);
    });
  });
});
