import { frontendURL } from '../../../../helper/URLHelper';
const SettingsContent = () => import('../Wrapper.vue');
const AttributesHome = () => import('./Index.vue');

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/custom-attributes'),
      component: SettingsContent,
      props: {
        headerTitle: 'ATTRIBUTES_MGMT.HEADER',
        icon: 'code',
        showNewButton: false,
      },
      children: [
        {
          path: '',
          redirect: 'list',
        },
        {
          path: 'list',
          name: 'attributes_list',
          component: AttributesHome,
          meta: {
            permissions: ['administrator'],
          },
        },
      ],
    },
  ],
};
