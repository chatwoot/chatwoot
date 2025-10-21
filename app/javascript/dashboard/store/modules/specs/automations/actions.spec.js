import axios from 'axios';
import { actions } from '../../automations';
import * as types from '../../../mutation-types';
import automationsList from './fixtures';

const commit = vi.fn();
global.axios = axios;
vi.mock('axios');

describe('#actions', () => {
  describe('#get', () => {
    it('sends correct actions if API is success', async () => {
      axios.get.mockResolvedValue({ data: { payload: automationsList } });
      await actions.get({ commit });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_AUTOMATION_UI_FLAG, { isFetching: true }],
        [types.default.SET_AUTOMATIONS, automationsList],
        [types.default.SET_AUTOMATION_UI_FLAG, { isFetching: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });
      await actions.get({ commit });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_AUTOMATION_UI_FLAG, { isFetching: true }],
        [types.default.SET_AUTOMATION_UI_FLAG, { isFetching: false }],
      ]);
    });
  });

  describe('#create', () => {
    it('sends correct actions if API is success', async () => {
      axios.post.mockResolvedValue({ data: automationsList[0] });
      await actions.create({ commit }, automationsList[0]);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_AUTOMATION_UI_FLAG, { isCreating: true }],
        [types.default.ADD_AUTOMATION, automationsList[0]],
        [types.default.SET_AUTOMATION_UI_FLAG, { isCreating: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.post.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.create({ commit })).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_AUTOMATION_UI_FLAG, { isCreating: true }],
        [types.default.SET_AUTOMATION_UI_FLAG, { isCreating: false }],
      ]);
    });
  });

  describe('#update', () => {
    it('sends correct actions if API is success', async () => {
      axios.patch.mockResolvedValue({
        data: { payload: automationsList[0] },
      });
      await actions.update({ commit }, automationsList[0]);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_AUTOMATION_UI_FLAG, { isUpdating: true }],
        [types.default.EDIT_AUTOMATION, automationsList[0]],
        [types.default.SET_AUTOMATION_UI_FLAG, { isUpdating: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.patch.mockRejectedValue({ message: 'Incorrect header' });
      await expect(
        actions.update({ commit }, automationsList[0])
      ).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_AUTOMATION_UI_FLAG, { isUpdating: true }],
        [types.default.SET_AUTOMATION_UI_FLAG, { isUpdating: false }],
      ]);
    });
  });

  describe('#delete', () => {
    it('sends correct actions if API is success', async () => {
      axios.delete.mockResolvedValue({ data: automationsList[0] });
      await actions.delete({ commit }, automationsList[0].id);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_AUTOMATION_UI_FLAG, { isDeleting: true }],
        [types.default.DELETE_AUTOMATION, automationsList[0].id],
        [types.default.SET_AUTOMATION_UI_FLAG, { isDeleting: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.delete.mockRejectedValue({ message: 'Incorrect header' });
      await expect(
        actions.delete({ commit }, automationsList[0].id)
      ).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_AUTOMATION_UI_FLAG, { isDeleting: true }],
        [types.default.SET_AUTOMATION_UI_FLAG, { isDeleting: false }],
      ]);
    });
  });

  describe('#clone', () => {
    it('clones the automation', async () => {
      axios.post.mockResolvedValue({ data: automationsList[0] });
      await actions.clone({ commit }, automationsList[0]);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_AUTOMATION_UI_FLAG, { isCloning: true }],
        [types.default.SET_AUTOMATION_UI_FLAG, { isCloning: false }],
      ]);
    });
  });
});
