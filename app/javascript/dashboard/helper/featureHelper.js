const FEATURE_HELP_URLS = {
  agent_bots: 'crafty.app/hc/agent-bots',
  agents: 'crafty.app/hc/agents',
  audit_logs: 'crafty.app/hc/audit-logs',
  campaigns: 'crafty.app/hc/campaigns',
  canned_responses: 'crafty.app/hc/canned',
  channel_email: 'crafty.app/hc/email',
  channel_facebook: 'crafty.app/hc/fb',
  custom_attributes: 'crafty.app/hc/custom-attributes',
  dashboard_apps: 'crafty.app/hc/dashboard-apps',
  help_center: 'crafty.app/hc/help-center',
  inboxes: 'crafty.app/hc/inboxes',
  integrations: 'crafty.app/hc/integrations',
  labels: 'crafty.app/hc/labels',
  macros: 'crafty.app/hc/macros',
  message_reply_to: 'crafty.app/hc/reply-to',
  reports: 'crafty.app/hc/reports',
  sla: 'crafty.app/hc/sla',
  team_management: 'crafty.app/hc/teams',
  webhook: 'crafty.app/hc/webhooks',
  billing: 'crafty.app/pricing',
  saml: 'crafty.app/hc/saml',
  captain_billing: 'crafty.app/hc/captain_billing',
};

export function getHelpUrlForFeature(featureName) {
  return FEATURE_HELP_URLS[featureName];
}
