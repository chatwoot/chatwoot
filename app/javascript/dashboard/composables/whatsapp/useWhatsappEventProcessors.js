export function useWhatsappEventProcessors({
  isValidBusinessData,
  normalizeBusinessData,
  businessData,
  authCodeReceived,
  authCode,
  completeSignupFlow,
  currentStep,
  processingMessage,
  handleSignupError,
  handleSignupCancellation,
  t,
}) {
  const processFinishEvent = async data => {
    const businessDataLocal =
      data.data || data.business_data || data.details || data;

    if (isValidBusinessData(businessDataLocal)) {
      const normalizedData = normalizeBusinessData(businessDataLocal);
      businessData.value = normalizedData;

      if (authCodeReceived.value && authCode.value) {
        await completeSignupFlow(normalizedData);
      } else {
        currentStep.value = 'waiting_for_auth';
        processingMessage.value = t(
          'INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.WAITING_FOR_AUTH'
        );
      }
    } else {
      handleSignupError({
        error: t(
          'INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.INVALID_BUSINESS_DATA'
        ),
      });
    }
  };

  const processErrorEvent = data => {
    handleSignupError({
      error:
        data.error_message ||
        t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.SIGNUP_ERROR'),
      error_id: data.error_id,
      session_id: data.session_id,
    });
  };

  const processCancelEvent = data => {
    handleSignupCancellation(data);
  };

  return {
    processFinishEvent,
    processErrorEvent,
    processCancelEvent,
  };
}
