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
    it('should redirect to login', () => {
      const to = { name: 'some-protected-route', params: { accountId: 1 } };

      // Mock the store to simulate user not logged in
      store.getters.isLoggedIn = false;

      // Mock window.location.assign
      const mockAssign = vi.fn();
      delete window.location;
      window.location = { assign: mockAssign };

      validateAuthenticateRoutePermission({ query: {}, ...to }, next);

      expect(mockAssign).toHaveBeenCalledWith('/app/login');
    });

    it('preserves Shopify App Pricing return parameters through login', () => {
      const to = {
        query: {
          plan_handle: 'growth',
          shop: 'store.myshopify.com',
        },
      };
      store.getters.isLoggedIn = false;
      const mockAssign = vi.fn();
      delete window.location;
      window.location = { assign: mockAssign };

      validateAuthenticateRoutePermission({ query: {}, ...to }, next);

      expect(mockAssign).toHaveBeenCalledWith(
        '/app/login?redirect_url=settings%2Fbilling%3Fplan_handle%3Dgrowth%26shop%3Dstore.myshopify.com'
      );
    });

    it('preserves the target account for a Shopify reinstall through login', () => {
      const to = {
        params: { accountId: 42 },
        query: { shop: 'store.myshopify.com' },
      };
      store.getters.isLoggedIn = false;
      const mockAssign = vi.fn();
      delete window.location;
      window.location = { assign: mockAssign };

      validateAuthenticateRoutePermission({ query: {}, ...to }, next);

      expect(mockAssign).toHaveBeenCalledWith(
        '/app/login?sso_account_id=42&redirect_url=settings%2Fbilling%3Fshop%3Dstore.myshopify.com'
      );
    });

    it('preserves the Shopify integration destination through login', () => {
      const to = {
        name: 'settings_integrations_shopify',
        params: { accountId: 42 },
      };
      store.getters.isLoggedIn = false;
      const mockAssign = vi.fn();
      delete window.location;
      window.location = { assign: mockAssign };

      validateAuthenticateRoutePermission({ query: {}, ...to }, next);

      expect(mockAssign).toHaveBeenCalledWith(
        '/app/login?sso_account_id=42&redirect_url=settings%2Fintegrations%2Fshopify'
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

        await validateAuthenticateRoutePermission({ query: {}, ...to }, next);

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

        await validateAuthenticateRoutePermission({ query: {}, ...to }, next);

        expect(next).toHaveBeenCalledWith();
      });

      it('redirects a pending Shopify account to billing before onboarding', async () => {
        store.getters.getCurrentUser.accounts[0] = {
          ...store.getters.getCurrentUser.accounts[0],
          onboarding_step: 'account_details',
          billing_provider: 'shopify',
          shopify_integration: true,
          subscription_status: 'pending',
          shopify_shop_domain: 'store.myshopify.com',
        };
        const to = {
          name: 'general_settings_index',
          params: { accountId: 1 },
          meta: { permissions: ['administrator'] },
        };

        await validateAuthenticateRoutePermission({ query: {}, ...to }, next);

        expect(next).toHaveBeenCalledWith({
          path: '/app/accounts/1/settings/billing',
          query: {},
        });
      });

      it('preserves a Shopify pricing redirect for a pending account', async () => {
        store.getters.getCurrentUser.accounts[0] = {
          ...store.getters.getCurrentUser.accounts[0],
          billing_provider: 'shopify',
          shopify_integration: true,
          subscription_status: 'pending',
          shopify_shop_domain: 'store.myshopify.com',
        };
        const to = {
          query: {
            redirect_url:
              'settings/billing?plan_handle=growth&shop=store.myshopify.com',
          },
        };

        await validateAuthenticateRoutePermission({ query: {}, ...to }, next);

        expect(next).toHaveBeenCalledWith(
          '/app/accounts/1/settings/billing?plan_handle=growth&shop=store.myshopify.com'
        );
      });

      it('routes a Shopify pricing redirect to the account connected to that shop', async () => {
        store.getters.getCurrentUser.accounts.push({
          id: 2,
          role: 'administrator',
          permissions: ['administrator'],
          status: 'active',
          billing_provider: 'shopify',
          shopify_integration: true,
          subscription_status: 'pending',
          shopify_shop_domain: 'second-store.myshopify.com',
        });
        const to = {
          query: {
            redirect_url:
              'settings/billing?plan_handle=growth&shop=second-store.myshopify.com',
          },
        };

        await validateAuthenticateRoutePermission({ query: {}, ...to }, next);

        expect(next).toHaveBeenCalledWith(
          '/app/accounts/2/settings/billing?plan_handle=growth&shop=second-store.myshopify.com'
        );
      });

      it('does not route an unknown Shopify shop to the active account', async () => {
        store.getters.getCurrentUser.accounts[0] = {
          ...store.getters.getCurrentUser.accounts[0],
          shopify_shop_domain: 'first-store.myshopify.com',
        };
        const to = {
          query: {
            redirect_url:
              'settings/billing?plan_handle=growth&shop=unknown-store.myshopify.com',
          },
        };

        await validateAuthenticateRoutePermission({ query: {}, ...to }, next);

        expect(next).toHaveBeenCalledWith('/app/accounts/1/dashboard');
      });

      it('allows a pending Shopify account to stay on billing', async () => {
        store.getters.getCurrentUser.accounts[0] = {
          ...store.getters.getCurrentUser.accounts[0],
          onboarding_step: 'account_details',
          billing_provider: 'shopify',
          shopify_integration: true,
          subscription_status: 'pending',
        };
        const to = {
          name: 'billing_settings_index',
          params: { accountId: 1 },
          meta: { permissions: ['administrator'] },
        };

        await validateAuthenticateRoutePermission({ query: {}, ...to }, next);

        expect(next).toHaveBeenCalledWith();
      });

      it('routes an entitled Shopify account return to billing with its parameters', async () => {
        store.getters.getCurrentUser.accounts[0] = {
          ...store.getters.getCurrentUser.accounts[0],
          billing_provider: 'shopify',
          shopify_integration: true,
          subscription_status: 'active',
          shopify_shop_domain: 'store.myshopify.com',
        };
        const to = {
          params: {},
          query: {
            plan_handle: 'growth',
            shop: 'store.myshopify.com',
          },
        };

        await validateAuthenticateRoutePermission({ query: {}, ...to }, next);

        expect(next).toHaveBeenCalledWith(
          '/app/accounts/1/settings/billing?plan_handle=growth&shop=store.myshopify.com'
        );
      });

      it('routes raw Shopify return parameters to the matching account', async () => {
        store.getters.getCurrentUser.accounts.push({
          id: 2,
          role: 'administrator',
          permissions: ['administrator'],
          status: 'active',
          billing_provider: 'shopify',
          shopify_integration: true,
          subscription_status: 'active',
          shopify_shop_domain: 'second-store.myshopify.com',
        });
        const to = {
          params: {},
          query: {
            plan_handle: 'growth',
            shop: 'second-store.myshopify.com',
          },
        };

        await validateAuthenticateRoutePermission({ query: {}, ...to }, next);

        expect(next).toHaveBeenCalledWith(
          '/app/accounts/2/settings/billing?plan_handle=growth&shop=second-store.myshopify.com'
        );
      });

      it('does not use Shopify return parameters when the account gate is disabled', async () => {
        store.getters.getCurrentUser.accounts[0] = {
          ...store.getters.getCurrentUser.accounts[0],
          billing_provider: 'shopify',
          shopify_integration: false,
          subscription_status: 'active',
        };
        const to = {
          params: {},
          query: {
            plan_handle: 'growth',
            shop: 'store.myshopify.com',
          },
        };

        await validateAuthenticateRoutePermission({ query: {}, ...to }, next);

        expect(next).toHaveBeenCalledWith('/app/accounts/1/dashboard');
      });
    });

    describe('when continuing a Shopify install from an existing session', () => {
      const pendingInstallRedirect =
        'settings/integrations/shopify?shopify_pending_install=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

      it('requires an explicit workspace choice', async () => {
        store.getters.getCurrentUser = {
          account_id: 1,
          id: 1,
          accounts: [
            { id: 1, role: 'agent', status: 'active' },
            { id: 2, role: 'administrator', status: 'active' },
          ],
        };
        const to = {
          query: { redirect_url: pendingInstallRedirect },
          params: {},
        };

        await validateAuthenticateRoutePermission({ query: {}, ...to }, next);

        expect(next).toHaveBeenCalledWith(
          `/app/shopify/select-account?${pendingInstallRedirect.split('?')[1]}`
        );
      });

      it('retains the token when no account can manage Shopify', async () => {
        const to = {
          query: { redirect_url: pendingInstallRedirect },
          params: {},
        };

        await validateAuthenticateRoutePermission({ query: {}, ...to }, next);

        expect(next).toHaveBeenCalledWith(
          `/app/shopify/select-account?${pendingInstallRedirect.split('?')[1]}`
        );
      });
    });
  });
});
