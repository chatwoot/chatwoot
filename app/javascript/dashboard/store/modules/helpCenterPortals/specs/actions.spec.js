import axios from 'axios';
import { actions } from '../actions';
import { types } from '../mutations';
import { apiResponse } from './fixtures';

const commit = jest.fn();
const dispatch = jest.fn();
global.axios = axios;
jest.mock('axios');

describe('#actions', () => {
  describe('#index', () => {
    it('sends correct actions if API is success', async () => {
      axios.get.mockResolvedValue({ data: apiResponse });
      await actions.index({
        commit,
        dispatch,
        state: {},
      });
      expect(commit.mock.calls).toEqual([
        [types.SET_UI_FLAG, { isFetching: true }],
        [types.CLEAR_PORTALS],
        [types.ADD_MANY_PORTALS_ENTRY, apiResponse.payload],
        [types.ADD_MANY_PORTALS_IDS, ['domain', 'campaign']],
        [types.SET_PORTALS_META, { current_page: 1, portals_count: 1 }],
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
      axios.post.mockResolvedValue({ data: apiResponse.payload[1] });
      await actions.create(
        { commit, dispatch, state: { portals: {} } },
        {
          color: 'red',
          custom_domain: 'domain_for_help',
          header_text: 'Domain Header',
        }
      );
      expect(commit.mock.calls).toEqual([
        [types.SET_UI_FLAG, { isCreating: true }],
        [types.ADD_PORTAL_ENTRY, apiResponse.payload[1]],
        [types.ADD_PORTAL_ID, 'campaign'],
        [types.SET_UI_FLAG, { isCreating: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.post.mockRejectedValue({ message: 'Incorrect header' });
      await expect(
        actions.create({ commit, dispatch, state: { portals: {} } }, {})
      ).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.SET_UI_FLAG, { isCreating: true }],
        [types.SET_UI_FLAG, { isCreating: false }],
      ]);
    });
  });

  describe('#update', () => {
    it('sends correct actions if API is success', async () => {
      axios.patch.mockResolvedValue({ data: apiResponse.payload[1] });
      await actions.update({ commit }, { portalObj: apiResponse.payload[1] });
      expect(commit.mock.calls).toEqual([
        [
          types.SET_HELP_PORTAL_UI_FLAG,
          { uiFlags: { isUpdating: true }, portalSlug: 'campaign' },
        ],
        [types.UPDATE_PORTAL_ENTRY, apiResponse.payload[1]],
        [
          types.SET_HELP_PORTAL_UI_FLAG,
          { uiFlags: { isUpdating: false }, portalSlug: 'campaign' },
        ],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.patch.mockRejectedValue({ message: 'Incorrect header' });
      await expect(
        actions.update({ commit }, { portalObj: apiResponse.payload[1] })
      ).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [
          types.SET_HELP_PORTAL_UI_FLAG,
          { uiFlags: { isUpdating: true }, portalSlug: 'campaign' },
        ],
        [
          types.SET_HELP_PORTAL_UI_FLAG,
          { uiFlags: { isUpdating: false }, portalSlug: 'campaign' },
        ],
      ]);
    });
  });

  describe('#delete', () => {
    it('sends correct actions if API is success', async () => {
      axios.delete.mockResolvedValue({});
      await actions.delete({ commit }, { portalSlug: 'campaign' });
      expect(commit.mock.calls).toEqual([
        [
          types.SET_HELP_PORTAL_UI_FLAG,
          { uiFlags: { isDeleting: true }, portalSlug: 'campaign' },
        ],
        [types.REMOVE_PORTAL_ENTRY, 'campaign'],
        [types.REMOVE_PORTAL_ID, 'campaign'],
        [
          types.SET_HELP_PORTAL_UI_FLAG,
          { uiFlags: { isDeleting: false }, portalSlug: 'campaign' },
        ],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.delete.mockRejectedValue({ message: 'Incorrect header' });
      await expect(
        actions.delete({ commit }, { portalSlug: 'campaign' })
      ).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [
          types.SET_HELP_PORTAL_UI_FLAG,
          { uiFlags: { isDeleting: true }, portalSlug: 'campaign' },
        ],
        [
          types.SET_HELP_PORTAL_UI_FLAG,
          { uiFlags: { isDeleting: false }, portalSlug: 'campaign' },
        ],
      ]);
    });
  });
});
