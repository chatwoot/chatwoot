import { describe, expect, it, vi } from 'vitest';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';

const mocks = vi.hoisted(() => ({
  dispatch: vi.fn(),
  getAccount: vi.fn(),
  isFeatureEnabled: vi.fn(),
}));

vi.mock('dashboard/store', () => ({
  default: {
    dispatch: mocks.dispatch,
    getters: {
      'accounts/getAccount': mocks.getAccount,
      'accounts/isFeatureEnabledonAccount': mocks.isFeatureEnabled,
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
vi.mock('../Stripe.vue', () => ({ default: {} }));
vi.mock('../Linear.vue', () => ({ default: {} }));
vi.mock('../Notion.vue', () => ({ default: {} }));
vi.mock('../Shopify.vue', () => ({ default: {} }));
vi.mock('../GoogleTranslate.vue', () => ({ default: {} }));

describe('integration settings routes', () => {
  beforeEach(() => {
    mocks.dispatch.mockReset();
    mocks.getAccount.mockReset().mockReturnValue({ id: 1 });
    mocks.isFeatureEnabled.mockReset();
  });

  it('protects the Shopify route with the shared availability guard', () => {
    const shopifyRoute = integrationsRoutes.routes
      .flatMap(route => route.children || [])
      .find(route => route.name === 'settings_integrations_shopify');

    expect(shopifyRoute.meta.featureFlag).toBeUndefined();
    expect(shopifyRoute.beforeEnter).toBe(redirectShopifyIfUnavailable);
  });

  it('redirects direct navigation when Shopify is disabled', async () => {
    mocks.isFeatureEnabled.mockReturnValue(false);
    const next = vi.fn();

    await redirectShopifyIfUnavailable(
      { params: { accountId: '1' } },
      undefined,
      next
    );

    expect(next).toHaveBeenCalledWith({
      name: 'settings_applications',
      params: { accountId: '1' },
    });
    expect(mocks.isFeatureEnabled).toHaveBeenCalledWith(
      1,
      FEATURE_FLAGS.SHOPIFY
    );
  });

  it.each([
    [true, false],
    [false, true],
    [true, true],
  ])('allows navigation with main=%s and custom=%s', async (main, custom) => {
    mocks.isFeatureEnabled.mockImplementation((accountId, flag) =>
      flag === FEATURE_FLAGS.SHOPIFY ? main : custom
    );
    const next = vi.fn();

    await redirectShopifyIfUnavailable(
      { params: { accountId: '1' } },
      undefined,
      next
    );

    expect(next).toHaveBeenCalledWith(undefined);
  });

  it('loads a missing account before evaluating its feature gate', async () => {
    mocks.getAccount.mockReturnValue({});
    mocks.dispatch.mockResolvedValue();
    mocks.isFeatureEnabled.mockReturnValue(true);
    const next = vi.fn();

    await redirectShopifyIfUnavailable(
      { params: { accountId: '1' } },
      undefined,
      next
    );

    expect(mocks.dispatch).toHaveBeenCalledWith('accounts/get', {
      accountId: 1,
      silent: true,
    });
    expect(next).toHaveBeenCalledWith(undefined);
  });
});
