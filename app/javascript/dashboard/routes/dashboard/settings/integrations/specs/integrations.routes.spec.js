import { describe, expect, it, vi } from 'vitest';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import integrationsRoutes from '../integrations.routes';

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
  });
});
