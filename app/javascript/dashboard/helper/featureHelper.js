const FEATURE_HELP_URLS = {
  agent_bots: '/support',
  agents: '/support',
  audit_logs: '/support',
  campaigns: '/support',
  canned_responses: '/support',
  channel_email: '/support',
  channel_facebook: '/support',
  custom_attributes: '/support',
  dashboard_apps: '/support',
  help_center: '/support',
  inboxes: '/support',
  integrations: '/support',
  labels: '/support',
  macros: '/support',
  message_reply_to: '/support',
  reports: '/support',
  sla: '/support',
  team_management: '/support',
  webhook: '/support',
  billing: '/support',
  saml: '/support',
  captain_billing: '/support',
};

export function getHelpUrlForFeature(featureName) {
  return FEATURE_HELP_URLS[featureName];
}
