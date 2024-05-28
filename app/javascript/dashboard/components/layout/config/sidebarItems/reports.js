import { FEATURE_FLAGS } from '../../../../featureFlags';
import { frontendURL } from '../../../../helper/URLHelper';

const reports = accountId => ({
  parentNav: 'reports',
  routes: [
    'account_overview_reports',
    'conversation_reports',
    'csat_reports',
    'bot_reports',
    'agent_reports',
    'label_reports',
    'inbox_reports',
    'team_reports',
    'sla_reports',
  ],
  menuItems: [
    {
      icon: 'arrow-trending-lines',
      label: 'REPORTS_OVERVIEW',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/reports/overview`),
      toStateName: 'account_overview_reports',
    },
    {
      icon: 'chat',
      label: 'REPORTS_CONVERSATION',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/reports/conversation`),
      toStateName: 'conversation_reports',
    },
    {
      icon: 'emoji',
      label: 'CSAT',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/reports/csat`),
      toStateName: 'csat_reports',
    },
    {
      icon: 'bot',
      label: 'REPORTS_BOT',
      hasSubMenu: false,
      featureFlag: FEATURE_FLAGS.RESPONSE_BOT,
      toState: frontendURL(`accounts/${accountId}/reports/bot`),
      toStateName: 'bot_reports',
    },
    {
      icon: 'people',
      label: 'REPORTS_AGENT',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/reports/agent`),
      toStateName: 'agent_reports',
    },
    {
      icon: 'tag',
      label: 'REPORTS_LABEL',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/reports/label`),
      toStateName: 'label_reports',
    },
    {
      icon: 'mail-inbox-all',
      label: 'REPORTS_INBOX',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/reports/inboxes`),
      toStateName: 'inbox_reports',
    },
    {
      icon: 'people-team',
      label: 'REPORTS_TEAM',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/reports/teams`),
      toStateName: 'team_reports',
    },
    {
      icon: 'document-list-clock',
      label: 'REPORTS_SLA',
      hasSubMenu: false,
      featureFlag: FEATURE_FLAGS.SLA,
      toState: frontendURL(`accounts/${accountId}/reports/sla`),
      toStateName: 'sla_reports',
    },
  ],
});

export default reports;
