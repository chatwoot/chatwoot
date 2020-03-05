import * as types from '../../../mutation-types';
import { mutations } from '../../userNotificationSettings';

describe('#mutations', () => {
  describe('#SET_USER_NOTIFICATION', () => {
    it('set user notification record', () => {
      const state = { record: {} };
      mutations[types.default.SET_USER_NOTIFICATION](state, {
        selected_email_flags: ['conversation_creation'],
      });
      expect(state.record).toEqual({
        selected_email_flags: ['conversation_creation'],
      });
    });
  });

  describe('#SET_USER_NOTIFICATION_UI_FLAG', () => {
    it('set UIFlag notification', () => {
      const state = {
        uiFlags: { isFetching: false },
      };
      mutations[types.default.SET_USER_NOTIFICATION_UI_FLAG](state, {
        isFetching: true,
      });
      expect(state.uiFlags).toEqual({
        isFetching: true,
      });
    });
  });
});
