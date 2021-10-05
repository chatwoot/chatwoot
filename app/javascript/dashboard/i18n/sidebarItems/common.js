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
      icon: 'ion-chatbox-working',
      label: 'CONVERSATIONS',
      hasSubMenu: false,
      key: '',
      toState: frontendURL(`accounts/${accountId}/dashboard`),
      toolTip: 'Conversation from all subscribed inboxes',
      toStateName: 'home',
    },
    contacts: {
      icon: 'ion-person',
      label: 'CONTACTS',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/contacts`),
      toStateName: 'contacts_dashboard',
    },
    notifications: {
      icon: 'ion-ios-bell',
      label: 'NOTIFICATIONS',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/notifications`),
      toStateName: 'notifications_dashboard',
    },
    report: {
      icon: 'ion-arrow-graph-up-right',
      label: 'REPORTS',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/reports`),
      toStateName: 'settings_account_reports',
    },
    campaigns: {
      icon: 'ion-speakerphone',
      label: 'CAMPAIGNS',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/campaigns`),
      toStateName: 'settings_account_campaigns',
    },
    settings: {
      icon: 'ion-settings',
      label: 'SETTINGS',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/settings`),
      toStateName: 'settings_home',
    },
  },
});

export default common;
