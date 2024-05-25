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
      meta: {
        permissions: ['account_manage'],
      },
      toStateName: 'account_overview_reports',
    },
    {
      icon: 'chat',
      label: 'REPORTS_CONVERSATION',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/reports/conversation`),
      meta: {
        permissions: ['account_manage'],
      },
      toStateName: 'conversation_reports',
    },
    {
      icon: 'emoji',
      label: 'CSAT',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/reports/csat`),
      meta: {
        permissions: ['account_manage'],
      },
      toStateName: 'csat_reports',
    },
    {
      icon: 'bot',
      label: 'REPORTS_BOT',
      hasSubMenu: false,
      featureFlag: FEATURE_FLAGS.RESPONSE_BOT,
      toState: frontendURL(`accounts/${accountId}/reports/bot`),
      meta: {
        permissions: ['account_manage'],
      },
      toStateName: 'bot_reports',
    },
    {
      icon: 'people',
      label: 'REPORTS_AGENT',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/reports/agent`),
      meta: {
        permissions: ['account_manage'],
      },
      toStateName: 'agent_reports',
    },
    {
      icon: 'tag',
      label: 'REPORTS_LABEL',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/reports/label`),
      meta: {
        permissions: ['account_manage'],
      },
      toStateName: 'label_reports',
    },
    {
      icon: 'mail-inbox-all',
      label: 'REPORTS_INBOX',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/reports/inboxes`),
      meta: {
        permissions: ['account_manage'],
      },
      toStateName: 'inbox_reports',
    },
    {
      icon: 'people-team',
      label: 'REPORTS_TEAM',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/reports/teams`),
      meta: {
        permissions: ['account_manage'],
      },
      toStateName: 'team_reports',
    },
    {
      icon: 'document-list-clock',
      label: 'REPORTS_SLA',
      hasSubMenu: false,
      featureFlag: FEATURE_FLAGS.SLA,
      toState: frontendURL(`accounts/${accountId}/reports/sla`),
      meta: {
        permissions: ['account_manage'],
      },
      toStateName: 'sla_reports',
    },
  ],
});

export default reports;
