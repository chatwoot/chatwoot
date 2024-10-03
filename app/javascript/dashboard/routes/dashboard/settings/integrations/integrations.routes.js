import { frontendURL } from '../../../../helper/URLHelper';
import { defineAsyncComponent } from 'vue';

const SettingsWrapper = defineAsyncComponent(
  () => import('../SettingsWrapper.vue')
);
const IntegrationHooks = defineAsyncComponent(
  () => import('./IntegrationHooks.vue')
);
const Index = defineAsyncComponent(() => import('./Index.vue'));
const Webhook = defineAsyncComponent(() => import('./Webhooks/Index.vue'));
const DashboardApps = defineAsyncComponent(
  () => import('./DashboardApps/Index.vue')
);
const Slack = defineAsyncComponent(() => import('./Slack.vue'));
const SettingsContent = defineAsyncComponent(() => import('../Wrapper.vue'));

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
            permissions: ['administrator'],
          },
        },
        {
          path: 'dashboard_apps',
          component: DashboardApps,
          name: 'settings_integrations_dashboard_apps',
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
      ],
    },
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
          name: 'settings_applications_integration',
          component: IntegrationHooks,
          meta: {
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
