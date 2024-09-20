import { validateAuthenticateRoutePermission } from './index';

describe('#validateAuthenticateRoutePermission', () => {
  describe(`when route is protected`, () => {
    describe(`when user not logged in`, () => {
      it(`should redirect to login`, () => {
        const to = { name: 'some-protected-route', params: { accountId: 1 } };
        const next = vi.fn();
        const getters = {
          isLoggedIn: false,
          getCurrentUser: {
            account_id: null,
            id: null,
            accounts: [],
          },
        };

        expect(validateAuthenticateRoutePermission(to, next, { getters })).toBe(
          '/app/login'
        );
      });
    });
    describe(`when user is logged in`, () => {
      describe(`when route is not accessible to current user`, () => {
        it(`should redirect to dashboard`, () => {
          const to = {
            name: 'general_settings_index',
            params: { accountId: 1 },
            meta: { permissions: ['administrator'] },
          };
          const next = vi.fn();
          const getters = {
            isLoggedIn: true,
            getCurrentUser: {
              account_id: 1,
              id: 1,
              permissions: ['agent'],
              accounts: [{ id: 1, role: 'agent', status: 'active' }],
            },
          };
          validateAuthenticateRoutePermission(to, next, { getters });
          expect(next).toHaveBeenCalledWith('/app/accounts/1/dashboard');
        });
      });
      describe(`when route is accessible to current user`, () => {
        it(`should go there`, () => {
          const to = {
            name: 'general_settings_index',
            params: { accountId: 1 },
            meta: { permissions: ['administrator'] },
          };
          const next = vi.fn();
          const getters = {
            isLoggedIn: true,
            getCurrentUser: {
              account_id: 1,
              id: 1,
              permissions: ['administrator'],
              accounts: [{ id: 1, role: 'administrator', status: 'active' }],
            },
          };
          validateAuthenticateRoutePermission(to, next, { getters });
          expect(next).toHaveBeenCalledWith();
        });
      });
    });
  });
});
