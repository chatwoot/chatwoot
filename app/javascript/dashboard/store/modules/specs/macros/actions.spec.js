import axios from 'axios';
import { actions } from '../../macros';
import * as types from '../../../mutation-types';
import macrosList from './fixtures';

const commit = vi.fn();
global.axios = axios;
vi.mock('axios');

describe('#actions', () => {
  describe('#get', () => {
    it('sends correct actions if API is success', async () => {
      axios.get.mockResolvedValue({ data: { payload: macrosList } });
      await actions.get({ commit });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_MACROS_UI_FLAG, { isFetching: true }],
        [types.default.SET_MACROS, macrosList],
        [types.default.SET_MACROS_UI_FLAG, { isFetching: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });
      await actions.get({ commit });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_MACROS_UI_FLAG, { isFetching: true }],
        [types.default.SET_MACROS_UI_FLAG, { isFetching: false }],
      ]);
    });
  });

  describe('#getMacroById', () => {
    it('sends correct actions if API is success', async () => {
      axios.get.mockResolvedValue({ data: { payload: macrosList[0] } });
      await actions.getSingleMacro({ commit }, 22);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_MACROS_UI_FLAG, { isFetchingItem: true }],
        [types.default.ADD_MACRO, macrosList[0]],
        [types.default.SET_MACROS_UI_FLAG, { isFetchingItem: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });
      await actions.getSingleMacro({ commit }, 22);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_MACROS_UI_FLAG, { isFetchingItem: true }],
        [types.default.SET_MACROS_UI_FLAG, { isFetchingItem: false }],
      ]);
    });
  });

  describe('#create', () => {
    it('sends correct actions if API is success', async () => {
      axios.post.mockResolvedValue({ data: { payload: macrosList[0] } });
      await actions.create({ commit }, macrosList[0]);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_MACROS_UI_FLAG, { isCreating: true }],
        [types.default.ADD_MACRO, macrosList[0]],
        [types.default.SET_MACROS_UI_FLAG, { isCreating: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.post.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.create({ commit })).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_MACROS_UI_FLAG, { isCreating: true }],
        [types.default.SET_MACROS_UI_FLAG, { isCreating: false }],
      ]);
    });
  });

  describe('#execute', () => {
    const macroId = 12;
    const conversationIds = [1];
    it('sends correct actions if API is success', async () => {
      axios.post.mockResolvedValue({ data: null });
      await actions.execute(
        { commit },
        {
          macroId,
          conversationIds,
        }
      );
      expect(commit.mock.calls).toEqual([
        [types.default.SET_MACROS_UI_FLAG, { isExecuting: true }],
        [types.default.SET_MACROS_UI_FLAG, { isExecuting: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.post.mockRejectedValue({ message: 'Incorrect header' });
      await expect(
        actions.execute(
          { commit },
          {
            macroId,
            conversationIds,
          }
        )
      ).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_MACROS_UI_FLAG, { isExecuting: true }],
        [types.default.SET_MACROS_UI_FLAG, { isExecuting: false }],
      ]);
    });
  });

  describe('#update', () => {
    it('sends correct actions if API is success', async () => {
      axios.patch.mockResolvedValue({
        data: { payload: macrosList[0] },
      });
      await actions.update({ commit }, macrosList[0]);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_MACROS_UI_FLAG, { isUpdating: true }],
        [types.default.EDIT_MACRO, macrosList[0]],
        [types.default.SET_MACROS_UI_FLAG, { isUpdating: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.patch.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.update({ commit }, macrosList[0])).rejects.toThrow(
        Error
      );
      expect(commit.mock.calls).toEqual([
        [types.default.SET_MACROS_UI_FLAG, { isUpdating: true }],
        [types.default.SET_MACROS_UI_FLAG, { isUpdating: false }],
      ]);
    });
  });

  describe('#delete', () => {
    it('sends correct actions if API is success', async () => {
      axios.delete.mockResolvedValue({ data: macrosList[0] });
      await actions.delete({ commit }, macrosList[0].id);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_MACROS_UI_FLAG, { isDeleting: true }],
        [types.default.DELETE_MACRO, macrosList[0].id],
        [types.default.SET_MACROS_UI_FLAG, { isDeleting: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.delete.mockRejectedValue({ message: 'Incorrect header' });
      await expect(
        actions.delete({ commit }, macrosList[0].id)
      ).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_MACROS_UI_FLAG, { isDeleting: true }],
        [types.default.SET_MACROS_UI_FLAG, { isDeleting: false }],
      ]);
    });
  });
});
