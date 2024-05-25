import { frontendURL } from '../../../../helper/URLHelper';

const SettingsWrapper = () => import('../SettingsWrapper.vue');
const Index = () => import('./Index.vue');

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/sla'),
      component: SettingsWrapper,
      props: {},
      children: [
        {
          path: '',
          name: 'sla_wrapper',
          meta: {
            permissions: ['account_manage'],
          },
          redirect: 'list',
        },
        {
          path: 'list',
          name: 'sla_list',
          meta: {
            permissions: ['account_manage'],
          },
          component: Index,
        },
      ],
    },
  ],
};
