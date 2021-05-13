import axios from 'axios';
import { actions, types } from '../../inboxMembers';
import inboxMembers from './fixtures';

const commit = jest.fn();
global.axios = axios;
jest.mock('axios');

describe('#actions', () => {
  describe('#fetch', () => {
    it('sends correct actions if API is success', async () => {
      axios.get.mockResolvedValue({ data: { payload: inboxMembers } });
      await actions.fetch({ commit }, { inboxId: 1 });
      expect(commit.mock.calls).toEqual([
        [types.SET_INBOX_MEMBERS_UI_FLAG, { isFetching: true }],
        [types.SET_INBOX_MEMBERS, { inboxId: 1, members: inboxMembers }],
        [types.SET_INBOX_MEMBERS_UI_FLAG, { isFetching: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.fetch({ commit }, { inboxId: 1 })).rejects.toThrow(
        Error
      );
      expect(commit.mock.calls).toEqual([
        [types.SET_INBOX_MEMBERS_UI_FLAG, { isFetching: true }],
        [types.SET_INBOX_MEMBERS_UI_FLAG, { isFetching: false }],
      ]);
    });
  });
});
