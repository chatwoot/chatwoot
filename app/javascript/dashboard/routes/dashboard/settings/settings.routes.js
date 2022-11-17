import { frontendURL } from '../../../helper/URLHelper';
import account from './account/account.routes';
import agent from './agents/agent.routes';
import agentBot from './agentBots/agentBot.routes';
import attributes from './attributes/attributes.routes';
import automation from './automation/automation.routes';
import billing from './billing/billing.routes';
import campaigns from './campaigns/campaigns.routes';
import canned from './canned/canned.routes';
import inbox from './inbox/inbox.routes';
import integrationapps from './integrationapps/integrations.routes';
import integrations from './integrations/integrations.routes';
import labels from './labels/labels.routes';
import macros from './macros/macros.routes';
import profile from './profile/profile.routes';
import reports from './reports/reports.routes';
import store from '../../../store';
import teams from './teams/teams.routes';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings'),
      name: 'settings_home',
      roles: ['administrator', 'agent'],
      redirect: () => {
        if (store.getters.getCurrentRole === 'administrator') {
          return frontendURL('accounts/:accountId/settings/general');
        }
        return frontendURL('accounts/:accountId/settings/canned-response');
      },
    },
    ...account.routes,
    ...agent.routes,
    ...agentBot.routes,
    ...attributes.routes,
    ...automation.routes,
    ...billing.routes,
    ...campaigns.routes,
    ...canned.routes,
    ...inbox.routes,
    ...integrationapps.routes,
    ...integrations.routes,
    ...labels.routes,
    ...macros.routes,
    ...profile.routes,
    ...reports.routes,
    ...teams.routes,
  ],
};
