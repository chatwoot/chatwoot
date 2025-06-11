import { useAlert } from 'dashboard/composables';

export function useWhatsappAuthCallbacks({
  authCode,
  authCodeReceived,
  currentStep,
  processingMessage,
  isProcessing,
  isAuthenticating,
  hasSignupStarted,
  businessData,
  completeSignupFlow,
  handleSignupError,
  t,
}) {
  const handleSuccessfulAuth = authResponse => {
    authCode.value = authResponse.code;
    authCodeReceived.value = true;
    currentStep.value = 'auth_received';
    processingMessage.value = t(
      'INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.WAITING_FOR_BUSINESS_INFO'
    );

    if (businessData.value) {
      completeSignupFlow(businessData.value);
    }
  };

  const handleAuthError = error => {
    handleSignupError({ error });
  };

  const handleAuthCancellation = () => {
    currentStep.value = 'initial';
    isProcessing.value = false;
    isAuthenticating.value = false;
    hasSignupStarted.value = false;
    useAlert(t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.CANCELLED'));
  };

  const fbLoginCallback = response => {
    if (response.authResponse?.code) {
      handleSuccessfulAuth(response.authResponse);
    } else if (response.error) {
      handleAuthError(response.error);
    } else {
      handleAuthCancellation();
    }
  };

  return {
    fbLoginCallback,
  };
}
