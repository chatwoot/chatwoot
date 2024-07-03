import { AdminRoles } from '../../../../featureFlags';
import { frontendURL } from '../../../../helper/URLHelper';
const SettingsContent = () => import('../Wrapper.vue');
const Index = () => import('./Index.vue');

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/general'),
      roles: AdminRoles,
      component: SettingsContent,
      props: {
        headerTitle: 'GENERAL_SETTINGS.TITLE',
        icon: 'briefcase',
        showNewButton: false,
      },
      children: [
        {
          path: '',
          name: 'general_settings_index',
          component: Index,
          roles: AdminRoles,
        },
      ],
    },
  ],
};
