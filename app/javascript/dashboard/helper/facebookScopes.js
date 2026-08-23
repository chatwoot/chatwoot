export const FACEBOOK_PAGE_SCOPES = [
  'pages_manage_metadata',
  'business_management',
  'pages_messaging',
  'pages_show_list',
  'pages_read_engagement',
];

export const INSTAGRAM_SCOPES = [
  'instagram_basic',
  'instagram_manage_messages',
];

export const buildFacebookLoginScopes = ({
  includeInstagramScopes = false,
} = {}) => {
  const scopes = [...FACEBOOK_PAGE_SCOPES];
  if (includeInstagramScopes) {
    scopes.push(...INSTAGRAM_SCOPES);
  }
  return scopes.join(',');
};

// Business-type Meta apps use Facebook Login for Business, which rejects
// scope-based FB.login calls ("This option is unavailable right now") and
// requires the config_id of a login configuration created in the app
// dashboard. The configuration defines the permissions, so scope is not sent
// alongside it. Classic apps leave FACEBOOK_LOGIN_CONFIG_ID unset and keep
// the scope-based call.
export const buildFacebookLoginOptions = ({
  includeInstagramScopes = false,
} = {}) => {
  const configId = window.chatwootConfig?.fbLoginConfigId;
  if (configId) {
    return { config_id: configId };
  }
  return { scope: buildFacebookLoginScopes({ includeInstagramScopes }) };
};
