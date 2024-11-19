import axios from 'axios';
import { actions } from '../../customRole';
import * as types from '../../../mutation-types';
import { customRoleList } from './fixtures';

const commit = vi.fn();
global.axios = axios;
vi.mock('axios');

describe('#actions', () => {
  describe('#getCustomRole', () => {
    it('sends correct actions if API is success', async () => {
      axios.get.mockResolvedValue({ data: customRoleList });
      await actions.getCustomRole({ commit });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CUSTOM_ROLE_UI_FLAG, { fetchingList: true }],
        [types.default.SET_CUSTOM_ROLE, customRoleList],
        [types.default.SET_CUSTOM_ROLE_UI_FLAG, { fetchingList: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });
      await actions.getCustomRole({ commit });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CUSTOM_ROLE_UI_FLAG, { fetchingList: true }],
        [types.default.SET_CUSTOM_ROLE_UI_FLAG, { fetchingList: false }],
      ]);
    });
  });

  describe('#createCustomRole', () => {
    it('sends correct actions if API is success', async () => {
      axios.post.mockResolvedValue({ data: customRoleList[0] });
      await actions.createCustomRole({ commit }, customRoleList[0]);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CUSTOM_ROLE_UI_FLAG, { creatingItem: true }],
        [types.default.ADD_CUSTOM_ROLE, customRoleList[0]],
        [types.default.SET_CUSTOM_ROLE_UI_FLAG, { creatingItem: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.post.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.createCustomRole({ commit })).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CUSTOM_ROLE_UI_FLAG, { creatingItem: true }],
        [types.default.SET_CUSTOM_ROLE_UI_FLAG, { creatingItem: false }],
      ]);
    });
  });

  describe('#updateCustomRole', () => {
    it('sends correct actions if API is success', async () => {
      axios.patch.mockResolvedValue({ data: customRoleList[0] });
      await actions.updateCustomRole(
        { commit },
        { id: 1, ...customRoleList[0] }
      );
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CUSTOM_ROLE_UI_FLAG, { updatingItem: true }],
        [types.default.EDIT_CUSTOM_ROLE, customRoleList[0]],
        [types.default.SET_CUSTOM_ROLE_UI_FLAG, { updatingItem: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.patch.mockRejectedValue({ message: 'Incorrect header' });
      await expect(
        actions.updateCustomRole({ commit }, { id: 1 })
      ).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CUSTOM_ROLE_UI_FLAG, { updatingItem: true }],
        [types.default.SET_CUSTOM_ROLE_UI_FLAG, { updatingItem: false }],
      ]);
    });
  });

  describe('#deleteCustomRole', () => {
    it('sends correct actions if API is success', async () => {
      axios.delete.mockResolvedValue({ data: customRoleList[0] });
      await actions.deleteCustomRole({ commit }, 1);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CUSTOM_ROLE_UI_FLAG, { deletingItem: true }],
        [types.default.DELETE_CUSTOM_ROLE, 1],
        [types.default.SET_CUSTOM_ROLE_UI_FLAG, { deletingItem: true }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.delete.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.deleteCustomRole({ commit }, 1)).rejects.toThrow(
        Error
      );
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CUSTOM_ROLE_UI_FLAG, { deletingItem: true }],
        [types.default.SET_CUSTOM_ROLE_UI_FLAG, { deletingItem: true }],
      ]);
    });
  });
});
