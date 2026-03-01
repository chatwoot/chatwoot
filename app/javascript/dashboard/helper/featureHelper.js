const FEATURE_HELP_URLS = {
  agent_bots: 'onelink.app/hc/agent-bots',
  agents: 'onelink.app/hc/agents',
  audit_logs: 'onelink.app/hc/audit-logs',
  campaigns: 'onelink.app/hc/campaigns',
  canned_responses: 'onelink.app/hc/canned',
  channel_email: 'onelink.app/hc/email',
  channel_facebook: 'onelink.app/hc/fb',
  custom_attributes: 'onelink.app/hc/custom-attributes',
  dashboard_apps: 'onelink.app/hc/dashboard-apps',
  help_center: 'onelink.app/hc/help-center',
  inboxes: 'onelink.app/hc/inboxes',
  integrations: 'onelink.app/hc/integrations',
  labels: 'onelink.app/hc/labels',
  macros: 'onelink.app/hc/macros',
  message_reply_to: 'onelink.app/hc/reply-to',
  reports: 'onelink.app/hc/reports',
  sla: 'onelink.app/hc/sla',
  team_management: 'onelink.app/hc/teams',
  webhook: 'onelink.app/hc/webhooks',
  billing: 'onelink.app/pricing',
  saml: 'onelink.app/hc/saml',
  captain_billing: 'onelink.app/hc/captain_billing',
};

export function getHelpUrlForFeature(featureName) {
  return FEATURE_HELP_URLS[featureName];
}
