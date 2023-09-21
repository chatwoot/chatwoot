import Index from './Index.vue';
import SettingsContent from '../Wrapper.vue';
import Webhook from './Webhooks/Index.vue';
import DashboardApps from './DashboardApps/Index.vue';
import ShowIntegration from './ShowIntegration.vue';
import Slack from './Slack.vue';
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
          path: 'dashboard-apps',
          component: DashboardApps,
          name: 'settings_integrations_dashboard_apps',
          roles: ['administrator'],
        },
        {
          path: 'slack',
          name: 'settings_integrations_slack',
          component: Slack,
          roles: ['administrator'],
          props: route => ({ code: route.query.code }),
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
