import axios from 'axios';
import { actions } from '../../campaigns';
import * as types from '../../../mutation-types';
import campaignList from './fixtures';

const commit = jest.fn();
global.axios = axios;
jest.mock('axios');

describe('#actions', () => {
  describe('#get', () => {
    it('sends correct actions if API is success', async () => {
      axios.get.mockResolvedValue({ data: campaignList });
      await actions.get({ commit }, { inboxId: 23 });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CAMPAIGN_UI_FLAG, { isFetching: true }],
        [types.default.SET_CAMPAIGNS, campaignList],
        [types.default.SET_CAMPAIGN_UI_FLAG, { isFetching: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });
      await actions.get({ commit }, { inboxId: 23 });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CAMPAIGN_UI_FLAG, { isFetching: true }],
        [types.default.SET_CAMPAIGN_UI_FLAG, { isFetching: false }],
      ]);
    });
  });
  describe('#create', () => {
    it('sends correct actions if API is success', async () => {
      axios.post.mockResolvedValue({ data: campaignList[0] });
      await actions.create({ commit }, campaignList[0]);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CAMPAIGN_UI_FLAG, { isCreating: true }],
        [types.default.ADD_CAMPAIGN, campaignList[0]],
        [types.default.SET_CAMPAIGN_UI_FLAG, { isCreating: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.post.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.create({ commit })).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CAMPAIGN_UI_FLAG, { isCreating: true }],
        [types.default.SET_CAMPAIGN_UI_FLAG, { isCreating: false }],
      ]);
    });
  });

  describe('#update', () => {
    it('sends correct actions if API is success', async () => {
      axios.patch.mockResolvedValue({ data: campaignList[0] });
      await actions.update({ commit }, campaignList[0]);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CAMPAIGN_UI_FLAG, { isUpdating: true }],
        [types.default.EDIT_CAMPAIGN, campaignList[0]],
        [types.default.SET_CAMPAIGN_UI_FLAG, { isUpdating: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.patch.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.update({ commit }, campaignList[0])).rejects.toThrow(
        Error
      );
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CAMPAIGN_UI_FLAG, { isUpdating: true }],
        [types.default.SET_CAMPAIGN_UI_FLAG, { isUpdating: false }],
      ]);
    });
  });

  describe('#delete', () => {
    it('sends correct actions if API is success', async () => {
      axios.delete.mockResolvedValue({ data: campaignList[0] });
      await actions.delete({ commit }, campaignList[0].id);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CAMPAIGN_UI_FLAG, { isDeleting: true }],
        [types.default.DELETE_CAMPAIGN, campaignList[0].id],
        [types.default.SET_CAMPAIGN_UI_FLAG, { isDeleting: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.delete.mockRejectedValue({ message: 'Incorrect header' });
      await expect(
        actions.delete({ commit }, campaignList[0].id)
      ).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CAMPAIGN_UI_FLAG, { isDeleting: true }],
        [types.default.SET_CAMPAIGN_UI_FLAG, { isDeleting: false }],
      ]);
    });
  });
});
