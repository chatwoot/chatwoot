const FEATURE_HELP_URLS = {
  agent_bots: '',
  agents: '',
  audit_logs: '',
  campaigns: '',
  canned_responses: '',
  channel_email: '',
  channel_facebook: '',
  custom_attributes: '',
  dashboard_apps: '',
  help_center: '',
  inboxes: '',
  integrations: '',
  labels: '',
  macros: '',
  message_reply_to: '',
  reports: '',
  sla: '',
  team_management: 's',
  webhook: '',
};

export function getHelpUrlForFeature(featureName) {
  return FEATURE_HELP_URLS[featureName];
}
