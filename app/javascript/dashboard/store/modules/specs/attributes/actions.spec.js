import axios from 'axios';
import { actions } from '../../attributes';
import * as types from '../../../mutation-types';
import attributesList from './fixtures';

const commit = vi.fn();
global.axios = axios;
vi.mock('axios');

describe('#actions', () => {
  describe('#get', () => {
    it('sends correct actions if API is success', async () => {
      axios.get.mockResolvedValue({ data: attributesList });
      await actions.get({ commit });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CUSTOM_ATTRIBUTE_UI_FLAG, { isFetching: true }],
        [types.default.SET_CUSTOM_ATTRIBUTE, attributesList],
        [types.default.SET_CUSTOM_ATTRIBUTE_UI_FLAG, { isFetching: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });
      await actions.get({ commit });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CUSTOM_ATTRIBUTE_UI_FLAG, { isFetching: true }],
        [types.default.SET_CUSTOM_ATTRIBUTE_UI_FLAG, { isFetching: false }],
      ]);
    });
  });
  describe('#create', () => {
    it('sends correct actions if API is success', async () => {
      axios.post.mockResolvedValue({ data: attributesList[0] });
      await actions.create({ commit }, attributesList[0]);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CUSTOM_ATTRIBUTE_UI_FLAG, { isCreating: true }],
        [types.default.ADD_CUSTOM_ATTRIBUTE, attributesList[0]],
        [types.default.SET_CUSTOM_ATTRIBUTE_UI_FLAG, { isCreating: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.post.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.create({ commit })).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CUSTOM_ATTRIBUTE_UI_FLAG, { isCreating: true }],
        [types.default.SET_CUSTOM_ATTRIBUTE_UI_FLAG, { isCreating: false }],
      ]);
    });
  });

  describe('#update', () => {
    it('sends correct actions if API is success', async () => {
      axios.patch.mockResolvedValue({ data: attributesList[0] });
      await actions.update({ commit }, attributesList[0]);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CUSTOM_ATTRIBUTE_UI_FLAG, { isUpdating: true }],
        [types.default.EDIT_CUSTOM_ATTRIBUTE, attributesList[0]],
        [types.default.SET_CUSTOM_ATTRIBUTE_UI_FLAG, { isUpdating: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.patch.mockRejectedValue({ message: 'Incorrect header' });
      await expect(
        actions.update({ commit }, attributesList[0])
      ).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CUSTOM_ATTRIBUTE_UI_FLAG, { isUpdating: true }],
        [types.default.SET_CUSTOM_ATTRIBUTE_UI_FLAG, { isUpdating: false }],
      ]);
    });
  });

  describe('#delete', () => {
    it('sends correct actions if API is success', async () => {
      axios.delete.mockResolvedValue({ data: attributesList[0] });
      await actions.delete({ commit }, attributesList[0].id);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CUSTOM_ATTRIBUTE_UI_FLAG, { isDeleting: true }],
        [types.default.DELETE_CUSTOM_ATTRIBUTE, attributesList[0].id],
        [types.default.SET_CUSTOM_ATTRIBUTE_UI_FLAG, { isDeleting: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.delete.mockRejectedValue({ message: 'Incorrect header' });
      await expect(
        actions.delete({ commit }, attributesList[0].id)
      ).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CUSTOM_ATTRIBUTE_UI_FLAG, { isDeleting: true }],
        [types.default.SET_CUSTOM_ATTRIBUTE_UI_FLAG, { isDeleting: false }],
      ]);
    });
  });

  describe('#reorder', () => {
    const state = {
      records: [
        { id: 1, position: 10 },
        { id: 2, position: 20 },
      ],
    };

    it('sets isReordering while in flight and clears it if API is success', async () => {
      axios.post.mockResolvedValue({});
      await actions.reorder({ commit, state }, { 1: 20, 2: 10 });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CUSTOM_ATTRIBUTE_UI_FLAG, { isReordering: true }],
        [types.default.SET_CUSTOM_ATTRIBUTE_POSITIONS, { 1: 20, 2: 10 }],
        [types.default.SET_CUSTOM_ATTRIBUTE_UI_FLAG, { isReordering: false }],
      ]);
    });

    it('rolls back positions and clears isReordering if API is error', async () => {
      axios.post.mockRejectedValue({ message: 'Incorrect header' });
      await expect(
        actions.reorder({ commit, state }, { 1: 20, 2: 10 })
      ).rejects.toBeTruthy();
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CUSTOM_ATTRIBUTE_UI_FLAG, { isReordering: true }],
        [types.default.SET_CUSTOM_ATTRIBUTE_POSITIONS, { 1: 20, 2: 10 }],
        [types.default.SET_CUSTOM_ATTRIBUTE_POSITIONS, { 1: 10, 2: 20 }],
        [types.default.SET_CUSTOM_ATTRIBUTE_UI_FLAG, { isReordering: false }],
      ]);
    });
  });
});
