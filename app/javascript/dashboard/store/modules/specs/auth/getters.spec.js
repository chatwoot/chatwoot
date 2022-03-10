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
      getters.getCurrentUserAvailability({
        currentAccountId: 1,
        currentUser: {
          id: 1,
          accounts: [{ id: 1, availability: 'busy' }],
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
  describe('#getMessageSignature', () => {
    it('Return signature when signature is present', () => {
      expect(
        getters.getMessageSignature({
          currentUser: { message_signature: 'Thanks' },
        })
      ).toEqual('Thanks');
    });
    it('Return empty string when signature is not present', () => {
      expect(
        getters.getMessageSignature({
          currentUser: {},
        })
      ).toEqual('');
    });
  });

  describe('#getCurrentAccount', () => {
    it('returns correct values', () => {
      expect(
        getters.getCurrentAccount({
          currentUser: {},
          currentAccountId: 1,
        })
      ).toEqual({});

      expect(
        getters.getCurrentAccount({
          currentUser: {
            accounts: [
              {
                name: 'Chatwoot',
                id: 1,
              },
            ],
          },
          currentAccountId: 1,
        })
      ).toEqual({
        name: 'Chatwoot',
        id: 1,
      });
    });
  });

  describe('#getUserAccounts', () => {
    it('returns correct values', () => {
      expect(
        getters.getUserAccounts({
          currentUser: {},
        })
      ).toEqual([]);

      expect(
        getters.getUserAccounts({
          currentUser: {
            accounts: [
              {
                name: 'Chatwoot',
                id: 1,
              },
            ],
          },
        })
      ).toEqual([
        {
          name: 'Chatwoot',
          id: 1,
        },
      ]);
    });
  });
});
