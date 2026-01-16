import { frontendURL } from '../../../../helper/URLHelper';

import SettingsWrapper from '../SettingsWrapper.vue';
import Index from './index.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/locations'),
      component: SettingsWrapper,
      children: [
        {
          path: '',
          name: 'locations_wrapper',
          meta: {
            permissions: ['administrator'],
          },
          redirect: to => {
            return { name: 'locations_list', params: to.params };
          },
        },
        {
          path: 'list',
          name: 'locations_list',
          meta: {
            permissions: ['administrator', 'supervisor'],
          },
          component: Index,
        },
      ],
    },
  ],
};
