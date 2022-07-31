import Index from './Index';
import SettingsContent from '../Wrapper';
import Webhook from './Webhook';
import Shopify from './Shopify';
import ShowIntegration from './ShowIntegration';
import { frontendURL } from '../../../../helper/URLHelper';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/integrations'),
      component: SettingsContent,
      props: params => {
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
          path: '',
          name: 'settings_integrations',
          component: Index,
          roles: ['administrator'],
        },
        {
          path: 'webhook',
          component: Webhook,
          name: 'settings_integrations_webhook',
          roles: ['administrator'],
        },
        {
          path: 'shopify',
          component: Shopify,
          name: 'settings_integrations_shopify',
          roles: ['administrator']
        },
        {
          path: ':integration_id',
          name: 'settings_integrations_integration',
          component: ShowIntegration,
          roles: ['administrator'],
          props: route => {
            return {
              integrationId: route.params.integration_id,
              code: route.query.code,
            };
          },
        },
      ],
    },
  ],
};
