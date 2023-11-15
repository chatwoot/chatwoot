import 'expect-more-jest';
import { validateAuthenticateRoutePermission } from './index';

jest.mock('./dashboard/dashboard.routes', () => ({
  routes: [],
}));
window.roleWiseRoutes = {};

describe('#validateAuthenticateRoutePermission', () => {
  describe(`when route is protected`, () => {
    describe(`when user not logged in`, () => {
      it(`should redirect to login`, () => {
        // Arrange
        const to = { name: 'some-protected-route', params: { accountId: 1 } };
        const next = jest.fn();
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
          window.roleWiseRoutes.agent = ['dashboard'];
          const to = { name: 'admin', params: { accountId: 1 } };
          const next = jest.fn();
          const getters = {
            isLoggedIn: true,
            getCurrentUser: {
              account_id: 1,
              id: 1,
              accounts: [{ id: 1, role: 'agent', status: 'active' }],
            },
          };
          validateAuthenticateRoutePermission(to, next, { getters });
          expect(next).toHaveBeenCalledWith('/app/accounts/1/dashboard');
        });
      });
      describe(`when route is accessible to current user`, () => {
        it(`should go there`, () => {
          window.roleWiseRoutes.agent = ['dashboard', 'admin'];
          const to = { name: 'admin', params: { accountId: 1 } };
          const next = jest.fn();
          const getters = {
            isLoggedIn: true,
            getCurrentUser: {
              account_id: 1,
              id: 1,
              accounts: [{ id: 1, role: 'agent', status: 'active' }],
            },
          };
          validateAuthenticateRoutePermission(to, next, { getters });
          expect(next).toHaveBeenCalledWith();
        });
      });
    });
  });
});
