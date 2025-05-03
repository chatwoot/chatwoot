import { FEATURE_FLAGS } from '../../../../featureFlags';
import { frontendURL } from '../../../../helper/URLHelper';

const primaryMenuItems = accountId => [
  {
    icon: 'chat',
    key: 'conversations',
    label: 'CONVERSATIONS',
    toState: frontendURL(`accounts/${accountId}/dashboard`),
    toStateName: 'home',
  },
  {
    icon: 'mail-inbox',
    key: 'inbox',
    label: 'INBOX',
    toState: frontendURL(`accounts/${accountId}/settings/inboxes/list`),
    toStateName: 'home',
  },
  {
    icon: 'captain',
    key: 'captain',
    label: 'CAPTAIN',
    featureFlag: FEATURE_FLAGS.CAPTAIN,
    toState: frontendURL(`accounts/${accountId}/captain/documents`),
    toStateName: 'captain',
  },
  {
    icon: 'book-contacts',
    key: 'contacts',
    label: 'CONTACTS',
    featureFlag: FEATURE_FLAGS.CRM,
    toState: frontendURL(`accounts/${accountId}/contacts`),
    toStateName: 'contacts_dashboard_index',
  },
  {
    icon: 'arrow-trending-lines',
    key: 'reports',
    label: 'REPORTS',
    featureFlag: FEATURE_FLAGS.REPORTS,
    toState: frontendURL(`accounts/${accountId}/reports`),
    toStateName: 'account_overview_reports',
  },
  {
    icon: 'bot',
    label: 'AI_AGENTS',
    hasSubMenu: false,
    meta: {
      permissions: ['administrator'],
    },
    toState: frontendURL(`accounts/${accountId}/ai-agents`),
    toStateName: 'ai_agents_index',
  },
  {
    icon: 'people',
    label: 'AGENTS',
    hasSubMenu: true,
    meta: {
      permissions: ['administrator'],
    },
    toState: frontendURL(`accounts/${accountId}/settings/agents/list`),
    toStateName: 'agent_list',
    featureFlag: FEATURE_FLAGS.AGENT_MANAGEMENT,
  },
  {
    icon: 'tag',
    label: 'LABELS',
    meta: {
      permissions: ['administrator'],
    },
    toState: frontendURL(`accounts/${accountId}/settings/labels/list`),
    toStateName: 'labels_list',
  },
  {
    icon: 'megaphone',
    key: 'campaigns',
    label: 'CAMPAIGNS',
    featureFlag: FEATURE_FLAGS.CAMPAIGNS,
    toState: frontendURL(`accounts/${accountId}/campaigns`),
    toStateName: 'campaigns_ongoing_index',
  },
  // {
  //   icon: 'library',
  //   key: 'helpcenter',
  //   label: 'HELP_CENTER.TITLE',
  //   featureFlag: FEATURE_FLAGS.HELP_CENTER,
  //   alwaysVisibleOnChatwootInstances: true,
  //   toState: frontendURL(`accounts/${accountId}/portals/portal_articles_index`),
  //   toStateName: 'portals_index',
  // },
  {
    icon: 'flash-on',
    label: 'INTEGRATIONS',
    hasSubMenu: false,
    meta: {
      permissions: ['administrator'],
    },
    toState: frontendURL(`accounts/${accountId}/settings/integrations`),
    toStateName: 'settings_applications',
    featureFlag: FEATURE_FLAGS.INTEGRATIONS,
  },
  {
    icon: 'key',
    label: 'AUDIT_LOGS',
    hasSubMenu: false,
    meta: {
      permissions: ['administrator'],
    },
    toState: frontendURL(`accounts/${accountId}/settings/audit-logs/list`),
    toStateName: 'auditlogs_list',
    isEnterpriseOnly: true,
    featureFlag: FEATURE_FLAGS.AUDIT_LOGS,
  },
  {
    icon: 'briefcase',
    label: 'ACCOUNT_SETTINGS',
    hasSubMenu: false,
    meta: {
      permissions: ['administrator'],
    },
    toState: frontendURL(`accounts/${accountId}/settings/general`),
    toStateName: 'general_settings_index',
  },
  {
    icon: 'credit-card-person',
    label: 'BILLING',
    hasSubMenu: false,
    meta: {
      permissions: ['administrator'],
    },
    toState: frontendURL(`accounts/${accountId}/settings/billing`),
    toStateName: 'billing_settings_index',
  },
];

export default primaryMenuItems;
