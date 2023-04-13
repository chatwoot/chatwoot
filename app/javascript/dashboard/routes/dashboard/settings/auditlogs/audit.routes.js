import SettingsContent from '../Wrapper';
import AuditLogsHome from './Index';
import { frontendURL } from '../../../../helper/URLHelper';

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
          name: 'auditlogs_wrapper',
          redirect: 'list',
        },
        {
          path: 'list',
          name: 'auditlogs_list',
          roles: ['administrator'],
          component: AuditLogsHome,
        },
      ],
    },
  ],
};
