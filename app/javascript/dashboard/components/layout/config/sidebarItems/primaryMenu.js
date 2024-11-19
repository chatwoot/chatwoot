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
  },
  {
    icon: 'chat',
    key: 'conversations',
    label: 'CONVERSATIONS',
    toState: frontendURL(`accounts/${accountId}/dashboard`),
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
    toStateName: 'contacts_dashboard',
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
    icon: 'megaphone',
    key: 'campaigns',
    label: 'CAMPAIGNS',
    featureFlag: FEATURE_FLAGS.CAMPAIGNS,
    toState: frontendURL(`accounts/${accountId}/campaigns`),
    toStateName: 'campaigns_ongoing_index',
  },
  {
    icon: 'library',
    key: 'helpcenter',
    label: 'HELP_CENTER.TITLE',
    featureFlag: FEATURE_FLAGS.HELP_CENTER,
    alwaysVisibleOnChatwootInstances: true,
    toState: frontendURL(`accounts/${accountId}/portals/portal_articles_index`),
    toStateName: 'portals_index',
  },
  {
    icon: 'settings',
    key: 'settings',
    label: 'SETTINGS',
    toState: frontendURL(`accounts/${accountId}/settings`),
    toStateName: 'settings_home',
  },
];

export default primaryMenuItems;
