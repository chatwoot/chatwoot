export const FEATURE_FLAGS = {
  AGENT_BOTS: 'agent_bots',
  AGENT_MANAGEMENT: 'agent_management',
  AUTO_RESOLVE_CONVERSATIONS: 'auto_resolve_conversations',
  AUTOMATIONS: 'automations',
  CAMPAIGNS: 'campaigns',
  CANNED_RESPONSES: 'canned_responses',
  CRM: 'crm',
  CUSTOM_ATTRIBUTES: 'custom_attributes',
  INBOX_MANAGEMENT: 'inbox_management',
  INTEGRATIONS: 'integrations',
  LABELS: 'labels',
  MACROS: 'macros',
  HELP_CENTER: 'help_center',
  PROMPTS: 'prompts',
  REPORTS: 'reports',
  TEAM_MANAGEMENT: 'team_management',
  VOICE_RECORDER: 'voice_recorder',
  AUDIT_LOGS: 'audit_logs',
  INBOX_VIEW: 'inbox_view',
  SLA: 'sla',
  RESPONSE_BOT: 'response_bot',
  CHANNEL_EMAIL: 'channel_email',
  CHANNEL_FACEBOOK: 'channel_facebook',
  CHANNEL_TWITTER: 'channel_twitter',
  CHANNEL_WEBSITE: 'channel_website',
  CUSTOM_REPLY_DOMAIN: 'custom_reply_domain',
  CUSTOM_REPLY_EMAIL: 'custom_reply_email',
  DISABLE_BRANDING: 'disable_branding',
  EMAIL_CONTINUITY_ON_API_CHANNEL: 'email_continuity_on_api_channel',
  INBOUND_EMAILS: 'inbound_emails',
  IP_LOOKUP: 'ip_lookup',
  LINEAR: 'linear_integration',
  CAPTAIN: 'captain_integration',
  CUSTOM_ROLES: 'custom_roles',
  CHATWOOT_V4: 'chatwoot_v4',
  REPORT_V4: 'report_v4',
  CHANNEL_INSTAGRAM: 'channel_instagram',
  CONTACT_CHATWOOT_SUPPORT_TEAM: 'contact_chatwoot_support_team',
  CHANNEL_WHATSAPP_WHAPI_PARTNER: 'channel_whatsapp_whapi_partner',
};

export const PREMIUM_FEATURES = [
  FEATURE_FLAGS.SLA,
  FEATURE_FLAGS.CAPTAIN,
  FEATURE_FLAGS.CUSTOM_ROLES,
  FEATURE_FLAGS.AUDIT_LOGS,
  FEATURE_FLAGS.HELP_CENTER,
];

// Custom feature flags - loaded at runtime from config/custom_features.yml
// These are automatically embedded in the HTML from the YAML configuration
export const CUSTOM_FEATURE_FLAGS = window.CUSTOM_FEATURES_CONFIG?.constants || {};

export const CUSTOM_FEATURES_METADATA = window.CUSTOM_FEATURES_CONFIG?.metadata || [];

// Helper function to check if a custom feature is enabled for current account
export const isCustomFeatureEnabled = (featureName, account) => {
  return account?.custom_features?.includes(featureName) || false;
};

// Helper function to get custom feature metadata
export const getCustomFeatureInfo = (featureName) => {
  return CUSTOM_FEATURES_METADATA.find(f => f.name === featureName) || null;
};

// Helper function to get custom feature display name
export const getCustomFeatureDisplayName = (featureName) => {
  const info = getCustomFeatureInfo(featureName);
  return info?.display_name || featureName;
};
