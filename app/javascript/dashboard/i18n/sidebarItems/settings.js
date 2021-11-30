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
    'automation_list',
  ],
  menuItems: {
    back: {
      icon: 'chevron-left',
      label: 'HOME',
      hasSubMenu: false,
      toStateName: 'home',
      toState: frontendURL(`accounts/${accountId}/dashboard`),
    },
    agents: {
      icon: 'people',
      label: 'AGENTS',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/settings/agents/list`),
      toStateName: 'agent_list',
    },
    teams: {
      icon: 'people-team',
      label: 'TEAMS',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/settings/teams/list`),
      toStateName: 'settings_teams_list',
    },
    inboxes: {
      icon: 'mail-inbox-all',
      label: 'INBOXES',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/settings/inboxes/list`),
      toStateName: 'settings_inbox_list',
    },
    labels: {
      icon: 'tag',
      label: 'LABELS',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/settings/labels/list`),
      toStateName: 'labels_list',
    },
    attributes: {
      icon: 'code',
      label: 'CUSTOM_ATTRIBUTES',
      hasSubMenu: false,
      toState: frontendURL(
        `accounts/${accountId}/settings/custom-attributes/list`
      ),
      toStateName: 'attributes_list',
    },
    automation: {
      icon: 'autocorrect',
      label: 'AUTOMATION',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/settings/automation/list`),
      toStateName: 'automation_list',
    },
    cannedResponses: {
      icon: 'chat-multiple',
      label: 'CANNED_RESPONSES',
      hasSubMenu: false,
      toState: frontendURL(
        `accounts/${accountId}/settings/canned-response/list`
      ),
      toStateName: 'canned_list',
    },
    settings_integrations: {
      icon: 'flash-on',
      label: 'INTEGRATIONS',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/settings/integrations`),
      toStateName: 'settings_integrations',
    },
    settings_applications: {
      icon: 'star-emphasis',
      label: 'APPLICATIONS',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/settings/applications`),
      toStateName: 'settings_applications',
    },
    general_settings_index: {
      icon: 'settings',
      label: 'ACCOUNT_SETTINGS',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/settings/general`),
      toStateName: 'general_settings_index',
    },
  },
});

export default settings;
