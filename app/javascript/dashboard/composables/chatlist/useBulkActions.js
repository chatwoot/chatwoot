import { ref, unref } from 'vue';
import { useStore } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store.js';
import { useBusinessRulesStatusGuard } from 'dashboard/composables/useBusinessRulesStatusGuard';
import wootConstants from 'dashboard/constants/globals';

export function useBulkActions() {
  const store = useStore();
  const { t } = useI18n();
  const { checkStatusChange } = useBusinessRulesStatusGuard();

  const selectedConversations = useMapGetter(
    'bulkActions/getSelectedConversationIds'
  );
  const selectedInboxes = ref([]);

  function selectConversation(conversationId, inboxId) {
    store.dispatch('bulkActions/setSelectedConversationIds', conversationId);
    selectedInboxes.value = [...selectedInboxes.value, inboxId];
  }

  function deSelectConversation(conversationId, inboxId) {
    store.dispatch('bulkActions/removeSelectedConversationIds', conversationId);
    // Only remove one instance of the inboxId, not all
    // This handles the case where multiple conversations from the same inbox are selected
    const index = selectedInboxes.value.indexOf(inboxId);
    if (index > -1) {
      selectedInboxes.value = [
        ...selectedInboxes.value.slice(0, index),
        ...selectedInboxes.value.slice(index + 1),
      ];
    }
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
    let conversationIds = selectedConversations.value;
    if (conversationId) {
      conversationIds = Array.isArray(conversationId)
        ? conversationId
        : [conversationId];
    }

    try {
      if (!agent?.id) {
        await Promise.all(
          conversationIds.map(id =>
            store.dispatch('assignAgent', {
              conversationId: id,
              agentId: null,
            })
          )
        );
      } else if (agent.assignee_type === 'AgentBot') {
        await Promise.all(
          conversationIds.map(id =>
            store.dispatch('assignAgent', {
              conversationId: id,
              agentId: agent.id,
              assigneeType: 'AgentBot',
            })
          )
        );
      } else {
        await Promise.all(
          conversationIds.map(id =>
            store.dispatch('assignAgent', {
              conversationId: id,
              agentId: agent.id,
              assigneeType: 'User',
            })
          )
        );
      }
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

  function contactIdsFromSelectedConversations() {
    const ids = new Set();
    selectedConversations.value.forEach(conversationId => {
      const conversation = store.getters.getConversationById(conversationId);
      const contactId =
        conversation?.meta?.sender?.id || conversation?.contact_id;
      if (contactId) ids.add(contactId);
    });
    return [...ids];
  }

  async function onAssignContactLabels(newLabels) {
    const contactIds = contactIdsFromSelectedConversations();
    if (!contactIds.length) {
      useAlert(t('BULK_ACTION.CONTACT_LABELS.NO_CONTACTS'));
      return;
    }
    try {
      await store.dispatch('bulkActions/process', {
        type: 'Contact',
        ids: contactIds,
        labels: {
          add: newLabels,
        },
      });
      store.dispatch('bulkActions/clearSelectedConversationIds');
      useAlert(t('BULK_ACTION.CONTACT_LABELS.ASSIGN_SUCCESFUL'));
    } catch (err) {
      useAlert(t('BULK_ACTION.CONTACT_LABELS.ASSIGN_FAILED'));
    }
  }

  async function onRemoveContactLabels(labelsToRemove) {
    const contactIds = contactIdsFromSelectedConversations();
    if (!contactIds.length) {
      useAlert(t('BULK_ACTION.CONTACT_LABELS.NO_CONTACTS'));
      return;
    }
    try {
      await store.dispatch('bulkActions/process', {
        type: 'Contact',
        ids: contactIds,
        labels: {
          remove: labelsToRemove,
        },
      });
      store.dispatch('bulkActions/clearSelectedConversationIds');
      useAlert(t('BULK_ACTION.CONTACT_LABELS.REMOVE_SUCCESFUL'));
    } catch (err) {
      useAlert(t('BULK_ACTION.CONTACT_LABELS.REMOVE_FAILED'));
    }
  }

  // Used by both context menu and bulk action bar.
  async function onRemoveLabels(labelsToRemove, conversationId = null) {
    try {
      await store.dispatch('bulkActions/process', {
        type: 'Conversation',
        ids: conversationId || selectedConversations.value,
        labels: {
          remove: labelsToRemove,
        },
      });

      // Context-menu remove should not disturb an existing bulk selection.
      if (conversationId) {
        useAlert(
          t('CONVERSATION.CARD_CONTEXT_MENU.API.LABEL_REMOVAL.SUCCESFUL', {
            labelName: labelsToRemove[0],
            conversationId,
          })
        );
      } else {
        store.dispatch('bulkActions/clearSelectedConversationIds');
        useAlert(t('BULK_ACTION.LABELS.REMOVE_SUCCESFUL'));
      }
    } catch (err) {
      useAlert(
        conversationId
          ? t('CONVERSATION.CARD_CONTEXT_MENU.API.LABEL_REMOVAL.FAILED')
          : t('BULK_ACTION.LABELS.REMOVE_FAILED')
      );
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
    if (selectedConversations.value.length === 0) return;

    let conversationIds = selectedConversations.value;
    let skippedCount = 0;

    // If resolving, check for required attributes
    if (status === wootConstants.STATUS_TYPE.RESOLVED) {
      const { validIds, skippedIds } = selectedConversations.value.reduce(
        (acc, id) => {
          const conversation = store.getters.getConversationById(id);
          const guard = checkStatusChange(conversation, status);

          if (!guard.blocked) {
            acc.validIds.push(id);
          } else {
            acc.skippedIds.push(id);
          }
          return acc;
        },
        { validIds: [], skippedIds: [] }
      );

      conversationIds = validIds;
      skippedCount = skippedIds.length;

      if (skippedCount > 0 && validIds.length === 0) {
        // All conversations have missing attributes
        useAlert(
          t('BULK_ACTION.RESOLVE.ALL_MISSING_ATTRIBUTES') ||
            'Cannot resolve conversations due to missing required attributes'
        );
        return;
      }
    }

    try {
      if (conversationIds.length > 0) {
        await store.dispatch('bulkActions/process', {
          type: 'Conversation',
          ids: conversationIds,
          fields: {
            status,
          },
          snoozed_until: snoozedUntil,
        });
      }

      store.dispatch('bulkActions/clearSelectedConversationIds');

      if (skippedCount > 0) {
        useAlert(t('BULK_ACTION.RESOLVE.PARTIAL_SUCCESS'));
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
    onRemoveLabels,
    onAssignContactLabels,
    onRemoveContactLabels,
    onAssignTeamsForBulk,
    onUpdateConversations,
  };
}
