import { computed } from 'vue';

/**
 * Composable for accessing Chatwoot configuration values.
 * @returns {Object} An object containing computed properties for various Chatwoot configuration values.
 */
export function useChatwootConfig() {
  const hostURL = computed(() => window.chatwootConfig.hostURL);

  const vapidPublicKey = computed(() => window.chatwootConfig.vapidPublicKey);

  const enabledLanguages = computed(
    () => window.chatwootConfig.enabledLanguages
  );

  const isEnterprise = computed(
    () => window.chatwootConfig.isEnterprise === 'true'
  );

  const enterprisePlanName = computed(
    () => window.chatwootConfig?.enterprisePlanName
  );

  return {
    hostURL,
    vapidPublicKey,
    enabledLanguages,
    isEnterprise,
    enterprisePlanName,
  };
}
