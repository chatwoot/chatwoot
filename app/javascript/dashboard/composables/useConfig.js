import { computed } from 'vue';

/**
 * A composable function that provides access to various configuration values.
 * @returns {Object} An object containing computed properties for configuration values.
 */
export function useConfig() {
  const config = window.chatwootConfig || {};

  /**
   * @type {import('vue').ComputedRef<string|undefined>}
   * The host URL of the Chatwoot instance.
   */
  const hostURL = computed(() => config.hostURL);

  /**
   * @type {import('vue').ComputedRef<string|undefined>}
   * The VAPID public key for web push notifications.
   */
  const vapidPublicKey = computed(() => config.vapidPublicKey);

  /**
   * @type {import('vue').ComputedRef<string[]|undefined>}
   * An array of enabled languages in the Chatwoot instance.
   */
  const enabledLanguages = computed(() => config.enabledLanguages);

  /**
   * @type {import('vue').ComputedRef<boolean>}
   * Indicates whether the current instance is an enterprise version.
   */
  const isEnterprise = computed(() => config.isEnterprise === 'true');

  /**
   * @type {import('vue').ComputedRef<string|undefined>}
   * The name of the enterprise plan, if applicable.
   * returns "community" or "enterprise"
   */
  const enterprisePlanName = computed(() => config.enterprisePlanName);

  return {
    hostURL,
    vapidPublicKey,
    enabledLanguages,
    isEnterprise,
    enterprisePlanName,
  };
}
