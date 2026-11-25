import { isValid } from 'date-fns';
import { formatLocalized } from 'shared/helpers/localizedDate';

/**
 * Whether a session inbox should surface the offline banner.
 *
 * `rerouting` is the connector redialling on purpose, which today is a proxy change: it is
 * back within a couple of seconds, and a banner telling the agent to link the device again
 * is the wrong advice for it. It stays on the `connecting` of that redial, which is part
 * of the same reconnect. Read from its own flag rather than from the absence of an
 * error, because an agent never receives the error string, and a real outage would then
 * read as a deliberate reconnect.
 *
 * @param {{connection?: string, rerouting?: boolean}|null|undefined} providerConnection
 * @returns {boolean}
 */
export const isProviderOffline = providerConnection => {
  const connection = providerConnection?.connection;
  if (connection === 'open') return false;
  const redialling = ['reconnecting', 'connecting'].includes(connection);
  return !(redialling && providerConnection?.rerouting);
};

/**
 * Whether a baileys inbox should surface the WhatsApp reach-out restriction banner.
 *
 * The lock is only meaningful while the connection is open (otherwise the offline banner
 * takes precedence). With a deadline, the restriction is shown only until it passes — the
 * provider may lag clearing is_active, so an expired deadline is treated as lifted.
 *
 * @param {{is_active?: boolean, time_enforcement_ends?: string}|null|undefined} lock
 * @param {string|undefined} connection - the provider_connection.connection value
 * @param {number} [now=Date.now()] - epoch millis, injectable for deterministic tests
 * @returns {boolean}
 */
export const isReachoutRestricted = (lock, connection, now = Date.now()) => {
  if (!lock?.is_active) return false;
  if (connection !== 'open') return false;
  if (!lock.time_enforcement_ends) return true;
  // A malformed deadline must not silently hide an active restriction: keep it
  // visible (fail safe) rather than letting NaN > now resolve to false.
  const deadline = new Date(lock.time_enforcement_ends);
  if (!isValid(deadline)) return true;
  return deadline.getTime() > now;
};

/**
 * Whether a session inbox should surface the send-stall banner.
 *
 * Gated on `open` for the opposite reason to the reach-out lock: that pairing IS the
 * fault. The connection receives, answers every health check, and reports 'open' while no
 * outgoing message leaves, so nothing else in the conversation view would warn anyone.
 * Once the connection is down the offline banner is both truer and more urgent, and the
 * stall value lingers by design (it is cleared only by a new socket reaching 'open').
 *
 * @param {{consecutive_timeouts?: number, action?: string, until?: string}|null|undefined} sendStall
 * @param {string|undefined} connection - the provider_connection.connection value
 * @returns {boolean}
 */
export const isSendStalled = (sendStall, connection) =>
  connection === 'open' && Boolean(sendStall);

/**
 * Local-timezone deadline label for the restriction banner, or '' when no deadline is set.
 * `new Date(isoUtc)` parses the UTC instant and `formatLocalized` renders it in the browser's
 * timezone automatically, in the app language.
 *
 * @param {{time_enforcement_ends?: string}|null|undefined} lock
 * @returns {string}
 */
export const reachoutRestrictionDeadline = lock => {
  if (!lock?.time_enforcement_ends) return '';
  // Formatting throws RangeError on an Invalid Date; fall back to '' so the banner
  // renders the generic (deadline-less) copy instead of crashing.
  const deadline = new Date(lock.time_enforcement_ends);
  return isValid(deadline)
    ? formatLocalized(deadline, 'MM/dd/yyyy h:mm a')
    : '';
};

// capping_status values that warrant a banner (NONE / absent => no banner).
const CAP_BANNER_STATUSES = ['FIRST_WARNING', 'SECOND_WARNING', 'CAPPED'];

/**
 * Whether a baileys inbox should surface the new-chat message cap (quota) banner.
 *
 * Only meaningful while the connection is open. `capping_status` is the operant signal: an account
 * that doesn't participate in the cap program reports NONE / NOT_ELIGIBLE, so it never banners.
 *
 * @param {{capping_status?: string}|null|undefined} cap
 * @param {string|undefined} connection - the provider_connection.connection value
 * @returns {boolean}
 */
export const isMessageCapped = (cap, connection) => {
  if (connection !== 'open') return false;
  return CAP_BANNER_STATUSES.includes(cap?.capping_status);
};

/**
 * Whether the cap is fully reached (CAPPED) vs merely a warning — drives the banner severity.
 *
 * @param {{capping_status?: string}|null|undefined} cap
 * @returns {boolean}
 */
export const isMessageCapReached = cap => cap?.capping_status === 'CAPPED';

/**
 * Usable {used, total} quota numbers, or null when they aren't trustworthy. total_quota:0 is a
 * placeholder for accounts not enrolled in the cap program, so we never surface a "0 of 0".
 *
 * @param {{total_quota?: number|string, used_quota?: number|string}|null|undefined} cap
 * @returns {{used: number, total: number}|null}
 */
export const messageCapQuota = cap => {
  const total = Number(cap?.total_quota);
  if (!Number.isFinite(total) || total <= 0) return null;
  const used = Number(cap?.used_quota) || 0;
  return { used, total };
};
