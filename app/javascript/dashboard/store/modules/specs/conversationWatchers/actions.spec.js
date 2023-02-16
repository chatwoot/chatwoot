import axios from 'axios';
import { actions } from '../../conversationWatchers';
import types from '../../../mutation-types';

const commit = jest.fn();
global.axios = axios;
jest.mock('axios');

describe('#actions', () => {
  describe('#get', () => {
    it('sends correct actions if API is success', async () => {
      axios.get.mockResolvedValue({ data: { id: 1 } });
      await actions.show({ commit }, { conversationId: 1 });
      expect(commit.mock.calls).toEqual([
        [types.SET_CONVERSATION_PARTICIPANTS_UI_FLAG, { isFetching: true }],
        [
          types.SET_CONVERSATION_PARTICIPANTS,
          { conversationId: 1, data: { id: 1 } },
        ],
        [types.SET_CONVERSATION_PARTICIPANTS_UI_FLAG, { isFetching: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });
      await expect(
        actions.show({ commit }, { conversationId: 1 })
      ).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.SET_CONVERSATION_PARTICIPANTS_UI_FLAG, { isFetching: true }],
        [types.SET_CONVERSATION_PARTICIPANTS_UI_FLAG, { isFetching: false }],
      ]);
    });
  });

  describe('#update', () => {
    it('sends correct actions if API is success', async () => {
      axios.patch.mockResolvedValue({ data: [{ id: 2 }] });
      await actions.update(
        { commit },
        { conversationId: 2, userIds: [{ id: 2 }] }
      );
      expect(commit.mock.calls).toEqual([
        [types.SET_CONVERSATION_PARTICIPANTS_UI_FLAG, { isUpdating: true }],
        [
          types.SET_CONVERSATION_PARTICIPANTS,
          { conversationId: 2, data: [{ id: 2 }] },
        ],
        [types.SET_CONVERSATION_PARTICIPANTS_UI_FLAG, { isUpdating: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.patch.mockRejectedValue({ message: 'Incorrect header' });
      await expect(
        actions.update({ commit }, { conversationId: 1, content: 'hi' })
      ).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.SET_CONVERSATION_PARTICIPANTS_UI_FLAG, { isUpdating: true }],
        [types.SET_CONVERSATION_PARTICIPANTS_UI_FLAG, { isUpdating: false }],
      ]);
    });
  });
});
