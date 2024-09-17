import { frontendURL } from 'dashboard/helper/URLHelper';

const SettingsWrapper = () => import('../SettingsWrapper.vue');
const CustomRolesHome = () => import('./Index.vue');

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/custom-roles'),
      component: SettingsWrapper,
      children: [
        {
          path: '',
          redirect: 'list',
        },
        {
          path: 'list',
          name: 'custom_roles_list',
          meta: {
            permissions: ['administrator'],
          },
          component: CustomRolesHome,
        },
      ],
    },
  ],
};
