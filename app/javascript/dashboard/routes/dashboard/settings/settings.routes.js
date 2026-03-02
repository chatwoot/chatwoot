import { frontendURL } from '../../../helper/URLHelper';
import {
  ROLES,
  CONVERSATION_PERMISSIONS,
} from 'dashboard/constants/permissions.js';

import account from './account/account.routes';
import agent from './agents/agent.routes';
import aloo from './aloo/aloo.routes';
import assignmentPolicy from './assignmentPolicy/assignmentPolicy.routes';
import attributes from './attributes/attributes.routes';
import automation from './automation/automation.routes';
import auditlogs from './auditlogs/audit.routes';
import billing from './billing/billing.routes';
import canned from './canned/canned.routes';
import catalog from './catalog/catalog.routes';
import paymentLinkSettings from './payment-link-settings/paymentLinkSettings.routes';
import inbox from './inbox/inbox.routes';
import integrations from './integrations/integrations.routes';
import labels from './labels/labels.routes';
import macros from './macros/macros.routes';
import reports from './reports/reports.routes';
import store from '../../../store';
import sla from './sla/sla.routes';
import teams from './teams/teams.routes';
import customRoles from './customRoles/customRole.routes';
import profile from './profile/profile.routes';
import security from './security/security.routes';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings'),
      name: 'settings_home',
      meta: {
        permissions: [...ROLES, ...CONVERSATION_PERMISSIONS],
      },
      redirect: to => {
        if (
          store.getters.getCurrentRole === 'administrator' &&
          store.getters.getCurrentCustomRoleId === null
        ) {
          return { name: 'general_settings_index', params: to.params };
        }

        return { name: 'canned_list', params: to.params };
      },
    },
    ...account.routes,
    ...agent.routes,
    ...aloo.routes,
    ...assignmentPolicy.routes,
    ...attributes.routes,
    ...automation.routes,
    ...auditlogs.routes,
    ...billing.routes,
    ...canned.routes,
    ...catalog.routes,
    ...paymentLinkSettings.routes,
    ...inbox.routes,
    ...integrations.routes,
    ...labels.routes,
    ...macros.routes,
    ...reports.routes,
    ...sla.routes,
    ...teams.routes,
    ...customRoles.routes,
    ...profile.routes,
    ...security.routes,
  ],
};
