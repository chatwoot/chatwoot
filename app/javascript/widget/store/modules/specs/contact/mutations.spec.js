import { mutations } from '../../contacts';

describe('#mutations', () => {
  describe('#SET_CURRENT_USER', () => {
    it('set current user', () => {
      const user = {
        has_email: true,
        has_name: true,
        avatar_url: '',
        identifier_hash: 'malana_hash',
      };
      const state = { currentUser: {} };
      mutations.SET_CURRENT_USER(state, user);
      expect(state.currentUser).toEqual(user);
    });
  });
});
