import { computed, ref, unref } from 'vue';
import { useStore } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store.js';
import { useAccount } from 'dashboard/composables/useAccount';

export function useBulkActions() {
  const store = useStore();
  const { t } = useI18n();
  const { currentAccount } = useAccount();

  const selectedConversations = useMapGetter(
    'bulkActions/getSelectedConversationIds'
  );
  const allConversations = useMapGetter('getAllConversations');
  const selectedInboxes = ref([]);

  const requiredAttributeKeys = computed(
    () => currentAccount.value?.settings?.conversation_required_attributes || []
  );

  const conversationsById = computed(() =>
    (allConversations.value || []).reduce((acc, conversation) => {
      acc[conversation.id] = conversation;
      return acc;
    }, {})
  );

  const hasAllRequiredValues = conversation => {
    if (!conversation) return false;
    const attrs = conversation.custom_attributes || {};
    return requiredAttributeKeys.value.every(key => {
      const value = attrs?.[key];
      return (
        value !== undefined && value !== null && String(value).trim() !== ''
      );
    });
  };

  function selectConversation(conversationId, inboxId) {
    store.dispatch('bulkActions/setSelectedConversationIds', conversationId);
    selectedInboxes.value = [...selectedInboxes.value, inboxId];
  }

  function deSelectConversation(conversationId, inboxId) {
    store.dispatch('bulkActions/removeSelectedConversationIds', conversationId);
    selectedInboxes.value = selectedInboxes.value.filter(
      item => item !== inboxId
    );
  }

  function resetBulkActions() {
    store.dispatch('bulkActions/clearSelectedConversationIds');
    selectedInboxes.value = [];
  }

  function selectAllConversations(check, conversationList) {
    const availableConversations = unref(conversationList);
    if (check) {
      store.dispatch(
        'bulkActions/setSelectedConversationIds',
        availableConversations.map(item => item.id)
      );
      selectedInboxes.value = availableConversations.map(item => item.inbox_id);
    } else {
      resetBulkActions();
    }
  }

  function isConversationSelected(id) {
    return selectedConversations.value.includes(id);
  }

  // Same method used in context menu, conversationId being passed from there.
  async function onAssignAgent(agent, conversationId = null) {
    try {
      await store.dispatch('bulkActions/process', {
        type: 'Conversation',
        ids: conversationId || selectedConversations.value,
        fields: {
          assignee_id: agent.id,
        },
      });
      store.dispatch('bulkActions/clearSelectedConversationIds');
      if (conversationId) {
        useAlert(
          t('CONVERSATION.CARD_CONTEXT_MENU.API.AGENT_ASSIGNMENT.SUCCESFUL', {
            agentName: agent.name,
            conversationId,
          })
        );
      } else {
        useAlert(t('BULK_ACTION.ASSIGN_SUCCESFUL'));
      }
    } catch (err) {
      useAlert(t('BULK_ACTION.ASSIGN_FAILED'));
    }
  }

  // Same method used in context menu, conversationId being passed from there.
  async function onAssignLabels(newLabels, conversationId = null) {
    try {
      await store.dispatch('bulkActions/process', {
        type: 'Conversation',
        ids: conversationId || selectedConversations.value,
        labels: {
          add: newLabels,
        },
      });
      store.dispatch('bulkActions/clearSelectedConversationIds');
      if (conversationId) {
        useAlert(
          t('CONVERSATION.CARD_CONTEXT_MENU.API.LABEL_ASSIGNMENT.SUCCESFUL', {
            labelName: newLabels[0],
            conversationId,
          })
        );
      } else {
        useAlert(t('BULK_ACTION.LABELS.ASSIGN_SUCCESFUL'));
      }
    } catch (err) {
      useAlert(t('BULK_ACTION.LABELS.ASSIGN_FAILED'));
    }
  }

  async function onAssignTeamsForBulk(team) {
    try {
      await store.dispatch('bulkActions/process', {
        type: 'Conversation',
        ids: selectedConversations.value,
        fields: {
          team_id: team.id,
        },
      });
      store.dispatch('bulkActions/clearSelectedConversationIds');
      useAlert(t('BULK_ACTION.TEAMS.ASSIGN_SUCCESFUL'));
    } catch (err) {
      useAlert(t('BULK_ACTION.TEAMS.ASSIGN_FAILED'));
    }
  }

  async function onUpdateConversations(status, snoozedUntil) {
    const selectedIds = selectedConversations.value;
    const requiresCheck =
      status === 'resolved' && requiredAttributeKeys.value.length > 0;

    const resolveCandidates = requiresCheck
      ? selectedIds.reduce(
          (result, id) => {
            const conversation = conversationsById.value[id];
            if (hasAllRequiredValues(conversation)) {
              result.resolvable.push(id);
            } else {
              result.blocked.push(id);
            }
            return result;
          },
          { resolvable: [], blocked: [] }
        )
      : { resolvable: selectedIds, blocked: [] };

    if (!resolveCandidates.resolvable.length) {
      if (requiresCheck) {
        useAlert(t('BULK_ACTION.UPDATE.REQUIRED_ATTRIBUTES_MISSING'));
      } else {
        useAlert(t('BULK_ACTION.UPDATE.UPDATE_FAILED'));
      }
      return;
    }

    try {
      await store.dispatch('bulkActions/process', {
        type: 'Conversation',
        ids: resolveCandidates.resolvable,
        fields: {
          status,
        },
        snoozed_until: snoozedUntil,
      });

      // Update selection to keep only blocked conversations, if any.
      store.dispatch('bulkActions/clearSelectedConversationIds');
      selectedInboxes.value = [];
      if (resolveCandidates.blocked.length) {
        store.dispatch('bulkActions/setSelectedConversationIds', [
          ...resolveCandidates.blocked,
        ]);
        selectedInboxes.value = resolveCandidates.blocked
          .map(id => conversationsById.value[id]?.inbox_id)
          .filter(Boolean);
        useAlert(t('BULK_ACTION.UPDATE.REQUIRED_ATTRIBUTES_MISSING'));
      } else {
        useAlert(t('BULK_ACTION.UPDATE.UPDATE_SUCCESFUL'));
      }
    } catch (err) {
      useAlert(t('BULK_ACTION.UPDATE.UPDATE_FAILED'));
    }
  }

  return {
    selectedConversations,
    selectedInboxes,
    selectConversation,
    deSelectConversation,
    selectAllConversations,
    resetBulkActions,
    isConversationSelected,
    onAssignAgent,
    onAssignLabels,
    onAssignTeamsForBulk,
    onUpdateConversations,
  };
}
