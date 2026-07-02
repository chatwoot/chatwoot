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
      'accounts/getAccount': () => ({}),
    },
    dispatch: vi.fn(() => Promise.resolve()),
  },
}));

describe('#validateAuthenticateRoutePermission', () => {
  let next;

  beforeEach(() => {
    next = vi.fn(); // Mock the next function
  });

  describe('when user is not logged in', () => {
    it('should allow public routes that ignore session', async () => {
      const to = {
        name: 'accept_invitation',
        meta: { ignoreSession: true },
        query: {
          client_id: 'talkai',
          token: 'invitation-token',
        },
      };

      store.getters.isLoggedIn = false;

      await validateAuthenticateRoutePermission(to, next);

      expect(next).toHaveBeenCalledWith();
    });

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

    it('should complete SSO token login before redirecting', async () => {
      const to = {
        name: 'login',
        params: {},
        query: {
          email: 'agent@example.com',
          sso_auth_token: 'sso-token',
        },
      };
      const currentUser = {
        account_id: 7,
        id: 1,
        accounts: [{ id: 7, status: 'active', role: 'administrator' }],
      };

      store.getters.isLoggedIn = false;
      store.dispatch.mockResolvedValue(currentUser);

      await validateAuthenticateRoutePermission(to, next);

      expect(store.dispatch).toHaveBeenCalledWith('loginWithSso', {
        email: 'agent@example.com',
        ssoAuthToken: 'sso-token',
        redirectTo: undefined,
      });
      expect(next).toHaveBeenCalledWith('/app/accounts/7/dashboard');
    });

    it('should complete SSO token login and use safe redirect target', async () => {
      const to = {
        name: 'login',
        params: {},
        query: {
          email: 'agent@example.com',
          sso_auth_token: 'sso-token',
          redirect_to: '/app/accounts/7/autonomia/invite-connection',
        },
      };
      const currentUser = {
        account_id: 7,
        id: 1,
        accounts: [{ id: 7, status: 'active', role: 'administrator' }],
      };

      store.getters.isLoggedIn = false;
      store.dispatch.mockResolvedValue(currentUser);

      await validateAuthenticateRoutePermission(to, next);

      expect(next).toHaveBeenCalledWith(
        '/app/accounts/7/autonomia/invite-connection'
      );
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
      it('should redirect to dashboard', async () => {
        const to = {
          name: 'general_settings_index',
          params: { accountId: 1 },
          meta: { permissions: ['administrator'] },
        };

        await validateAuthenticateRoutePermission(to, next);

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

      it('should go to the intended route', async () => {
        const to = {
          name: 'general_settings_index',
          params: { accountId: 1 },
          meta: { permissions: ['administrator'] },
        };

        await validateAuthenticateRoutePermission(to, next);

        expect(next).toHaveBeenCalledWith();
      });
    });
  });
});
