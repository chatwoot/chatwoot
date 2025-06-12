import { FEATURE_FLAGS } from '../../../../featureFlags';
import { INSTALLATION_TYPES } from 'dashboard/constants/installationTypes';
import { frontendURL } from '../../../../helper/URLHelper';

import SettingsWrapper from '../SettingsWrapper.vue';
import AuditLogsHome from './Index.vue';

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
            featureFlag: FEATURE_FLAGS.AUDIT_LOGS,
            installationTypes: [
              INSTALLATION_TYPES.CLOUD,
              INSTALLATION_TYPES.ENTERPRISE,
            ],
            permissions: ['administrator'],
          },
          component: AuditLogsHome,
        },
      ],
    },
  ],
};
