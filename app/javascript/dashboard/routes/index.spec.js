import { validateAuthenticateRoutePermission } from './index';
import store from '../store'; // This import will be mocked
import { vi } from 'vitest';

// Mock the store module
vi.mock('../store', () => ({
  default: {
    getters: {
      isLoggedIn: false,
      getCurrentUser: {
        account_id: null,
        id: null,
        accounts: [],
      },
    },
  },
}));

describe('#validateAuthenticateRoutePermission', () => {
  let next;

  beforeEach(() => {
    next = vi.fn(); // Mock the next function
  });

  describe('when user is not logged in', () => {
    it('should redirect to login', () => {
      const to = { name: 'some-protected-route', params: { accountId: 1 } };

      // Mock the store to simulate user not logged in
      store.getters.isLoggedIn = false;

      // Mock window.location.assign
      const mockAssign = vi.fn();
      delete window.location;
      window.location = { assign: mockAssign };

      validateAuthenticateRoutePermission(to, next);

      expect(mockAssign).toHaveBeenCalledWith('/app/login');
    });
  });

  describe('when user is logged in', () => {
    beforeEach(() => {
      // Mock the store's getter for a logged-in user
      store.getters.isLoggedIn = true;
      store.getters.getCurrentUser = {
        account_id: 1,
        id: 1,
        accounts: [
          {
            id: 1,
            role: 'agent',
            permissions: ['agent'],
            status: 'active',
          },
        ],
      };
    });

    describe('when route is not accessible to current user', () => {
      it('should redirect to dashboard', () => {
        const to = {
          name: 'general_settings_index',
          params: { accountId: 1 },
          meta: { permissions: ['administrator'] },
        };

        validateAuthenticateRoutePermission(to, next);

        expect(next).toHaveBeenCalledWith('/app/accounts/1/dashboard');
      });
    });

    describe('when route is accessible to current user', () => {
      beforeEach(() => {
        // Adjust store getters to reflect the user has admin permissions
        store.getters.getCurrentUser = {
          account_id: 1,
          id: 1,
          accounts: [
            {
              id: 1,
              role: 'administrator',
              permissions: ['administrator'],
              status: 'active',
            },
          ],
        };
      });

      it('should go to the intended route', () => {
        const to = {
          name: 'general_settings_index',
          params: { accountId: 1 },
          meta: { permissions: ['administrator'] },
        };

        validateAuthenticateRoutePermission(to, next);

        expect(next).toHaveBeenCalledWith();
      });
    });
  });
});
