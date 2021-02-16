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
});
