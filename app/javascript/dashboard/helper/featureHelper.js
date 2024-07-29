const FEATURE_HELP_URLS = {
  channel_email: 'https://chwt.app/hc/email',
  channel_facebook: 'https://chwt.app/hc/fb',
  help_center: 'https://chwt.app/hc/help-center',
  agent_bots: 'https://chwt.app/hc/agent-bots',
  team_management: 'https://chwt.app/hc/teams',
  labels: 'https://chwt.app/hc/labels',
  custom_attributes: 'https://chwt.app/hc/custom-attributes',
  canned_responses: 'https://chwt.app/hc/canned',
  integrations: 'https://chwt.app/hc/integrations',
  campaigns: 'https://chwt.app/hc/campaigns',
  reports: 'https://chwt.app/hc/reports',
  message_reply_to: 'https://chwt.app/hc/reply-to',
  sla: 'https://chwt.app/hc/sla',
  dashboard_apps: 'https://chwt.app/hc/dashboard-apps',
};

export function getHelpUrlForFeature(featureName) {
  return FEATURE_HELP_URLS[featureName];
}
