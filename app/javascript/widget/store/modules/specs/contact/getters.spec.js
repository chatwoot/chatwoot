import { getters } from '../../contacts';

describe('#getters', () => {
  it('getCurrentUser', () => {
    const user = {
      email: 'thoma@sphadikam.com',
      name: 'Adu Thoma',
      avatar_url: '',
      identifier_hash: 'malana_hash',
    };
    const state = {
      currentUser: user,
      uiFlags: {
        isUpdating: false,
      },
    };
    expect(getters.getCurrentUser(state)).toEqual({
      email: 'thoma@sphadikam.com',
      name: 'Adu Thoma',
      avatar_url: '',
      identifier_hash: 'malana_hash',
    });
  });
  it('getUIFlags', () => {
    const state = {
      currentUser: {},
      uiFlags: {
        isUpdating: false,
      },
    };
    expect(getters.getUIFlags(state)).toEqual({
      isUpdating: false,
    });
  });
});
