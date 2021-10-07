import { getters } from '../../auth';

import '../../../../routes';

jest.mock('../../../../routes', () => {});
describe('#getters', () => {
  it('isLoggedIn', () => {
    expect(getters.isLoggedIn({ currentUser: { id: null } })).toEqual(false);
    expect(getters.isLoggedIn({ currentUser: { id: 1 } })).toEqual(true);
  });

  it('getCurrentUserID', () => {
    expect(getters.getCurrentUserID({ currentUser: { id: 1 } })).toEqual(1);
  });
  it('getCurrentUser', () => {
    expect(
      getters.getCurrentUser({ currentUser: { id: 1, name: 'Pranav' } })
    ).toEqual({ id: 1, name: 'Pranav' });
  });

  it('get', () => {
    expect(
      getters.getCurrentUserAvailabilityStatus({
        currentAccountId: 1,
        currentUser: {
          id: 1,
          accounts: [{ id: 1, availability_status: 'busy' }],
        },
      })
    ).toEqual('busy');
  });

  it('getUISettings', () => {
    expect(
      getters.getUISettings({
        currentUser: { ui_settings: { is_contact_sidebar_open: true } },
      })
    ).toEqual({ is_contact_sidebar_open: true });
  });
});
