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
          roles: ['administrator'],
          redirect: 'list',
        },
        {
          path: 'list',
          name: 'sla_list',
          roles: ['administrator'],
          component: Index,
        },
      ],
    },
  ],
};
