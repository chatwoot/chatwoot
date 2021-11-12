import { frontendURL } from '../../helper/URLHelper';

const settings = accountId => ({
  routes: [
    'agent_list',
    'canned_list',
    'labels_list',
    'settings_inbox',
    'attributes_list',
    'settings_inbox_new',
    'settings_inbox_list',
    'settings_inbox_show',
    'settings_inboxes_page_channel',
    'settings_inboxes_add_agents',
    'settings_inbox_finish',
    'settings_integrations',
    'settings_integrations_webhook',
    'settings_integrations_integration',
    'settings_applications',
    'settings_applications_webhook',
    'settings_applications_integration',
    'general_settings',
    'general_settings_index',
    'settings_teams_list',
    'settings_teams_new',
    'settings_teams_add_agents',
    'settings_teams_finish',
    'settings_teams_edit',
    'settings_teams_edit_members',
    'settings_teams_edit_finish',
  ],
  menuItems: {
    back: {
      icon: 'ion-ios-arrow-back',
      label: 'HOME',
      hasSubMenu: false,
      toStateName: 'home',
      toState: frontendURL(`accounts/${accountId}/dashboard`),
    },
    agents: {
      icon: 'ion-person-stalker',
      label: 'AGENTS',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/settings/agents/list`),
      toStateName: 'agent_list',
    },
    teams: {
      icon: 'ion-ios-people',
      label: 'TEAMS',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/settings/teams/list`),
      toStateName: 'settings_teams_list',
    },
    inboxes: {
      icon: 'ion-archive',
      label: 'INBOXES',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/settings/inboxes/list`),
      toStateName: 'settings_inbox_list',
    },
    labels: {
      icon: 'ion-pricetags',
      label: 'LABELS',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/settings/labels/list`),
      toStateName: 'labels_list',
    },
    attributes: {
      icon: 'ion-code',
      label: 'CUSTOM_ATTRIBUTES',
      hasSubMenu: false,
      toState: frontendURL(
        `accounts/${accountId}/settings/custom-attributes/list`
      ),
      toStateName: 'attributes_list',
    },
    cannedResponses: {
      icon: 'ion-chatbox-working',
      label: 'CANNED_RESPONSES',
      hasSubMenu: false,
      toState: frontendURL(
        `accounts/${accountId}/settings/canned-response/list`
      ),
      toStateName: 'canned_list',
    },
    settings_integrations: {
      icon: 'ion-flash',
      label: 'INTEGRATIONS',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/settings/integrations`),
      toStateName: 'settings_integrations',
    },
    settings_applications: {
      icon: 'ion-asterisk',
      label: 'APPLICATIONS',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/settings/applications`),
      toStateName: 'settings_applications',
    },
    general_settings_index: {
      icon: 'ion-gear-a',
      label: 'ACCOUNT_SETTINGS',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/settings/general`),
      toStateName: 'general_settings_index',
    },
  },
});

export default settings;
