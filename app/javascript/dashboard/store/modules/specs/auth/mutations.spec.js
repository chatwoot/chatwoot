import types from '../../../mutation-types';
import { mutations } from '../../auth';

describe('#mutations', () => {
  describe('#SET_CURRENT_USER_UI_SETTINGS', () => {
    it('set ui flags', () => {
      const state = {
        currentUser: {
          ui_settings: { is_contact_sidebar_open: true, icon_type: 'emoji' },
        },
      };
      mutations[types.SET_CURRENT_USER_UI_SETTINGS](state, {
        uiSettings: { is_contact_sidebar_open: false },
      });
      expect(state.currentUser.ui_settings).toEqual({
        is_contact_sidebar_open: false,
        icon_type: 'emoji',
      });
    });
  });
  describe('#SET_CURRENT_USER_UI_FLAGS', () => {
    it('set auth ui flags', () => {
      const state = {
        uiFlags: { isFetching: false },
      };
      mutations[types.SET_CURRENT_USER_UI_FLAGS](state, { isFetching: true });
      expect(state.uiFlags.isFetching).toEqual(true);
    });
  });
  describe('#CLEAR_USER', () => {
    it('set auth ui flags', () => {
      const state = {
        currentUser: { id: 1 },
      };
      mutations[types.CLEAR_USER](state);
      expect(state.currentUser).toEqual({
        id: null,
        account_id: null,
        accounts: [],
        email: null,
        name: null,
      });
    });
  });
  describe('#SET_CURRENT_USER_AVAILABILITY', () => {
    const state = {
      currentUser: {
        id: 1,
        accounts: [{ id: 1, availability_status: 'offline' }],
        account_id: 1,
      },
    };
    it('set availability status for current user', () => {
      mutations[types.SET_CURRENT_USER_AVAILABILITY](state, 'online');
      expect(state.currentUser.accounts[0].availability_status).toEqual(
        'online'
      );
    });
  });
});
