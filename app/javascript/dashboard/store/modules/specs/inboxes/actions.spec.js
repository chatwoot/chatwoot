import axios from 'axios';
import { actions } from '../../inboxes';
import * as types from '../../../mutation-types';
import inboxList from './fixtures';

const commit = jest.fn();
global.axios = axios;
jest.mock('axios');

describe('#actions', () => {
  describe('#get', () => {
    it('sends correct actions if API is success', async () => {
      axios.get.mockResolvedValue({ data: { payload: inboxList } });
      await actions.get({ commit });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_INBOXES_UI_FLAG, { isFetching: true }],
        [types.default.SET_INBOXES_UI_FLAG, { isFetching: false }],
        [types.default.SET_INBOXES, inboxList],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });
      await actions.get({ commit });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_INBOXES_UI_FLAG, { isFetching: true }],
        [types.default.SET_INBOXES_UI_FLAG, { isFetching: false }],
      ]);
    });
  });

  describe('#createWebsiteChannel', () => {
    it('sends correct actions if API is success', async () => {
      axios.post.mockResolvedValue({ data: inboxList[0] });
      await actions.createWebsiteChannel({ commit }, inboxList[0]);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_INBOXES_UI_FLAG, { isCreating: true }],
        [types.default.ADD_INBOXES, inboxList[0]],
        [types.default.SET_INBOXES_UI_FLAG, { isCreating: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.post.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.createWebsiteChannel({ commit })).rejects.toThrow(
        Error
      );
      expect(commit.mock.calls).toEqual([
        [types.default.SET_INBOXES_UI_FLAG, { isCreating: true }],
        [types.default.SET_INBOXES_UI_FLAG, { isCreating: false }],
      ]);
    });
  });

  describe('#createFBChannel', () => {
    it('sends correct actions if API is success', async () => {
      axios.post.mockResolvedValue({ data: inboxList[0] });
      await actions.createFBChannel({ commit }, inboxList[0]);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_INBOXES_UI_FLAG, { isCreating: true }],
        [types.default.ADD_INBOXES, inboxList[0]],
        [types.default.SET_INBOXES_UI_FLAG, { isCreating: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.post.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.createFBChannel({ commit })).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_INBOXES_UI_FLAG, { isCreating: true }],
        [types.default.SET_INBOXES_UI_FLAG, { isCreating: false }],
      ]);
    });
  });

  describe('#updateInbox', () => {
    it('sends correct actions if API is success', async () => {
      const updatedInbox = inboxList[0];
      updatedInbox.enable_auto_assignment = false;

      axios.patch.mockResolvedValue({ data: updatedInbox });
      await actions.updateInbox(
        { commit },
        { id: updatedInbox.id, inbox: { enable_auto_assignment: false } }
      );
      expect(commit.mock.calls).toEqual([
        [types.default.SET_INBOXES_UI_FLAG, { isUpdatingAutoAssignment: true }],
        [types.default.EDIT_INBOXES, updatedInbox],
        [
          types.default.SET_INBOXES_UI_FLAG,
          { isUpdatingAutoAssignment: false },
        ],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.patch.mockRejectedValue({ message: 'Incorrect header' });
      await expect(
        actions.updateInbox(
          { commit },
          { id: inboxList[0].id, inbox: { enable_auto_assignment: false } }
        )
      ).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_INBOXES_UI_FLAG, { isUpdatingAutoAssignment: true }],
        [
          types.default.SET_INBOXES_UI_FLAG,
          { isUpdatingAutoAssignment: false },
        ],
      ]);
    });
  });

  describe('#delete', () => {
    it('sends correct actions if API is success', async () => {
      axios.delete.mockResolvedValue({ data: inboxList[0] });
      await actions.delete({ commit }, inboxList[0].id);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_INBOXES_UI_FLAG, { isDeleting: true }],
        [types.default.DELETE_INBOXES, inboxList[0].id],
        [types.default.SET_INBOXES_UI_FLAG, { isDeleting: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.delete.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.delete({ commit }, inboxList[0].id)).rejects.toThrow(
        Error
      );
      expect(commit.mock.calls).toEqual([
        [types.default.SET_INBOXES_UI_FLAG, { isDeleting: true }],
        [types.default.SET_INBOXES_UI_FLAG, { isDeleting: false }],
      ]);
    });
  });
});
