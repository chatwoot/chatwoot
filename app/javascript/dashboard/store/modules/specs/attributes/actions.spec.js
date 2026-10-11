import axios from 'axios';
import { actions } from '../../attributes';
import * as types from '../../../mutation-types';
import attributesList from './fixtures';

const commit = vi.fn();
global.axios = axios;
vi.mock('axios');

const buildState = uiFlags => ({
  uiFlags: { isFetching: false, fetchedAccountId: null, ...uiFlags },
});
const rootGetters = { getCurrentAccountId: 1 };

describe('#actions', () => {
  describe('#get', () => {
    it('sends correct actions if API is success', async () => {
      axios.get.mockResolvedValue({ data: attributesList });
      await actions.get({ commit, rootGetters, state: buildState() });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CUSTOM_ATTRIBUTE_UI_FLAG, { isFetching: true }],
        [types.default.SET_CUSTOM_ATTRIBUTE, attributesList],
        [
          types.default.SET_CUSTOM_ATTRIBUTE_UI_FLAG,
          { isFetching: false, fetchedAccountId: 1 },
        ],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });
      await actions.get({ commit, rootGetters, state: buildState() });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CUSTOM_ATTRIBUTE_UI_FLAG, { isFetching: true }],
        [types.default.SET_CUSTOM_ATTRIBUTE_UI_FLAG, { isFetching: false }],
      ]);
    });

    it.each([{ isFetching: true }, { fetchedAccountId: 1 }])(
      'does not fetch again when %o',
      async uiFlags => {
        await actions.get({ commit, rootGetters, state: buildState(uiFlags) });

        expect(axios.get).not.toHaveBeenCalled();
        expect(commit).not.toHaveBeenCalled();
      }
    );

    it('fetches when the account changes', async () => {
      axios.get.mockResolvedValue({ data: attributesList });

      await actions.get({
        commit,
        rootGetters: { getCurrentAccountId: 2 },
        state: buildState({ fetchedAccountId: 1 }),
      });

      expect(axios.get).toHaveBeenCalledOnce();
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
});
