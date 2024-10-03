import { frontendURL } from '../../../../helper/URLHelper';

const SettingsWrapper = () => import('../SettingsWrapper.vue');
const AuditLogsHome = () => import('./Index.vue');

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/audit-logs'),
      component: SettingsWrapper,
      children: [
        {
          path: '',
          redirect: to => {
            return { name: 'auditlogs_list', params: to.params };
          },
        },
        {
          path: 'list',
          name: 'auditlogs_list',
          meta: {
            permissions: ['administrator'],
          },
          component: AuditLogsHome,
        },
      ],
    },
  ],
};
