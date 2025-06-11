export function useWhatsappSignupFlow({
  currentStep,
  isProcessing,
  processingMessage,
  t,
}) {
  const setProcessingState = () => {
    currentStep.value = 'processing';
    isProcessing.value = true;
    processingMessage.value = t(
      'INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.PROCESSING'
    );
  };

  const handleAuthError = (handleSignupError, translator) => {
    handleSignupError({
      error: translator(
        'INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.AUTH_NOT_COMPLETED'
      ),
    });
  };

  const handleRequestError = (error, handleSignupError) => {
    handleSignupError({ error: error.message });
  };

  return {
    setProcessingState,
    handleAuthError,
    handleRequestError,
  };
}
