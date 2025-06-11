import { computed } from 'vue';
import Auth from 'dashboard/api/auth';

export function useWhatsappAuth() {
  const authHeaders = computed(() => {
    if (!Auth.hasAuthCookie()) return {};

    const {
      'access-token': accessToken,
      'token-type': tokenType,
      client,
      expiry,
      uid,
    } = Auth.getAuthData();

    return {
      'access-token': accessToken,
      'token-type': tokenType,
      client,
      expiry,
      uid,
    };
  });

  const validateAuthRequirements = (authCodeReceived, authCode) => {
    return authCodeReceived.value && authCode.value;
  };

  return {
    authHeaders,
    validateAuthRequirements,
  };
}
