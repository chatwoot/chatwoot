import 'expect-more-jest';
import { validateAuthenticateRoutePermission } from './index';
import auth from '../api/auth';

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

window.roleWiseRoutes = {};

describe(`behavior`, () => {
  describe(`when route is not protected`, () => {
    it(`should go to the dashboard when user is logged in`, () => {
      // Arrange
      spyOn(auth, 'isLoggedIn').and.returnValue(true);
      spyOn(auth, 'getCurrentUser').and.returnValue({
        account_id: 1,
        accounts: [{ id: 1, role: 'agent' }],
      });
      const to = { name: 'login' };
      const from = { name: '', params: { accountId: 1 } };
      const next = jest.fn();
      // Act
      validateAuthenticateRoutePermission(to, from, next);
      // Assert
      expect(next).toHaveBeenCalledWith('/app/accounts/1/dashboard');
    });
  });
  describe(`when route is protected`, () => {
    describe(`when user not logged in`, () => {
      it(`should redirect to login`, () => {
        // Arrange
        spyOn(auth, 'isLoggedIn').and.returnValue(false);
        spyOn(auth, 'getCurrentUser').and.returnValue(null);
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
          spyOn(auth, 'isLoggedIn').and.returnValue(true);
          spyOn(auth, 'getCurrentUser').and.returnValue({
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
          spyOn(auth, 'isLoggedIn').and.returnValue(true);
          spyOn(auth, 'getCurrentUser').and.returnValue({
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
