import 'expect-more-jest';
import {
  validateAuthenticateRoutePermission,
  validateRouteAccess,
} from './index';

jest.mock('./dashboard/dashboard.routes', () => ({
  routes: [],
}));
jest.mock('./auth/auth.routes', () => ({
  routes: [],
}));
jest.mock('./login/login.routes', () => ({
  routes: [],
}));
window.roleWiseRoutes = {};

describe('#validateAuthenticateRoutePermission', () => {
  describe(`when route is not protected`, () => {
    it(`should go to the dashboard when user is logged in`, () => {
      const to = { name: 'login', params: { accountId: 1 } };
      const from = { name: '', params: { accountId: 1 } };
      const next = jest.fn();
      const getters = {
        isLoggedIn: true,
        getCurrentUser: {
          account_id: 1,
          id: 1,
          accounts: [{ id: 1, role: 'admin', status: 'active' }],
        },
      };
      validateAuthenticateRoutePermission(to, from, next, { getters });
      expect(next).toHaveBeenCalledWith('/app/accounts/1/dashboard');
    });
    it(`should go there when user is not logged in`, () => {
      const to = { name: 'login', params: {} };
      const from = { name: '', params: {} };
      const next = jest.fn();
      const getters = { isLoggedIn: false };
      validateAuthenticateRoutePermission(to, from, next, { getters });
      expect(next).toHaveBeenCalledWith();
    });
  });
  describe(`when route is protected`, () => {
    describe(`when user not logged in`, () => {
      it(`should redirect to login`, () => {
        // Arrange
        const to = { name: 'some-protected-route', params: { accountId: 1 } };
        const from = { name: '' };
        const next = jest.fn();
        const getters = {
          isLoggedIn: false,
          getCurrentUser: {
            account_id: null,
            id: null,
            accounts: [],
          },
        };
        validateAuthenticateRoutePermission(to, from, next, { getters });
        expect(next).toHaveBeenCalledWith('/app/login');
      });
    });
    describe(`when user is logged in`, () => {
      describe(`when route is not accessible to current user`, () => {
        it(`should redirect to dashboard`, () => {
          window.roleWiseRoutes.agent = ['dashboard'];
          const to = { name: 'admin', params: { accountId: 1 } };
          const from = { name: '' };
          const next = jest.fn();
          const getters = {
            isLoggedIn: true,
            getCurrentUser: {
              account_id: 1,
              id: 1,
              accounts: [{ id: 1, role: 'agent', status: 'active' }],
            },
          };
          validateAuthenticateRoutePermission(to, from, next, { getters });
          expect(next).toHaveBeenCalledWith('/app/accounts/1/dashboard');
        });
      });
      describe(`when route is accessible to current user`, () => {
        it(`should go there`, () => {
          window.roleWiseRoutes.agent = ['dashboard', 'admin'];
          const to = { name: 'admin', params: { accountId: 1 } };
          const from = { name: '' };
          const next = jest.fn();
          const getters = {
            isLoggedIn: true,
            getCurrentUser: {
              account_id: 1,
              id: 1,
              accounts: [{ id: 1, role: 'agent', status: 'active' }],
            },
          };
          validateAuthenticateRoutePermission(to, from, next, { getters });
          expect(next).toHaveBeenCalledWith();
        });
      });
    });
  });
});

describe('#validateRouteAccess', () => {
  it('returns to login if signup is disabled', () => {
    window.chatwootConfig = { signupEnabled: 'false' };
    const to = { name: 'auth_signup', meta: { requireSignupEnabled: true } };
    const from = { name: '' };
    const next = jest.fn();
    validateRouteAccess(to, from, next, {});
    expect(next).toHaveBeenCalledWith('/app/login');
  });

  it('returns next for an auth ignore route ', () => {
    const to = { name: 'auth_confirmation' };
    const from = { name: '' };
    const next = jest.fn();

    validateRouteAccess(to, from, next, {});
    expect(next).toHaveBeenCalledWith();
  });

  it('returns route validation for everything else ', () => {
    const to = { name: 'login' };
    const from = { name: '' };
    const next = jest.fn();

    validateRouteAccess(to, from, next, { getters: { isLoggedIn: false } });
    expect(next).toHaveBeenCalledWith();
  });
});
