import { getters } from '../../auth';

describe('#getters', () => {
  describe('#isLoggedIn', () => {
    it('return correct value if user data is available', () => {
      expect(getters.isLoggedIn({ currentUser: { id: null } })).toEqual(false);
      expect(getters.isLoggedIn({ currentUser: { id: 1 } })).toEqual(true);
    });
  });

  describe('#getCurrentUser', () => {
    it('returns current user id', () => {
      expect(getters.getCurrentUserID({ currentUser: { id: 1 } })).toEqual(1);
    });
  });

  describe('#getCurrentUser', () => {
    it('returns current user object', () => {
      expect(
        getters.getCurrentUser({ currentUser: { id: 1, name: 'Pranav' } })
      ).toEqual({ id: 1, name: 'Pranav' });
    });
  });

  describe('#getCurrentRole', () => {
    it('returns current role if account is available', () => {
      expect(
        getters.getCurrentRole(
          { currentUser: { accounts: [{ id: 1, role: 'admin' }] } },
          { getCurrentAccountId: 1 }
        )
      ).toEqual('admin');
    });

    it('returns undefined if account is not available', () => {
      expect(
        getters.getCurrentRole(
          { currentUser: { accounts: [{ id: 1, role: 'admin' }] } },
          { getCurrentAccountId: 2 }
        )
      ).toEqual(undefined);
    });
  });

  describe('#getCurrentCustomRoleId', () => {
    it('returns current custom role id', () => {
      expect(
        getters.getCurrentCustomRoleId(
          { currentUser: { accounts: [{ id: 1, custom_role_id: 1 }] } },
          { getCurrentAccountId: 1 }
        )
      ).toEqual(1);
    });

    it('returns undefined if account is not available', () => {
      expect(
        getters.getCurrentCustomRoleId(
          { currentUser: { accounts: [{ id: 1, custom_role_id: 1 }] } },
          { getCurrentAccountId: 2 }
        )
      ).toEqual(undefined);
    });
  });

  describe('#getCurrentUserAvailability', () => {
    it('returns correct availability status', () => {
      expect(
        getters.getCurrentUserAvailability(
          {
            currentAccountId: 1,
            currentUser: {
              id: 1,
              accounts: [{ id: 1, availability: 'busy' }],
            },
          },
          { getCurrentAccountId: 1 }
        )
      ).toEqual('busy');
    });
  });

  describe('#getCurrentUserAcceptsConversations', () => {
    it('returns the conversations preference of the current account', () => {
      expect(
        getters.getCurrentUserAcceptsConversations(
          {},
          { getCurrentAccount: { id: 1, accepts_conversations: false } }
        )
      ).toEqual(false);
    });
  });

  describe('#getCurrentUserAcceptsCalls', () => {
    it('returns the calls preference of the current account', () => {
      expect(
        getters.getCurrentUserAcceptsCalls(
          {},
          { getCurrentAccount: { id: 1, accepts_calls: false } }
        )
      ).toEqual(false);
    });
  });

  describe('#getCurrentUserReceivesCalls', () => {
    it('returns true when the user is online and takes calls', () => {
      expect(
        getters.getCurrentUserReceivesCalls(
          {},
          {
            getCurrentUserAvailability: 'online',
            getCurrentUserAcceptsCalls: true,
          }
        )
      ).toEqual(true);
    });

    it('returns false when the user is not online', () => {
      expect(
        getters.getCurrentUserReceivesCalls(
          {},
          {
            getCurrentUserAvailability: 'busy',
            getCurrentUserAcceptsCalls: true,
          }
        )
      ).toEqual(false);
    });

    it('returns false when the user has turned calls off', () => {
      expect(
        getters.getCurrentUserReceivesCalls(
          {},
          {
            getCurrentUserAvailability: 'online',
            getCurrentUserAcceptsCalls: false,
          }
        )
      ).toEqual(false);
    });
  });

  describe('#getUISettings', () => {
    it('return correct UI Settings', () => {
      expect(
        getters.getUISettings({
          currentUser: { ui_settings: { is_contact_sidebar_open: true } },
        })
      ).toEqual({ is_contact_sidebar_open: true });
    });
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
      expect(getters.getMessageSignature({ currentUser: {} })).toEqual('');
    });
  });

  describe('#getCurrentAccount', () => {
    it('returns correct values', () => {
      expect(
        getters.getCurrentAccount({
          currentUser: {},
        })
      ).toEqual({});
      expect(
        getters.getCurrentAccount(
          {
            currentUser: {
              accounts: [
                {
                  name: 'Chatwoot',
                  id: 1,
                },
              ],
            },
            currentAccountId: 1,
          },
          { getCurrentAccountId: 1 }
        )
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
