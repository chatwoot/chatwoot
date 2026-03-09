import axios from 'axios';
import { actions } from '../../customViews';
import * as types from '../../../mutation-types';
import { customViewList, updateCustomViewList } from './fixtures';

const commit = vi.fn();
global.axios = axios;
vi.mock('axios');

describe('#actions', () => {
  describe('#get', () => {
    it('sends correct actions if API is success', async () => {
      axios.get.mockResolvedValue({ data: customViewList });
      await actions.get({ commit }, 'conversation');
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CUSTOM_VIEW_UI_FLAG, { isFetching: true }],
        [
          types.default.SET_CUSTOM_VIEW,
          { data: customViewList, filterType: 'conversation' },
        ],
        [types.default.SET_CUSTOM_VIEW_UI_FLAG, { isFetching: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });
      await actions.get({ commit });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CUSTOM_VIEW_UI_FLAG, { isFetching: true }],
        [types.default.SET_CUSTOM_VIEW_UI_FLAG, { isFetching: false }],
      ]);
    });
  });

  describe('#create', () => {
    it('sends correct actions if API is success', async () => {
      const firstItem = customViewList[0];
      axios.post.mockResolvedValue({ data: firstItem });
      await actions.create({ commit }, firstItem);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CUSTOM_VIEW_UI_FLAG, { isCreating: true }],
        [
          types.default.ADD_CUSTOM_VIEW,
          { data: firstItem, filterType: 'conversation' },
        ],
        [types.default.SET_CUSTOM_VIEW_UI_FLAG, { isCreating: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.post.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.create({ commit })).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CUSTOM_VIEW_UI_FLAG, { isCreating: true }],
        [types.default.SET_CUSTOM_VIEW_UI_FLAG, { isCreating: false }],
      ]);
    });
  });

  describe('#delete', () => {
    it('sends correct actions if API is success', async () => {
      axios.delete.mockResolvedValue({ data: customViewList[0] });
      await actions.delete({ commit }, { id: 1, filterType: 'contact' });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CUSTOM_VIEW_UI_FLAG, { isDeleting: true }],
        [types.default.DELETE_CUSTOM_VIEW, { data: 1, filterType: 'contact' }],
        [types.default.SET_CUSTOM_VIEW_UI_FLAG, { isDeleting: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.delete.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.delete({ commit }, 1)).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CUSTOM_VIEW_UI_FLAG, { isDeleting: true }],
        [types.default.SET_CUSTOM_VIEW_UI_FLAG, { isDeleting: false }],
      ]);
    });
  });

  describe('#update', () => {
    it('sends correct actions if API is success', async () => {
      const item = updateCustomViewList[0];
      axios.patch.mockResolvedValue({ data: item });
      await actions.update({ commit }, item);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CUSTOM_VIEW_UI_FLAG, { isCreating: true }],
        [
          types.default.UPDATE_CUSTOM_VIEW,
          { data: item, filterType: 'conversation' },
        ],
        [types.default.SET_CUSTOM_VIEW_UI_FLAG, { isCreating: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.patch.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.update({ commit }, 1)).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CUSTOM_VIEW_UI_FLAG, { isCreating: true }],
        [types.default.SET_CUSTOM_VIEW_UI_FLAG, { isCreating: false }],
      ]);
    });
  });

  describe('#setActiveConversationFolder', () => {
    it('set active conversation folder', async () => {
      await actions.setActiveConversationFolder({ commit }, customViewList[0]);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_ACTIVE_CONVERSATION_FOLDER, customViewList[0]],
      ]);
    });
  });
});
