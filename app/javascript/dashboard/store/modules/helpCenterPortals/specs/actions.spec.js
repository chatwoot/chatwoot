import axios from 'axios';
import { actions } from '../actions';
import { types } from '../mutations';
import { apiResponse } from './fixtures';

const commit = jest.fn();
global.axios = axios;
jest.mock('axios');

describe('#actions', () => {
  describe('#index', () => {
    it('sends correct actions if API is success', async () => {
      axios.get.mockResolvedValue({ data: apiResponse });
      await actions.index({ commit });
      expect(commit.mock.calls).toEqual([
        [types.SET_UI_FLAG, { isFetching: true }],
        [types.ADD_MANY_PORTALS_ENTRY, apiResponse],
        [types.ADD_MANY_PORTALS_IDS, [1, 2]],
        [types.SET_UI_FLAG, { isFetching: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.index({ commit })).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.SET_UI_FLAG, { isFetching: true }],
        [types.SET_UI_FLAG, { isFetching: false }],
      ]);
    });
  });

  describe('#create', () => {
    it('sends correct actions if API is success', async () => {
      axios.post.mockResolvedValue({ data: apiResponse[1] });
      await actions.create(
        { commit },
        {
          color: 'red',
          custom_domain: 'domain_for_help',
          header_text: 'Domain Header',
        }
      );
      expect(commit.mock.calls).toEqual([
        [types.SET_UI_FLAG, { isCreating: true }],
        [types.ADD_PORTAL_ENTRY, apiResponse[1]],
        [types.ADD_PORTAL_ID, 2],
        [types.SET_UI_FLAG, { isCreating: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.post.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.create({ commit }, {})).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.SET_UI_FLAG, { isCreating: true }],
        [types.SET_UI_FLAG, { isCreating: false }],
      ]);
    });
  });

  describe('#update', () => {
    it('sends correct actions if API is success', async () => {
      axios.patch.mockResolvedValue({ data: apiResponse[1] });
      await actions.update({ commit }, apiResponse[1]);
      expect(commit.mock.calls).toEqual([
        [
          types.SET_HELP_PORTAL_UI_FLAG,
          { uiFlags: { isUpdating: true }, portalId: 2 },
        ],
        [types.UPDATE_PORTAL_ENTRY, apiResponse[1]],
        [
          types.SET_HELP_PORTAL_UI_FLAG,
          { uiFlags: { isUpdating: false }, portalId: 2 },
        ],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.patch.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.update({ commit }, apiResponse[1])).rejects.toThrow(
        Error
      );
      expect(commit.mock.calls).toEqual([
        [
          types.SET_HELP_PORTAL_UI_FLAG,
          { uiFlags: { isUpdating: true }, portalId: 2 },
        ],
        [
          types.SET_HELP_PORTAL_UI_FLAG,
          { uiFlags: { isUpdating: false }, portalId: 2 },
        ],
      ]);
    });
  });

  describe('#delete', () => {
    it('sends correct actions if API is success', async () => {
      axios.delete.mockResolvedValue({});
      await actions.delete({ commit }, 2);
      expect(commit.mock.calls).toEqual([
        [
          types.SET_HELP_PORTAL_UI_FLAG,
          { uiFlags: { isDeleting: true }, portalId: 2 },
        ],
        [types.REMOVE_PORTAL_ENTRY, 2],
        [types.REMOVE_PORTAL_ID, 2],
        [
          types.SET_HELP_PORTAL_UI_FLAG,
          { uiFlags: { isDeleting: false }, portalId: 2 },
        ],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.delete.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.delete({ commit }, 2)).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [
          types.SET_HELP_PORTAL_UI_FLAG,
          { uiFlags: { isDeleting: true }, portalId: 2 },
        ],
        [
          types.SET_HELP_PORTAL_UI_FLAG,
          { uiFlags: { isDeleting: false }, portalId: 2 },
        ],
      ]);
    });
  });
});
