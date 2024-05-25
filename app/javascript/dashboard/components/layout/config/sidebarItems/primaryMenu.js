import { FEATURE_FLAGS } from '../../../../featureFlags';
import { frontendURL } from '../../../../helper/URLHelper';

const primaryMenuItems = accountId => [
  {
    icon: 'mail-inbox',
    key: 'inboxView',
    label: 'INBOX_VIEW',
    featureFlag: FEATURE_FLAGS.INBOX_VIEW,
    toState: frontendURL(`accounts/${accountId}/inbox-view`),
    toStateName: 'inbox_view',
    meta: {
      permissions: [
        'account_manage',
        'conversation_manage',
        'conversation_participating_manage',
        'conversation_unassigned_manage',
      ],
    },
  },
  {
    icon: 'chat',
    key: 'conversations',
    label: 'CONVERSATIONS',
    toState: frontendURL(`accounts/${accountId}/dashboard`),
    toStateName: 'home',
    meta: {
      permissions: [
        'account_manage',
        'conversation_manage',
        'conversation_participating_manage',
        'conversation_unassigned_manage',
      ],
    },
  },
  {
    icon: 'book-contacts',
    key: 'contacts',
    label: 'CONTACTS',
    featureFlag: FEATURE_FLAGS.CRM,
    toState: frontendURL(`accounts/${accountId}/contacts`),
    toStateName: 'contacts_dashboard',
    meta: {
      permissions: [
        'account_manage',
        'conversation_manage',
        'conversation_participating_manage',
        'conversation_unassigned_manage',
      ],
    },
  },
  {
    icon: 'arrow-trending-lines',
    key: 'reports',
    label: 'REPORTS',
    featureFlag: FEATURE_FLAGS.REPORTS,
    toState: frontendURL(`accounts/${accountId}/reports`),
    toStateName: 'settings_account_reports',
    meta: {
      permissions: ['account_manage'],
    },
  },
  {
    icon: 'megaphone',
    key: 'campaigns',
    label: 'CAMPAIGNS',
    featureFlag: FEATURE_FLAGS.CAMPAIGNS,
    toState: frontendURL(`accounts/${accountId}/campaigns`),
    toStateName: 'ongoing_campaigns',
    meta: {
      permissions: ['account_manage'],
    },
  },
  {
    icon: 'library',
    key: 'helpcenter',
    label: 'HELP_CENTER.TITLE',
    featureFlag: FEATURE_FLAGS.HELP_CENTER,
    alwaysVisibleOnChatwootInstances: true,
    toState: frontendURL(`accounts/${accountId}/portals`),
    toStateName: 'default_portal_articles',
    meta: {
      permissions: ['account_manage'],
    },
  },
  {
    icon: 'settings',
    key: 'settings',
    label: 'SETTINGS',
    toState: frontendURL(`accounts/${accountId}/settings`),
    toStateName: 'settings_home',
    meta: {
      permissions: [
        'account_manage',
        'conversation_manage',
        'conversation_participating_manage',
        'conversation_unassigned_manage',
      ],
    },
  },
];

export default primaryMenuItems;
