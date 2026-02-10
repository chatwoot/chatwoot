import { frontendURL } from '../../../../helper/URLHelper';
import Index from './Index.vue';
import SettingsWrapper from '../SettingsWrapper.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/catalog'),
      meta: {
        permissions: ['administrator', 'agent'],
      },
      component: SettingsWrapper,
      children: [
        {
          path: '',
          name: 'catalog_settings_index',
          component: Index,
          meta: {
            permissions: ['administrator', 'agent'],
          },
        },
      ],
    },
  ],
};
