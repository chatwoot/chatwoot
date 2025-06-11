import { useAlert } from 'dashboard/composables';

export function useWhatsappSuccessHandler({ store, router, t }) {
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

  return {
    handleValidInboxData,
    handleInvalidInboxData,
  };
}
