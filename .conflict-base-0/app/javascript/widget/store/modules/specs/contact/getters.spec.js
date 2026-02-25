import { getters } from '../../contacts';

describe('#getters', () => {
  it('getCurrentUser', () => {
    const user = {
      has_email: true,
      has_name: true,
      avatar_url: '',
      identifier_hash: 'malana_hash',
    };
    const state = {
      currentUser: user,
    };
    expect(getters.getCurrentUser(state)).toEqual({
      has_email: true,
      has_name: true,
      avatar_url: '',
      identifier_hash: 'malana_hash',
    });
  });
});
