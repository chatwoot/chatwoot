export function useWhatsappMessageHandler({
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

  const handleEmbeddedSignupData = async data => {
    switch (data.event) {
      case 'FINISH':
        await processFinishEvent(data);
        break;
      case 'CANCEL':
        handleSignupCancellation(data);
        break;
      case 'error':
        processErrorEvent(data);
        break;
      default:
        // Handle unknown events silently
        break;
    }
  };

  const validateMessageOrigin = origin => {
    try {
      const originUrl = new URL(origin);
      const allowedHosts = ['facebook.com', 'www.facebook.com'];
      return allowedHosts.includes(originUrl.hostname);
    } catch (error) {
      return false;
    }
  };

  const parseMessageData = data => {
    try {
      return JSON.parse(data);
    } catch (error) {
      return null;
    }
  };

  const handleSignupMessage = event => {
    if (!validateMessageOrigin(event.origin)) return;

    const data = parseMessageData(event.data);
    if (data?.type === 'WA_EMBEDDED_SIGNUP') {
      handleEmbeddedSignupData(data);
    }
  };

  return {
    handleSignupMessage,
  };
}
