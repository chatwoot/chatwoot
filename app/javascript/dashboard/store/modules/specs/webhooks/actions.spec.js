import axios from 'axios';
import { actions } from '../../webhooks';
import * as types from '../../../mutation-types';
import webhooks from './fixtures';

const commit = vi.fn();
global.axios = axios;
vi.mock('axios');

describe('#actions', () => {
  describe('#get', () => {
    it('sends correct actions if API is success', async () => {
      axios.get.mockResolvedValue({ data: { payload: { webhooks } } });
      await actions.get({ commit });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_WEBHOOK_UI_FLAG, { fetchingList: true }],
        [types.default.SET_WEBHOOK, webhooks],
        [types.default.SET_WEBHOOK_UI_FLAG, { fetchingList: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });
      await actions.get({ commit });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_WEBHOOK_UI_FLAG, { fetchingList: true }],
        [types.default.SET_WEBHOOK_UI_FLAG, { fetchingList: false }],
      ]);
    });
  });

  describe('#create', () => {
    it('sends correct actions if API is success', async () => {
      axios.post.mockResolvedValue({
        data: { payload: { webhook: webhooks[0] } },
      });
      await actions.create({ commit }, webhooks[0]);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_WEBHOOK_UI_FLAG, { creatingItem: true }],
        [types.default.ADD_WEBHOOK, webhooks[0]],
        [types.default.SET_WEBHOOK_UI_FLAG, { creatingItem: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.post.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.create({ commit }, webhooks[0].id)).rejects.toEqual({
        message: 'Incorrect header',
      });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_WEBHOOK_UI_FLAG, { creatingItem: true }],
        [types.default.SET_WEBHOOK_UI_FLAG, { creatingItem: false }],
      ]);
    });
  });

  describe('#update', () => {
    it('sends correct actions if API is success', async () => {
      axios.patch.mockResolvedValue({
        data: { payload: { webhook: webhooks[1] } },
      });
      await actions.update({ commit }, webhooks[1]);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_WEBHOOK_UI_FLAG, { updatingItem: true }],
        [types.default.UPDATE_WEBHOOK, webhooks[1]],
        [types.default.SET_WEBHOOK_UI_FLAG, { updatingItem: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.put.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.update({ commit }, webhooks[0])).rejects.toThrow(
        Error
      );
      expect(commit.mock.calls).toEqual([
        [types.default.SET_WEBHOOK_UI_FLAG, { updatingItem: true }],
        [types.default.SET_WEBHOOK_UI_FLAG, { updatingItem: false }],
      ]);
    });
  });

  describe('#delete', () => {
    it('sends correct actions if API is success', async () => {
      axios.delete.mockResolvedValue({ data: webhooks[0] });
      await actions.delete({ commit }, webhooks[0].id);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_WEBHOOK_UI_FLAG, { deletingItem: true }],
        [types.default.DELETE_WEBHOOK, webhooks[0].id],
        [types.default.SET_WEBHOOK_UI_FLAG, { deletingItem: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.delete.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.delete({ commit }, webhooks[0].id)).rejects.toEqual({
        message: 'Incorrect header',
      });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_WEBHOOK_UI_FLAG, { deletingItem: true }],
        [types.default.SET_WEBHOOK_UI_FLAG, { deletingItem: false }],
      ]);
    });
  });
});
