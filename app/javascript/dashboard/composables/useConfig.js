/**
 * A function that provides access to various configuration values.
 * @returns {Object} An object containing configuration values.
 */
export function useConfig() {
  const config = window.chatwootConfig || {};

  /**
   * The host URL of the Chatwoot instance.
   * @type {string|undefined}
   */
  const hostURL = config.hostURL;

  /**
   * An array of enabled languages in the Chatwoot instance.
   * @type {string[]|undefined}
   */
  const enabledLanguages = config.enabledLanguages;

  /**
   * Indicates whether the current instance is an enterprise version.
   * @type {boolean}
   */
  const isEnterprise = config.isEnterprise === 'true';

  /**
   * The name of the enterprise plan, if applicable.
   * Returns "community" or "enterprise"
   * @type {string|undefined}
   */
  const enterprisePlanName = config.enterprisePlanName;

  /**
   * Indicates whether inbox webhook events (ENABLE_INBOX_EVENTS) are enabled.
   * @type {boolean}
   */
  const inboxEventsEnabled = config.inboxEventsEnabled === 'true';

  return {
    hostURL,
    enabledLanguages,
    isEnterprise,
    enterprisePlanName,
    inboxEventsEnabled,
  };
}
