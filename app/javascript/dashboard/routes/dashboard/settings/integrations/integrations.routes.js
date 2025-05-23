import { FEATURE_FLAGS } from '../../../../featureFlags';
import { frontendURL } from '../../../../helper/URLHelper';
import SettingsWrapper from '../SettingsWrapper.vue';
import IntegrationHooks from './IntegrationHooks.vue';
import Index from './Index.vue';
import Webhook from './Webhooks/Index.vue';
import DashboardApps from './DashboardApps/Index.vue';
import Slack from './Slack.vue';
import SettingsContent from '../Wrapper.vue';
import Linear from './Linear.vue';
import Shopify from './Shopify.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/integrations'),
      component: SettingsWrapper,
      props: {},
      children: [
        {
          path: '',
          name: 'settings_applications',
          component: Index,
          meta: {
            featureFlag: FEATURE_FLAGS.INTEGRATIONS,
            permissions: ['administrator'],
          },
        },
        {
          path: 'dashboard_apps',
          component: DashboardApps,
          name: 'settings_integrations_dashboard_apps',
          meta: {
            featureFlag: FEATURE_FLAGS.INTEGRATIONS,
            permissions: ['administrator'],
          },
        },
        {
          path: 'webhook',
          component: Webhook,
          name: 'settings_integrations_webhook',
          meta: {
            featureFlag: FEATURE_FLAGS.INTEGRATIONS,
            permissions: ['administrator'],
          },
        },
      ],
    },
    {
      path: frontendURL('accounts/:accountId/settings/integrations'),
      component: SettingsContent,
      props: params => {
        const integrationId = params.params?.integration_id;
        const hideHeader = ['dialogflow'].includes(integrationId);

        // Don't show header
        if (hideHeader) {
          return {};
        }

        const showBackButton = params.name !== 'settings_integrations';
        const backUrl =
          params.name === 'settings_integrations_integration'
            ? { name: 'settings_integrations' }
            : '';
        return {
          headerTitle: 'INTEGRATION_SETTINGS.HEADER',
          icon: 'flash-on',
          showBackButton,
          backUrl,
        };
      },
      children: [
        {
          path: 'slack',
          name: 'settings_integrations_slack',
          component: Slack,
          meta: {
            featureFlag: FEATURE_FLAGS.INTEGRATIONS,
            permissions: ['administrator'],
          },
          props: route => ({ code: route.query.code }),
        },
        {
          path: 'linear',
          name: 'settings_integrations_linear',
          component: Linear,
          meta: {
            permissions: ['administrator'],
          },
          props: route => ({ code: route.query.code }),
        },
        {
          path: 'shopify',
          name: 'settings_integrations_shopify',
          component: Shopify,
          meta: {
            featureFlag: FEATURE_FLAGS.INTEGRATIONS,
            permissions: ['administrator'],
          },
          props: route => ({ error: route.query.error }),
        },
        {
          path: ':integration_id',
          name: 'settings_applications_integration',
          component: IntegrationHooks,
          meta: {
            featureFlag: FEATURE_FLAGS.INTEGRATIONS,
            permissions: ['administrator'],
          },
          props: route => ({
            integrationId: route.params.integration_id,
          }),
        },
      ],
    },
  ],
};
