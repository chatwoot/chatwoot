import {
  getCurrentAccount,
  getUserRole,
  routeIsAccessibleFor,
  validateLoggedInRoutes,
} from '../routeHelpers';

describe('#getCurrentAccount', () => {
  it('should return the current account', () => {
    expect(getCurrentAccount({ accounts: [{ id: 1 }] }, 1)).toEqual({ id: 1 });
    expect(getCurrentAccount({ accounts: [] }, 1)).toEqual(undefined);
  });
});

describe('#getUserRole', () => {
  it('should return the current role', () => {
    expect(
      getUserRole({ accounts: [{ id: 1, role: 'administrator' }] }, 1)
    ).toEqual('administrator');
    expect(getUserRole({ accounts: [] }, 1)).toEqual(null);
  });
});

describe('#routeIsAccessibleFor', () => {
  it('should return the correct access', () => {
    const roleWiseRoutes = { agent: ['conversations'], admin: ['billing'] };
    expect(routeIsAccessibleFor('billing', 'agent', roleWiseRoutes)).toEqual(
      false
    );
    expect(routeIsAccessibleFor('billing', 'admin', roleWiseRoutes)).toEqual(
      true
    );
  });
});

describe('#validateLoggedInRoutes', () => {
  describe('when account access is missing', () => {
    it('should return the login route', () => {
      expect(
        validateLoggedInRoutes(
          { params: { accountId: 1 } },
          { accounts: [] },
          {}
        )
      ).toEqual(`app/login`);
    });
  });
  describe('when account access is available', () => {
    describe('when account is suspended', () => {
      it('return suspended route', () => {
        expect(
          validateLoggedInRoutes(
            { name: 'conversations', params: { accountId: 1 } },
            { accounts: [{ id: 1, role: 'agent', status: 'suspended' }] },
            { agent: ['conversations'] }
          )
        ).toEqual(`accounts/1/suspended`);
      });
    });
    describe('when account is active', () => {
      describe('when route is accessible', () => {
        it('returns null (no action required)', () => {
          expect(
            validateLoggedInRoutes(
              { name: 'conversations', params: { accountId: 1 } },
              { accounts: [{ id: 1, role: 'agent', status: 'active' }] },
              { agent: ['conversations'] }
            )
          ).toEqual(null);
        });
      });
      describe('when route is not accessible', () => {
        it('returns dashboard url', () => {
          expect(
            validateLoggedInRoutes(
              { name: 'conversations', params: { accountId: 1 } },
              { accounts: [{ id: 1, role: 'agent', status: 'active' }] },
              { admin: ['conversations'], agent: [] }
            )
          ).toEqual(`accounts/1/dashboard`);
        });
      });
      describe('when route is suspended route', () => {
        it('returns dashboard url', () => {
          expect(
            validateLoggedInRoutes(
              { name: 'account_suspended', params: { accountId: 1 } },
              { accounts: [{ id: 1, role: 'agent', status: 'active' }] },
              { agent: ['account_suspended'] }
            )
          ).toEqual(`accounts/1/dashboard`);
        });
      });
    });
  });
});
