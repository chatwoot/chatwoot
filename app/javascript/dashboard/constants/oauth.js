// The parameters of an OAuth authorization request that the consent API reads
export const OAUTH_AUTHORIZE_PARAMS = [
  'client_id',
  'redirect_uri',
  'response_type',
  'scope',
  'state',
  'code_challenge',
  'code_challenge_method',
];

export const OAUTH_SCOPE_LABELS = {
  'conversations:read': 'OAUTH.SCOPES.CONVERSATIONS_READ',
  'conversations:write': 'OAUTH.SCOPES.CONVERSATIONS_WRITE',
  'messages:write': 'OAUTH.SCOPES.MESSAGES_WRITE',
  'contacts:read': 'OAUTH.SCOPES.CONTACTS_READ',
  'contacts:write': 'OAUTH.SCOPES.CONTACTS_WRITE',
};
