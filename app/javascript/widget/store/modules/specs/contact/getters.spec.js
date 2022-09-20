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
      isSetUserTriggered: { fullName: false },
    };
    expect(getters.getCurrentUser(state)).toEqual({
      email: 'thoma@sphadikam.com',
      name: 'Adu Thoma',
      avatar_url: '',
      identifier_hash: 'malana_hash',
    });
    expect(getters.getSetUserTriggerStatus(state)).toEqual({ fullName: false });
  });
});
