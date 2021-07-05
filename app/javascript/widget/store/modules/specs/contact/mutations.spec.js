import { mutations } from '../../contacts';

describe('#mutations', () => {
  describe('#SET_CURRENT_USER', () => {
    it('set current user', () => {
      const user = {
        email: 'thoma@sphadikam.com',
        name: 'Adu Thoma',
        avatar_url: '',
        identifier_hash: 'malana_hash',
      };
      const state = { currentUser: {} };
      mutations.SET_CURRENT_USER(state, user);
      expect(state.currentUser).toEqual(user);
    });
  });
});
