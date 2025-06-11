import { computed } from 'vue';
import Auth from 'dashboard/api/auth';

export function useWhatsappSignupApi({
  authCodeReceived,
  authCode,
  currentStep,
  isProcessing,
  processingMessage,
  store,
  t,
  handleSignupError,
  handleSignupSuccess,
}) {
  const authHeaders = computed(() => {
    if (Auth.hasAuthCookie()) {
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
    }
    return {};
  });

  const completeSignupFlow = async businessDataParam => {
    if (!authCodeReceived.value || !authCode.value) {
      handleSignupError({
        error: t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.AUTH_NOT_COMPLETED'),
      });
      return;
    }

    currentStep.value = 'processing';
    isProcessing.value = true;
    processingMessage.value = t(
      'INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.PROCESSING'
    );

    try {
      const accountId = store.getters.getCurrentAccountId;
      const response = await fetch('/whatsapp/embedded_signup', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document
            .querySelector('meta[name="csrf-token"]')
            ?.getAttribute('content'),
          ...authHeaders.value,
        },
        body: JSON.stringify({
          account_id: accountId,
          code: authCode.value,
          business_id: businessDataParam.business_id,
          waba_id: businessDataParam.waba_id,
          phone_number_id: businessDataParam.phone_number_id,
        }),
      });

      const responseData = await response.json();

      if (response.ok) {
        authCode.value = null;
        handleSignupSuccess(responseData);
      } else {
        throw new Error(responseData.message || responseData.error);
      }
    } catch (error) {
      handleSignupError({ error: error.message });
    }
  };

  return {
    completeSignupFlow,
  };
}
