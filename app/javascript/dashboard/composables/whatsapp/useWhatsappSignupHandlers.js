import { useAlert } from 'dashboard/composables';

export function useWhatsappSignupHandlers({
  currentStep,
  isProcessing,
  isAuthenticating,
  resetState,
  store,
  router,
  t,
}) {
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

  const navigateToAgentSelection = inboxId => {
    router.replace({
      name: 'settings_inboxes_add_agents',
      params: {
        page: 'new',
        inbox_id: inboxId,
      },
    });
  };

  const navigateToInboxList = () => {
    router.replace({
      name: 'settings_inbox_list',
    });
  };

  const updateStoreWithInbox = inboxData => {
    store.commit('inboxes/ADD_INBOXES', inboxData);
    useAlert(t('INBOX_MGMT.FINISH.MESSAGE'));
  };

  const handleValidInboxData = inboxData => {
    updateStoreWithInbox(inboxData);
    navigateToAgentSelection(inboxData.id);
  };

  const handleInvalidInboxData = () => {
    useAlert(t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.SUCCESS_FALLBACK'));
    navigateToInboxList();
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
