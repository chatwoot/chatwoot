// export default {
//     computed: {
//       hostURL() {
//         return window.chatwootConfig.hostURL;
//       },
//       vapidPublicKey() {
//         return window.chatwootConfig.vapidPublicKey;
//       },
//       enabledLanguages() {
//         return window.chatwootConfig.enabledLanguages;
//       },
//       isEnterprise() {
//         return window.chatwootConfig.isEnterprise === 'true';
//       },
//       enterprisePlanName() {
//         // returns "community" or "enterprise"
//         return window.chatwootConfig?.enterprisePlanName;
//       },
//     },
//   };

import { computed } from 'vue';

/**
 * Composable for accessing Chatwoot configuration values.
 * @returns {Object} An object containing computed properties for various Chatwoot configuration values.
 */
export function useConfig() {
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
