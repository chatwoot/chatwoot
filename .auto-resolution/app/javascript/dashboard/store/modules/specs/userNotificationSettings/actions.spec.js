import axios from 'axios';
import { actions } from '../../userNotificationSettings';
import * as types from '../../../mutation-types';

const commit = vi.fn();
global.axios = axios;
vi.mock('axios');

describe('#actions', () => {
  describe('#get', () => {
    it('sends correct actions if API is success', async () => {
      axios.get.mockResolvedValue({
        data: { selected_email_flags: ['conversation_creation'] },
      });
      await actions.get({ commit });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_USER_NOTIFICATION_UI_FLAG, { isFetching: true }],
        [
          types.default.SET_USER_NOTIFICATION,
          { selected_email_flags: ['conversation_creation'] },
        ],
        [types.default.SET_USER_NOTIFICATION_UI_FLAG, { isFetching: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });
      await actions.get({ commit });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_USER_NOTIFICATION_UI_FLAG, { isFetching: true }],
        [types.default.SET_USER_NOTIFICATION_UI_FLAG, { isFetching: false }],
      ]);
    });
  });

  describe('#update', () => {
    it('sends correct actions if API is success', async () => {
      axios.patch.mockResolvedValue({
        data: { selected_email_flags: ['conversation_creation'] },
      });
      await actions.update(
        { commit },
        { selected_email_flags: ['conversation_creation'] }
      );
      expect(commit.mock.calls).toEqual([
        [types.default.SET_USER_NOTIFICATION_UI_FLAG, { isUpdating: true }],
        [
          types.default.SET_USER_NOTIFICATION,
          { selected_email_flags: ['conversation_creation'] },
        ],
        [types.default.SET_USER_NOTIFICATION_UI_FLAG, { isUpdating: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.patch.mockRejectedValue({ message: 'Incorrect header' });
      await expect(
        actions.update(
          { commit },
          { selected_email_flags: ['conversation_creation'] }
        )
      ).rejects.toEqual({
        message: 'Incorrect header',
      });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_USER_NOTIFICATION_UI_FLAG, { isUpdating: true }],
        [types.default.SET_USER_NOTIFICATION_UI_FLAG, { isUpdating: false }],
      ]);
    });
  });
});
