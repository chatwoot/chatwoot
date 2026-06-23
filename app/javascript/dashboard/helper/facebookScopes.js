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
