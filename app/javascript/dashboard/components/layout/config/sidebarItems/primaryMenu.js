import { FEATURE_FLAGS } from '../../../../featureFlags';
import { frontendURL } from '../../../../helper/URLHelper';

const primaryMenuItems = accountId => [
  {
    icon: 'chat-new',
    key: 'conversations',
    label: 'CONVERSATIONS',
    toState: frontendURL(`accounts/${accountId}/dashboard`),
    toStateName: 'home',
  },
  {
    icon: 'mail-inbox-new',
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
    icon: 'book-contacts-new',
    key: 'contacts',
    label: 'CONTACTS',
    featureFlag: FEATURE_FLAGS.CRM,
    toState: frontendURL(`accounts/${accountId}/contacts`),
    toStateName: 'contacts_dashboard_index',
  },
  {
    icon: 'arrow-trending-lines-new',
    key: 'reports',
    label: 'REPORTS',
    featureFlag: FEATURE_FLAGS.REPORTS,
    toState: frontendURL(`accounts/${accountId}/reports`),
    toStateName: 'account_overview_reports',
  },
  {
    icon: 'bot-new',
    label: 'AI_AGENTS',
    hasSubMenu: false,
    meta: {
      permissions: ['administrator'],
    },
    toState: frontendURL(`accounts/${accountId}/ai-agents`),
    toStateName: 'ai_agents_index',
  },
  {
    icon: 'people-new',
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
    icon: 'tag-new',
    label: 'LABELS',
    meta: {
      permissions: ['administrator'],
    },
    toState: frontendURL(`accounts/${accountId}/settings/labels/list`),
    toStateName: 'labels_list',
  },
  {
    icon: 'megaphone-new',
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
    label: 'QUICK_REPLY',
    hasSubMenu: false,
    meta: {
      permissions: ['administrator'],
    },
    toState: frontendURL(`accounts/${accountId}/quick-replies`),
    toStateName: 'quick_reply_manage',
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
    icon: 'briefcase-new',
    label: 'ACCOUNT_SETTINGS',
    hasSubMenu: false,
    meta: {
      permissions: ['administrator'],
    },
    toState: frontendURL(`accounts/${accountId}/settings/general`),
    toStateName: 'general_settings_index',
  },
  {
    icon: 'credit-card-person-new',
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
