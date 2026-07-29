import { describe, expect, it, vi } from 'vitest';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';

const mocks = vi.hoisted(() => ({
  currentUser: {
    accounts: [],
  },
}));

vi.mock('dashboard/store', () => ({
  default: {
    getters: {
      getCurrentUser: mocks.currentUser,
    },
  },
}));

import integrationsRoutes, {
  redirectShopifyIfUnavailable,
} from '../integrations.routes';

vi.mock('../../SettingsWrapper.vue', () => ({ default: {} }));
vi.mock('../IntegrationHooks.vue', () => ({ default: {} }));
vi.mock('../Index.vue', () => ({ default: {} }));
vi.mock('../Webhooks/Index.vue', () => ({ default: {} }));
vi.mock('../DashboardApps/Index.vue', () => ({ default: {} }));
vi.mock('../Slack.vue', () => ({ default: {} }));
vi.mock('../Linear.vue', () => ({ default: {} }));
vi.mock('../Notion.vue', () => ({ default: {} }));
vi.mock('../Shopify.vue', () => ({ default: {} }));

describe('integration settings routes', () => {
  it('protects the Shopify route with the Shopify feature flag', () => {
    const shopifyRoute = integrationsRoutes.routes
      .flatMap(route => route.children || [])
      .find(route => route.name === 'settings_integrations_shopify');

    expect(shopifyRoute.meta.featureFlag).toBe(FEATURE_FLAGS.SHOPIFY);
    expect(shopifyRoute.beforeEnter).toBe(redirectShopifyIfUnavailable);
  });

  it('redirects direct navigation when Shopify is disabled', () => {
    mocks.currentUser.accounts = [{ id: 1, features: [] }];
    const next = vi.fn();

    redirectShopifyIfUnavailable(
      { params: { accountId: '1' } },
      undefined,
      next
    );

    expect(next).toHaveBeenCalledWith({
      name: 'settings_applications',
      params: { accountId: '1' },
    });
  });

  it('allows direct navigation when Shopify is enabled', () => {
    mocks.currentUser.accounts = [{ id: 1, features: [FEATURE_FLAGS.SHOPIFY] }];
    const next = vi.fn();

    redirectShopifyIfUnavailable(
      { params: { accountId: '1' } },
      undefined,
      next
    );

    expect(next).toHaveBeenCalledWith(undefined);
  });
});
