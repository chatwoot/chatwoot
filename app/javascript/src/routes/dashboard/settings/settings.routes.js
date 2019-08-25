import agent from './agents/agent.routes';
import inbox from './inbox/inbox.routes';
import canned from './canned/canned.routes';
import reports from './reports/reports.routes';
import billing from './billing/billing.routes';
import Auth from '../../../api/auth';
import { frontendURL } from '../../../helper/URLHelper';

export default {
  routes: [
    {
      path: frontendURL('settings'),
      name: 'settings_home',
      roles: ['administrator', 'agent'],
      redirect: () => {
        if (Auth.isAdmin()) {
          return frontendURL('settings/agents');
        }
        return frontendURL('settings/canned-response');
      },
    },
    ...inbox.routes,
    ...agent.routes,
    ...canned.routes,
    ...reports.routes,
    ...billing.routes,
  ],
};
