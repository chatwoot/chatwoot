import { frontendURL } from '../../../helper/URLHelper';
import {
  ROLES,
  CONVERSATION_PERMISSIONS,
} from 'dashboard/constants/permissions.js';

import account from './account/account.routes';
import agent from './agents/agent.routes';
import assignmentPolicy from './assignmentPolicy/assignmentPolicy.routes';
import agentBot from './agentBots/agentBot.routes';
import attributes from './attributes/attributes.routes';
import automation from './automation/automation.routes';
import auditlogs from './auditlogs/audit.routes';
import billing from './billing/billing.routes';
import canned from './canned/canned.routes';
import inbox from './inbox/inbox.routes';
import integrations from './integrations/integrations.routes';
import labels from './labels/labels.routes';
    ...integrations.routes,
    ...labels.routes,
    ...reports.routes,
    ...sla.routes,
    ...teams.routes,
    ...customRoles.routes,
    ...profile.routes,
    ...security.routes,
    ...captain.routes,
  ],
};
