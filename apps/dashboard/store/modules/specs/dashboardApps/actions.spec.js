import axios from 'axios';
import { actions } from '../../dashboardApps';
import types from '../../../mutation-types';
import { payload, automationsList } from './fixtures';
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

  describe('#create', () => {
    it('sends correct actions if API is success', async () => {
      axios.post.mockResolvedValue({ data: payload });
      await actions.create({ commit }, payload);
      expect(commit.mock.calls).toEqual([
        [types.SET_DASHBOARD_APPS_UI_FLAG, { isCreating: true }],
        [types.CREATE_DASHBOARD_APP, payload],
        [types.SET_DASHBOARD_APPS_UI_FLAG, { isCreating: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.post.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.create({ commit })).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.SET_DASHBOARD_APPS_UI_FLAG, { isCreating: true }],
        [types.SET_DASHBOARD_APPS_UI_FLAG, { isCreating: false }],
      ]);
    });
  });

  describe('#update', () => {
    it('sends correct actions if API is success', async () => {
      axios.patch.mockResolvedValue({ data: automationsList[0] });
      await actions.update({ commit }, automationsList[0]);
      expect(commit.mock.calls).toEqual([
        [types.SET_DASHBOARD_APPS_UI_FLAG, { isUpdating: true }],
        [types.EDIT_DASHBOARD_APP, automationsList[0]],
        [types.SET_DASHBOARD_APPS_UI_FLAG, { isUpdating: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.patch.mockRejectedValue({ message: 'Incorrect header' });
      await expect(
        actions.update({ commit }, automationsList[0])
      ).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.SET_DASHBOARD_APPS_UI_FLAG, { isUpdating: true }],
        [types.SET_DASHBOARD_APPS_UI_FLAG, { isUpdating: false }],
      ]);
    });
  });

  describe('#delete', () => {
    it('sends correct actions if API is success', async () => {
      axios.delete.mockResolvedValue({ data: automationsList[0] });
      await actions.delete({ commit }, automationsList[0].id);
      expect(commit.mock.calls).toEqual([
        [types.SET_DASHBOARD_APPS_UI_FLAG, { isDeleting: true }],
        [types.DELETE_DASHBOARD_APP, automationsList[0].id],
        [types.SET_DASHBOARD_APPS_UI_FLAG, { isDeleting: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.delete.mockRejectedValue({ message: 'Incorrect header' });
      await expect(
        actions.delete({ commit }, automationsList[0].id)
      ).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.SET_DASHBOARD_APPS_UI_FLAG, { isDeleting: true }],
        [types.SET_DASHBOARD_APPS_UI_FLAG, { isDeleting: false }],
      ]);
    });
  });
});
