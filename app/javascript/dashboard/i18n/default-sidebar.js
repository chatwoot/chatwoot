import { frontendURL } from '../helper/URLHelper';

export default {
  common: {
    routes: [
      'home',
      'inbox_dashboard',
      'inbox_conversation',
      'settings_account_reports',
      'billing_deactivated',
    ],
    menuItems: {
      assignedToMe: {
        icon: 'ion-chatbox-working',
        label: 'Conversations',
        hasSubMenu: false,
        key: '',
        toState: frontendURL('dashboard'),
        toolTip: 'Conversation from all subscribed inboxes',
        toStateName: 'home',
      },
      report: {
        icon: 'ion-arrow-graph-up-right',
        label: 'Reports',
        hasSubMenu: false,
        toState: frontendURL('reports'),
        toStateName: 'settings_account_reports',
      },
      settings: {
        icon: 'ion-settings',
        label: 'Settings',
        hasSubMenu: false,
        toState: frontendURL('settings'),
        toStateName: 'settings_home',
      },
    },
  },
  settings: {
    routes: [
      'agent_list',
      'agent_new',
      'canned_list',
      'canned_new',
      'settings_inbox',
      'settings_inbox_new',
      'settings_inbox_list',
      'settings_inbox_show',
      'settings_inboxes_page_channel',
      'settings_inboxes_add_agents',
      'settings_inbox_finish',
      'billing',
    ],
    menuItems: {
      back: {
        icon: 'ion-ios-arrow-back',
        label: 'Home',
        hasSubMenu: false,
        toStateName: 'home',
        toState: frontendURL('dashboard'),
      },
      agents: {
        icon: 'ion-person-stalker',
        label: 'Agents',
        hasSubMenu: false,
        toState: frontendURL('settings/agents/list'),
        toStateName: 'agent_list',
      },
      inboxes: {
        icon: 'ion-archive',
        label: 'Inboxes',
        hasSubMenu: false,
        toState: frontendURL('settings/inboxes/list'),
        toStateName: 'settings_inbox_list',
      },
      cannedResponses: {
        icon: 'ion-chatbox-working',
        label: 'Canned Responses',
        hasSubMenu: false,
        toState: frontendURL('settings/canned-response/list'),
        toStateName: 'canned_list',
      },
      billing: {
        icon: 'ion-card',
        label: 'Billing',
        hasSubMenu: false,
        toState: frontendURL('settings/billing'),
        toStateName: 'billing',
      },
      account: {
        icon: 'ion-beer',
        label: 'Account Settings',
        hasSubMenu: false,
        toState: frontendURL('settings/account'),
        toStateName: 'account',
      },
    },
  },
};
