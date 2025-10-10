import { frontendURL } from '../../../../helper/URLHelper';
import { ROLES } from 'dashboard/constants/permissions.js';

const SettingsContent = () => import('../Wrapper.vue');
const TemplatesHome = () => import('./Index.vue');

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/templates'),
      component: SettingsContent,
      props: {
        headerTitle: 'TEMPLATES.HEADER',
        icon: 'document-duplicate',
        showNewButton: false,
      },
      children: [
        {
          path: '',
          name: 'templates_list',
          meta: {
            permissions: ROLES,
          },
          component: TemplatesHome,
        },
      ],
    },
  ],
};
