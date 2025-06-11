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
  const handleSignupError = data => {
    resetState();
    const errorMessage =
      data.error ||
      data.message ||
      t('INBOX_MGMT.ADD.WHATSAPP.API.ERROR_MESSAGE');
    useAlert(errorMessage);
  };

  const handleSignupCancellation = data => {
    resetState();
    let message = t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.CANCELLED');
    if (data.data?.current_step) {
      message += ` (Step: ${data.data.current_step})`;
    }
    useAlert(message);
  };

  const handleSignupSuccess = inboxData => {
    currentStep.value = 'completed';
    isProcessing.value = false;
    isAuthenticating.value = false;

    if (inboxData && inboxData.id) {
      store.commit('inboxes/ADD_INBOXES', inboxData);
      useAlert(t('INBOX_MGMT.FINISH.MESSAGE'));
      router.replace({
        name: 'settings_inboxes_add_agents',
        params: {
          page: 'new',
          inbox_id: inboxData.id,
        },
      });
    } else {
      useAlert(t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.SUCCESS_FALLBACK'));
      router.replace({
        name: 'settings_inbox_list',
      });
    }
  };

  return {
    handleSignupError,
    handleSignupCancellation,
    handleSignupSuccess,
  };
}
