import { frontendURL } from '../../../../helper/URLHelper';

const isFeatureEnabled = (featureFlags, key) => featureFlags[key];

const settings = (accountId, features) => {
  const config = {
    parentNav: 'settings',
    routes: [
      'agent_bots',
      'agent_list',
      'attributes_list',
      'automation_list',
      'canned_list',
      'general_settings_index',
      'general_settings',
      'labels_list',
      'settings_applications_integration',
      'settings_applications_webhook',
      'settings_applications',
      'settings_inbox_finish',
      'settings_inbox_list',
      'settings_inbox_new',
      'settings_inbox_show',
      'settings_inbox',
      'settings_inboxes_add_agents',
      'settings_inboxes_page_channel',
      'settings_integrations_integration',
      'settings_integrations_webhook',
      'settings_integrations',
      'settings_teams_add_agents',
      'settings_teams_edit_finish',
      'settings_teams_edit_members',
      'settings_teams_edit',
      'settings_teams_finish',
      'settings_teams_list',
      'settings_teams_new',
    ],
    menuItems: [
      {
        icon: 'people',
        label: 'AGENTS',
        hasSubMenu: false,
        toState: frontendURL(`accounts/${accountId}/settings/agents/list`),
        toStateName: 'agent_list',
      },
      {
        icon: 'people-team',
        label: 'TEAMS',
        hasSubMenu: false,
        toState: frontendURL(`accounts/${accountId}/settings/teams/list`),
        toStateName: 'settings_teams_list',
      },
      {
        icon: 'mail-inbox-all',
        label: 'INBOXES',
        hasSubMenu: false,
        toState: frontendURL(`accounts/${accountId}/settings/inboxes/list`),
        toStateName: 'settings_inbox_list',
      },
      {
        icon: 'tag',
        label: 'LABELS',
        hasSubMenu: false,
        toState: frontendURL(`accounts/${accountId}/settings/labels/list`),
        toStateName: 'labels_list',
      },
      {
        icon: 'code',
        label: 'CUSTOM_ATTRIBUTES',
        hasSubMenu: false,
        toState: frontendURL(
          `accounts/${accountId}/settings/custom-attributes/list`
        ),
        toStateName: 'attributes_list',
      },
      {
        icon: 'automation',
        label: 'AUTOMATION',
        hasSubMenu: false,
        toState: frontendURL(`accounts/${accountId}/settings/automation/list`),
        toStateName: 'automation_list',
        beta: true,
      },
      {
        icon: 'chat-multiple',
        label: 'CANNED_RESPONSES',
        hasSubMenu: false,
        toState: frontendURL(
          `accounts/${accountId}/settings/canned-response/list`
        ),
        toStateName: 'canned_list',
      },
      {
        icon: 'flash-on',
        label: 'INTEGRATIONS',
        hasSubMenu: false,
        toState: frontendURL(`accounts/${accountId}/settings/integrations`),
        toStateName: 'settings_integrations',
      },
      {
        icon: 'star-emphasis',
        label: 'APPLICATIONS',
        hasSubMenu: false,
        toState: frontendURL(`accounts/${accountId}/settings/applications`),
        toStateName: 'settings_applications',
      },
      {
        icon: 'settings',
        label: 'ACCOUNT_SETTINGS',
        hasSubMenu: false,
        toState: frontendURL(`accounts/${accountId}/settings/general`),
        toStateName: 'general_settings_index',
      },
    ],
  };

  if (isFeatureEnabled(features, 'agent_bots')) {
    const agentBotRouteConfig = {
      icon: 'bot',
      label: 'AGENT_BOTS',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/settings/agent-bots`),
      toStateName: 'agent_bots',
      beta: true,
    };
    const routeIndex = config.menuItems.findIndex(
      route => route.label === 'INTEGRATIONS'
    );
    config.menuItems.splice(routeIndex, 0, agentBotRouteConfig);
  }
  return config;
};

export default settings;
