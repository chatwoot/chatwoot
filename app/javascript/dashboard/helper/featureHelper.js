const FEATURE_HELP_URLS = {
  agent_bots: 'https://buzzcrm.ai',
  agents: 'https://buzzcrm.ai',
  audit_logs: 'https://buzzcrm.ai',
  campaigns: 'https://buzzcrm.ai',
  canned_responses: 'https://buzzcrm.ai',
  channel_email: 'https://buzzcrm.ai',
  channel_facebook: 'https://buzzcrm.ai',
  custom_attributes: 'https://buzzcrm.ai',
  dashboard_apps: 'https://buzzcrm.ai',
  help_center: 'https://buzzcrm.ai',
  inboxes: 'https://buzzcrm.ai',
  integrations: 'https://buzzcrm.ai',
  labels: 'https://buzzcrm.ai',
  macros: 'https://buzzcrm.ai',
  message_reply_to: 'https://buzzcrm.ai',
  reports: 'https://buzzcrm.ai',
  sla: 'https://buzzcrm.ai',
  team_management: 'https://buzzcrm.ai',
  webhook: 'https://buzzcrm.ai',
  billing: 'https://buzzcrm.ai',
};

export function getHelpUrlForFeature(featureName) {
  return FEATURE_HELP_URLS[featureName];
}
