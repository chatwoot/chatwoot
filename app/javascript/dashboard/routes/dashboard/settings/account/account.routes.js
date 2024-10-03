import { frontendURL } from '../../../../helper/URLHelper';
import { defineAsyncComponent } from 'vue';
const SettingsContent = defineAsyncComponent(() => import('../Wrapper.vue'));
const Index = defineAsyncComponent(() => import('./Index.vue'));

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/general'),
      meta: {
        permissions: ['administrator'],
      },
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
          meta: {
            permissions: ['administrator'],
          },
        },
      ],
    },
  ],
};
