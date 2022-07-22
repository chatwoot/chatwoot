import axios from 'axios';
import { actions } from '../actions';
import { types } from '../mutations';
import { apiResponse } from './fixtures';

const commit = jest.fn();
global.axios = axios;
jest.mock('axios');

// fetchAllPortals;
// createPortal;
// updatePortal;
// deletePortal;

describe('#actions', () => {
  describe('#fetchAllPortals', () => {
    it('sends correct actions if API is success', async () => {
      axios.get.mockResolvedValue({ data: apiResponse });
      await actions.fetchAllPortals({ commit });
      expect(commit.mock.calls).toEqual([
        [types.SET_UI_FLAG, { isFetching: true }],
        [types.ADD_MANY_PORTALS_ENTRY, apiResponse],
        [types.ADD_MANY_PORTALS_IDS, [1, 2]],
        [types.SET_UI_FLAG, { isFetching: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.fetchAllPortals({ commit })).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.SET_UI_FLAG, { isFetching: true }],
        [types.SET_UI_FLAG, { isFetching: false }],
      ]);
    });
  });

  describe('#createPortal', () => {
    it('sends correct actions if API is success', async () => {
      axios.post.mockResolvedValue({ data: apiResponse[1] });
      await actions.createPortal(
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
      await expect(actions.createPortal({ commit }, {})).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.SET_UI_FLAG, { isCreating: true }],
        [types.SET_UI_FLAG, { isCreating: false }],
      ]);
    });
  });

  describe('#updatePortal', () => {
    it('sends correct actions if API is success', async () => {
      axios.patch.mockResolvedValue({ data: apiResponse[1] });
      await actions.updatePortal({ commit }, { helpCenter: apiResponse[1] });
      expect(commit.mock.calls).toEqual([
        [
          types.SET_HELP_PORTAL_UI_FLAG,
          {
            uiFlags: {
              isUpdating: true,
            },
            helpCenterId: 2,
          },
        ],
        [types.UPDATE_PORTAL_ENTRY, apiResponse[1]],
        [
          types.SET_HELP_PORTAL_UI_FLAG,
          {
            uiFlags: {
              isUpdating: false,
            },
            helpCenterId: 2,
          },
        ],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.patch.mockRejectedValue({ message: 'Incorrect header' });
      await expect(
        actions.updatePortal({ commit }, { helpCenter: apiResponse[1] })
      ).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [
          types.SET_HELP_PORTAL_UI_FLAG,
          {
            uiFlags: {
              isUpdating: true,
            },
            helpCenterId: 2,
          },
        ],
        [
          types.SET_HELP_PORTAL_UI_FLAG,
          {
            uiFlags: {
              isUpdating: false,
            },
            helpCenterId: 2,
          },
        ],
      ]);
    });
  });

  describe('#deletePortal', () => {
    it('sends correct actions if API is success', async () => {
      axios.delete.mockResolvedValue({});
      await actions.deletePortal({ commit }, { helpCenterId: 2 });
      expect(commit.mock.calls).toEqual([
        [
          types.SET_HELP_PORTAL_UI_FLAG,
          {
            uiFlags: {
              isDeleting: true,
            },
            helpCenterId: 2,
          },
        ],
        [types.REMOVE_PORTAL_ENTRY, 2],
        [types.REMOVE_PORTAL_ID, 2],
        [
          types.SET_HELP_PORTAL_UI_FLAG,
          {
            uiFlags: {
              isDeleting: false,
            },
            helpCenterId: 2,
          },
        ],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.delete.mockRejectedValue({ message: 'Incorrect header' });
      await expect(
        actions.deletePortal({ commit }, { helpCenterId: 2 })
      ).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [
          types.SET_HELP_PORTAL_UI_FLAG,
          {
            uiFlags: {
              isDeleting: true,
            },
            helpCenterId: 2,
          },
        ],
        [
          types.SET_HELP_PORTAL_UI_FLAG,
          {
            uiFlags: {
              isDeleting: false,
            },
            helpCenterId: 2,
          },
        ],
      ]);
    });
  });
});
