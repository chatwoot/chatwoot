import { frontendURL } from '../../../../helper/URLHelper';

const SettingsWrapper = () => import('../SettingsWrapper.vue');
const CannedHome = () => import('./Index.vue');

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/canned-response'),
      component: SettingsWrapper,
      children: [
        {
          path: '',
          redirect: 'list',
        },
        {
          path: 'list',
          name: 'canned_list',
          meta: {
            permissions: ['administrator', 'agent'],
          },
          component: CannedHome,
        },
      ],
    },
  ],
};
