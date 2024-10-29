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
   * The VAPID public key for web push notifications.
   * @type {string|undefined}
   */
  const vapidPublicKey = config.vapidPublicKey;

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

  return {
    hostURL,
    vapidPublicKey,
    enabledLanguages,
    isEnterprise,
    enterprisePlanName,
  };
}
