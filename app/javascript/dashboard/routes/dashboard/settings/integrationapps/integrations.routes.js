import { frontendURL } from '../../../../helper/URLHelper';
const SettingsContent = () => import('../Wrapper.vue');
const IntegrationHooks = () => import('./IntegrationHooks.vue');
const Index = () => import('./Index.vue');

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/applications'),
      component: SettingsContent,
      props: params => {
        const showBackButton = params.name !== 'settings_applications';
        const backUrl =
          params.name === 'settings_applications_integration'
            ? { name: 'settings_applications' }
            : '';
        return {
          headerTitle: 'INTEGRATION_APPS.HEADER',
          icon: 'star-emphasis',
          showBackButton,
          backUrl,
        };
      },
      children: [
        {
          path: '',
          name: 'settings_applications',
          component: Index,
          roles: ['administrator'],
        },
        {
          path: ':integration_id',
          name: 'settings_applications_integration',
          component: IntegrationHooks,
          roles: ['administrator'],
          props: route => ({
            integrationId: route.params.integration_id,
          }),
        },
      ],
    },
  ],
};
