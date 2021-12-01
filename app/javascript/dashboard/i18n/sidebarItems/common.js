import { frontendURL } from '../../helper/URLHelper';

const common = accountId => ({
  routes: [
    'home',
    'inbox_dashboard',
    'inbox_conversation',
    'conversation_through_inbox',
    'notifications_dashboard',
    'profile_settings',
    'profile_settings_index',
    'label_conversations',
    'conversations_through_label',
    'team_conversations',
    'conversations_through_team',
    'notifications_index',
  ],
  menuItems: {
    assignedToMe: {
      icon: 'chat',
      label: 'CONVERSATIONS',
      hasSubMenu: true,
      key: 'conversations',
      toState: frontendURL(`accounts/${accountId}/dashboard`),
      toolTip: 'Conversation from all subscribed inboxes',
      toStateName: 'home',
    },
    contacts: {
      key: 'contacts',
      icon: 'book-contacts',
      label: 'CONTACTS',
      hasSubMenu: true,
      toState: frontendURL(`accounts/${accountId}/contacts`),
      toStateName: 'contacts_dashboard',
    },
    reports: {
      key: 'reports',
      icon: 'arrow-trending-lines',
      label: 'REPORTS',
      hasSubMenu: true,
      toState: frontendURL(`accounts/${accountId}/reports`),
      toStateName: 'settings_account_reports',
    },
    campaigns: {
      key: 'campaigns',
      icon: 'megaphone',
      label: 'CAMPAIGNS',
      hasSubMenu: true,
      toState: frontendURL(`accounts/${accountId}/campaigns`),
      toStateName: 'settings_account_campaigns',
    },
    settings: {
      key: 'settings',
      icon: 'settings',
      label: 'SETTINGS',
      hasSubMenu: true,
      toState: frontendURL(`accounts/${accountId}/settings`),
      toStateName: 'settings_home',
    },
  },
});

export default common;
