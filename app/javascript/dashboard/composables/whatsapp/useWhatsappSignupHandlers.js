import { useAlert } from 'dashboard/composables';
import { useWhatsappSuccessHandler } from './useWhatsappSuccessHandler';

export function useWhatsappSignupHandlers({
  currentStep,
  isProcessing,
  isAuthenticating,
  resetState,
  store,
  router,
  t,
}) {
  const { handleValidInboxData, handleInvalidInboxData } =
    useWhatsappSuccessHandler({ store, router, t });

  const getErrorMessage = data => {
    return (
      data.error ||
      data.message ||
      t('INBOX_MGMT.ADD.WHATSAPP.API.ERROR_MESSAGE')
    );
  };

  const getCancellationMessage = data => {
    let message = t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.CANCELLED');
    if (data.data?.current_step) {
      message += ` (Step: ${data.data.current_step})`;
    }
    return message;
  };

  const handleSignupError = data => {
    resetState();
    const errorMessage = getErrorMessage(data);
    useAlert(errorMessage);
  };

  const handleSignupCancellation = data => {
    resetState();
    const message = getCancellationMessage(data);
    useAlert(message);
  };

  const handleSignupSuccess = inboxData => {
    currentStep.value = 'completed';
    isProcessing.value = false;
    isAuthenticating.value = false;

    if (inboxData?.id) {
      handleValidInboxData(inboxData);
    } else {
      handleInvalidInboxData();
    }
  };

  return {
    handleSignupError,
    handleSignupCancellation,
    handleSignupSuccess,
  };
}
