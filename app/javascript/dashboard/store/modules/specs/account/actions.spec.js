import axios from 'axios';
import { actions, getters } from '../../accounts';
import * as types from '../../../mutation-types';

const accountData = {
  id: 1,
  name: 'Company one',
  locale: 'en',
};

const newAccountInfo = {
  accountName: 'Company two',
};

const commit = vi.fn();
global.axios = axios;
vi.mock('axios');

describe('#actions', () => {
  describe('#get', () => {
    it('sends correct actions if API is success', async () => {
      axios.get.mockResolvedValue({ data: accountData });
      await actions.get({ commit });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_ACCOUNT_UI_FLAG, { isFetchingItem: true }],
        [types.default.ADD_ACCOUNT, accountData],
        [types.default.SET_ACCOUNT_UI_FLAG, { isFetchingItem: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });
      await actions.get({ commit });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_ACCOUNT_UI_FLAG, { isFetchingItem: true }],
        [types.default.SET_ACCOUNT_UI_FLAG, { isFetchingItem: false }],
      ]);
    });
  });

  describe('#update', () => {
    it('sends correct actions if API is success', async () => {
      axios.patch.mockResolvedValue({
        data: { id: 1, name: 'John' },
      });
      await actions.update({ commit, getters }, accountData);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_ACCOUNT_UI_FLAG, { isUpdating: true }],
        [types.default.EDIT_ACCOUNT, { id: 1, name: 'John' }],
        [types.default.SET_ACCOUNT_UI_FLAG, { isUpdating: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.patch.mockRejectedValue({ message: 'Incorrect header' });
      await expect(
        actions.update({ commit, getters }, accountData)
      ).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_ACCOUNT_UI_FLAG, { isUpdating: true }],
        [types.default.SET_ACCOUNT_UI_FLAG, { isUpdating: false }],
      ]);
    });
  });

  describe('#create', () => {
    it('sends correct actions if API is success', async () => {
      axios.post.mockResolvedValue({
        data: { data: { id: 1, name: 'John' } },
      });
      await actions.create({ commit, getters }, newAccountInfo);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_ACCOUNT_UI_FLAG, { isCreating: true }],
        [types.default.SET_ACCOUNT_UI_FLAG, { isCreating: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.patch.mockRejectedValue({ message: 'Incorrect header' });
      await expect(
        actions.create({ commit, getters }, newAccountInfo)
      ).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_ACCOUNT_UI_FLAG, { isCreating: true }],
        [types.default.SET_ACCOUNT_UI_FLAG, { isCreating: false }],
      ]);
    });
  });

  describe('#toggleDeletion', () => {
    it('sends correct actions with delete action if API is success', async () => {
      axios.post.mockResolvedValue({});
      await actions.toggleDeletion({ commit }, { action_type: 'delete' });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_ACCOUNT_UI_FLAG, { isUpdating: true }],
        [types.default.SET_ACCOUNT_UI_FLAG, { isUpdating: false }],
      ]);
      expect(axios.post.mock.calls[0][1]).toEqual({
        action_type: 'delete',
      });
    });

    it('sends correct actions with undelete action if API is success', async () => {
      axios.post.mockResolvedValue({});
      await actions.toggleDeletion({ commit }, { action_type: 'undelete' });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_ACCOUNT_UI_FLAG, { isUpdating: true }],
        [types.default.SET_ACCOUNT_UI_FLAG, { isUpdating: false }],
      ]);
      expect(axios.post.mock.calls[0][1]).toEqual({
        action_type: 'undelete',
      });
    });

    it('sends correct actions if API is error', async () => {
      axios.post.mockRejectedValue({ message: 'Incorrect header' });
      await expect(
        actions.toggleDeletion({ commit }, { action_type: 'delete' })
      ).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_ACCOUNT_UI_FLAG, { isUpdating: true }],
        [types.default.SET_ACCOUNT_UI_FLAG, { isUpdating: false }],
      ]);
    });
  });
});
