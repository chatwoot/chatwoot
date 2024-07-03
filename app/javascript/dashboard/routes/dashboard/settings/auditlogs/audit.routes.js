import { frontendURL } from '../../../../helper/URLHelper';

const SettingsContent = () => import('../Wrapper.vue');
const AuditLogsHome = () => import('./Index.vue');

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/audit-log'),
      component: SettingsContent,
      props: {
        headerTitle: 'AUDIT_LOGS.HEADER',
        icon: 'key',
        showNewButton: false,
      },
      children: [
        {
          path: '',
          redirect: 'list',
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
