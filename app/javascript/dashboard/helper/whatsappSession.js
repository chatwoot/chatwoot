/**
 * The QR/pairing family of WhatsApp providers, legacy ones included.
 *
 * What sets these apart from the cloud family (`whatsapp_cloud`, `default`) is
 * behavioral, not who serves them: a paired session is a real WhatsApp client, so there
 * is no 24-hour messaging window and no template requirement. Mirrors
 * `Whatsapp::Session::Registry.session_family?`.
 */
export const SESSION_PROVIDERS = ['baileys', 'zapi', 'native', 'uazapi'];

/**
 * The providers this app serves through its own session layer, as opposed to the legacy
 * ones it only labels. Mirrors `Whatsapp::Session::Registry.session_provider?`, which is
 * what the history-file endpoints check: only this layer files a history message whose
 * file is still to be fetched.
 */
export const SESSION_LAYER_PROVIDERS = ['native', 'uazapi'];

export const isSessionLayerProvider = provider =>
  SESSION_LAYER_PROVIDERS.includes(provider);

/**
 * What a provider can actually do. Mirrors `Whatsapp::Session::Capabilities::ALL`, which
 * is what the server declares per provider and serves on the inbox payload.
 *
 * Gate features on these instead of on a provider name: a name says who is answering, a
 * capability says whether the call will work, and the two stop agreeing the moment a
 * provider is added or a kill switch is thrown.
 */
export const CAPABILITIES = {
  QR_PAIRING: 'qr_pairing',
  CODE_PAIRING: 'code_pairing',
  SESSION_IMPORT: 'session_import',
  ECHO_BY_RESERVED_ID: 'echo_by_reserved_id',
  EDIT: 'edit',
  REVOKE: 'revoke',
  REACTIONS: 'reactions',
  TYPING: 'typing',
  PRESENCE: 'presence',
  PRESENCE_SUBSCRIBE: 'presence_subscribe',
  READ_RECEIPTS: 'read_receipts',
  MARK_UNREAD: 'mark_unread',
  CHECK_NUMBER: 'check_number',
  PROFILE_PICTURE: 'profile_picture',
  GROUPS: 'groups',
  GROUP_MANAGEMENT: 'group_management',
  GROUP_ADMIN: 'group_admin',
  GROUP_INVITES: 'group_invites',
  GROUP_JOIN_REQUESTS: 'group_join_requests',
  ACCOUNT_LIMITS: 'account_limits',
  HISTORY_SYNC: 'history_sync',
  CALLS: 'calls',
  MEDIA_DOWNLOAD: 'media_download',
};

/**
 * Takes the provider rather than the whole inbox on purpose: an inbox reaches the
 * dashboard in two shapes (snake_case straight from the store, camelCase through
 * `useCamelCase`), so a helper reading `channel_type` off it would silently answer false
 * on half the call sites. Each caller pairs this with the channel-type check it already
 * has in its own shape.
 *
 * @param {string|undefined} provider
 * @returns {boolean}
 */
export const isSessionProvider = provider =>
  SESSION_PROVIDERS.includes(provider);

/**
 * The capability list the server put on this inbox. Absent for every non-WhatsApp
 * channel, so a gate on an unrelated inbox reads false instead of throwing.
 *
 * @param {{capabilities?: string[]}|null|undefined} inbox
 * @returns {string[]}
 */
export const inboxCapabilities = inbox => inbox?.capabilities ?? [];

/**
 * @param {{capabilities?: string[]}|null|undefined} inbox
 * @param {string} capability - one of CAPABILITIES
 * @returns {boolean}
 */
export const hasCapability = (inbox, capability) =>
  inboxCapabilities(inbox).includes(capability);

/**
 * Whether a provider address has a shape the server would accept.
 *
 * It lives here rather than in `helper/URLHelper` because it exists to mirror one
 * server-side rule: `Backend.validate_config` takes any http(s) URI that has a host, and
 * decides separately whether one inside the deployment's own network is permitted
 * (`Whatsapp::Session::PrivateAddress` plus `SafeFetch.allow_private_network?`). The
 * dashboard cannot know that policy, so it checks shape only.
 *
 * `isValidURL` is stricter than that: its regex needs a dot in the host, which refuses
 * `http://uazapi:3000` and `http://localhost:3000` (the addresses an operator who has set
 * `SAFE_FETCH_ALLOW_PRIVATE_NETWORK` is entitled to enter) and every IPv6 literal. A form
 * that refuses more than the server does is a provider the operator cannot enter at all.
 *
 * @param {string} value
 * @returns {boolean}
 */
export const isHttpUrl = value => {
  try {
    const { protocol, hostname } = new URL(value);
    return (protocol === 'http:' || protocol === 'https:') && hostname !== '';
  } catch {
    return false;
  }
};
