import 'expect-more-jest';
import { validateAuthenticateRoutePermission } from './index';
import store from '../store';
jest.mock('./dashboard/dashboard.routes', () => ({
  routes: [],
}));
jest.mock('./auth/auth.routes', () => ({
  routes: [],
}));
jest.mock('./login/login.routes', () => ({
  routes: [],
}));
jest.mock('../constants', () => {
  return {
    GRAVATAR_URL: 'https://www.gravatar.com/avatar',
    CHANNELS: {
      FACEBOOK: 'facebook',
    },
    ASSIGNEE_TYPE: {
      ME: 'me',
      UNASSIGNED: 'unassigned',
      ALL: 'all',
    },
    STATUS_TYPE: {
      OPEN: 'open',
      RESOLVED: 'resolved',
    },
  };
});
jest.mock('../store', () => jest.fn());
window.roleWiseRoutes = {};

describe(`behavior`, () => {
  beforeEach(() => jest.resetModules());
  describe(`when route is not protected`, () => {
    store.mockReturnValue(() => ({
      getters: {
        isLoggedIn: true,
        getCurrentUser: {
          id: 1,
          accounts: [{ id: 1, role: 'admin' }],
          account_id: 1,
        },
        getCurrentAccountId: 1,
      },
    }));
    it(`should go to the dashboard when user is logged in`, () => {
      const to = { name: 'login', params: { accountId: 1 } };
      const from = { name: '', params: { accountId: 1 } };
      const next = jest.fn();

      validateAuthenticateRoutePermission(to, from, next);

      expect(next).toHaveBeenCalledWith('/app/accounts/1/dashboard');
    });
  });
  describe(`when route is protected`, () => {
    describe(`when user not logged in`, () => {
      it(`should redirect to login`, () => {
        // Arrange
        spyOn(store, 'isLoggedIn').and.returnValue(false);
        spyOn(store, 'getCurrentUser').and.returnValue(null);
        const to = { name: 'some-protected-route', params: { accountId: 1 } };
        const from = { name: '' };
        const next = jest.fn();
        // Act
        validateAuthenticateRoutePermission(to, from, next);
        // Assert
        expect(next).toHaveBeenCalledWith('/app/login');
      });
    });
    describe(`when user is logged in`, () => {
      describe(`when route is not accessible to current user`, () => {
        it(`should redirect to dashboard`, () => {
          // Arrange
          spyOn(store, 'isLoggedIn').and.returnValue(true);
          spyOn(store, 'getCurrentUser').and.returnValue({
            accounts: [{ id: 1, role: 'agent' }],
          });
          window.roleWiseRoutes.agent = ['dashboard'];
          const to = { name: 'admin', params: { accountId: 1 } };
          const from = { name: '' };
          const next = jest.fn();
          // Act
          validateAuthenticateRoutePermission(to, from, next);
          // Assert
          expect(next).toHaveBeenCalledWith('/app/accounts/1/dashboard');
        });
      });
      describe(`when route is accessible to current user`, () => {
        it(`should go there`, () => {
          // Arrange
          spyOn(store, 'isLoggedIn').and.returnValue(true);
          spyOn(store, 'getCurrentUser').and.returnValue({
            accounts: [{ id: 1, role: 'agent' }],
          });
          window.roleWiseRoutes.agent = ['dashboard', 'admin'];
          const to = { name: 'admin', params: { accountId: 1 } };
          const from = { name: '' };
          const next = jest.fn();
          // Act
          validateAuthenticateRoutePermission(to, from, next);
          // Assert
          expect(next).toHaveBeenCalledWith();
        });
      });
    });
  });
});
