import { frontendURL } from '../../../../helper/URLHelper';

const SettingsContent = () => import('../Wrapper.vue');
const Webhook = () => import('./Webhooks/Index.vue');
const DashboardApps = () => import('./DashboardApps/Index.vue');
const ShowIntegration = () => import('./ShowIntegration.vue');
const Slack = () => import('./Slack.vue');
const Index = () => import('./Index.vue');

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
          meta: {
            permissions: ['administrator'],
          },
        },
        {
          path: 'webhook',
          component: Webhook,
          name: 'settings_integrations_webhook',
          meta: {
            permissions: ['administrator'],
          },
        },
        {
          path: 'dashboard-apps',
          component: DashboardApps,
          name: 'settings_integrations_dashboard_apps',
          meta: {
            permissions: ['administrator'],
          },
        },
        {
          path: 'slack',
          name: 'settings_integrations_slack',
          component: Slack,
          meta: {
            permissions: ['administrator'],
          },
          props: route => ({ code: route.query.code }),
        },
        {
          path: ':integration_id',
          name: 'settings_integrations_integration',
          component: ShowIntegration,
          meta: {
            permissions: ['administrator'],
          },
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
