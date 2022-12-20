import { FEATURE_FLAGS } from '../../../../featureFlags';
import { frontendURL } from '../../../../helper/URLHelper';

const primaryMenuItems = accountId => [
  {
    icon: 'chat',
    key: 'conversations',
    label: 'CONVERSATIONS',
    toState: frontendURL(`accounts/${accountId}/dashboard`),
    toStateName: 'home',
    roles: ['administrator', 'agent'],
  },
  {
    icon: 'book-contacts',
    key: 'contacts',
    label: 'CONTACTS',
    featureFlag: FEATURE_FLAGS.CRM,
    toState: frontendURL(`accounts/${accountId}/contacts`),
    toStateName: 'contacts_dashboard',
    roles: ['administrator', 'agent'],
  },
  {
    icon: 'arrow-trending-lines',
    key: 'reports',
    label: 'REPORTS',
    featureFlag: FEATURE_FLAGS.REPORTS,
    toState: frontendURL(`accounts/${accountId}/reports`),
    toStateName: 'settings_account_reports',
    roles: ['administrator'],
  },
  {
    icon: 'megaphone',
    key: 'campaigns',
    label: 'CAMPAIGNS',
    featureFlag: FEATURE_FLAGS.CAMPAIGNS,
    toState: frontendURL(`accounts/${accountId}/campaigns`),
    toStateName: 'settings_account_campaigns',
    roles: ['administrator'],
  },
  {
    icon: 'library',
    key: 'helpcenter',
    label: 'HELP_CENTER.TITLE',
    featureFlag: FEATURE_FLAGS.HELP_CENTER,
    toState: frontendURL(`accounts/${accountId}/portals`),
    toStateName: 'default_portal_articles',
    roles: ['administrator'],
  },
  {
    icon: 'settings',
    key: 'settings',
    label: 'SETTINGS',
    toState: frontendURL(`accounts/${accountId}/settings`),
    toStateName: 'settings_home',
    roles: ['administrator', 'agent'],
  },
];

export default primaryMenuItems;
