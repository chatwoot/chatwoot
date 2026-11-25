import { computed, ref, unref } from 'vue';
import { useStore } from 'vuex';
import { useAlert, useAssignmentError, useTrack } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store.js';
import { useConversationRequiredAttributes } from 'dashboard/composables/useConversationRequiredAttributes';
import { resolvesConversation } from 'dashboard/composables/useMacroExecution';
import { CONVERSATION_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import wootConstants from 'dashboard/constants/globals';

export function useBulkActions() {
  const store = useStore();
  const { t } = useI18n();
  const { checkMissingAttributes } = useConversationRequiredAttributes();

  const selectedConversations = useMapGetter(
    'bulkActions/getSelectedConversationIds'
  );
  // Keyed by conversation, so deselecting needs nothing but the id. It used to be a parallel array
  // that the caller had to index into by inbox, which meant a conversation already gone from the
  // store (deleted, or its contact removed) could not be deselected fully: the id left the
  // selection and its inbox stayed behind, narrowing the assignable agents of the next selection.
  const selectedInboxById = ref(new Map());
  const selectedInboxes = computed(() => [...selectedInboxById.value.values()]);

  function selectConversation(conversationId, inboxId) {
    store.dispatch('bulkActions/setSelectedConversationIds', conversationId);
    selectedInboxById.value = new Map(selectedInboxById.value).set(
      conversationId,
      inboxId
    );
  }

  function deSelectConversation(conversationId) {
    store.dispatch('bulkActions/removeSelectedConversationIds', conversationId);
    const next = new Map(selectedInboxById.value);
    next.delete(conversationId);
    selectedInboxById.value = next;
  }

  function resetBulkActions() {
    store.dispatch('bulkActions/clearSelectedConversationIds');
    selectedInboxById.value = new Map();
  }

  function selectAllConversations(check, conversationList) {
    const availableConversations = unref(conversationList);
    if (check) {
      store.dispatch(
        'bulkActions/setSelectedConversationIds',
        availableConversations.map(item => item.id)
      );
      selectedInboxById.value = new Map(
        availableConversations.map(item => [item.id, item.inbox_id])
      );
    } else {
      resetBulkActions();
    }
  }

  function isConversationSelected(id) {
    return selectedConversations.value.includes(id);
  }

  // Same method used in context menu, conversationId being passed from there.
  // The context menu always carries a single conversation, so it goes through
  // the synchronous assignment endpoint: bulk_actions answers `head :ok` before
  // the job runs and could never report a rejected assignment back to the agent.
  async function onAssignAgent(agent, conversationId = null) {
    const [singleConversationId] = [conversationId].flat().filter(Boolean);

    try {
      if (singleConversationId) {
        await store.dispatch('assignAgent', {
          conversationId: singleConversationId,
          assignee: agent,
        });
        useAlert(
          t('CONVERSATION.CARD_CONTEXT_MENU.API.AGENT_ASSIGNMENT.SUCCESFUL', {
            agentName: agent.name,
            conversationId: singleConversationId,
          })
        );
        return;
      }

      await store.dispatch('bulkActions/process', {
        type: 'Conversation',
        ids: selectedConversations.value,
        fields: {
          assignee_id: agent.id,
        },
      });
      store.dispatch('bulkActions/clearSelectedConversationIds');
      useAlert(t('BULK_ACTION.ASSIGN_SUCCESFUL'));
    } catch (err) {
      useAssignmentError(err, t('BULK_ACTION.ASSIGN_FAILED'));
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
          const currentCustomAttributes = conversation?.custom_attributes || {};
          const { hasMissing } = checkMissingAttributes(
            currentCustomAttributes
          );

          if (!hasMissing) {
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

  async function onExecuteMacro(macro) {
    const conversationIds = selectedConversations.value;
    const count = conversationIds.length;
    const hasMissingRequiredAttributes =
      resolvesConversation(macro) &&
      conversationIds.some(id => {
        const conversation = store.getters.getConversationById(id);
        return conversation
          ? checkMissingAttributes(conversation.custom_attributes || {})
              .hasMissing
          : false;
      });

    try {
      await store.dispatch('macros/execute', {
        macroId: macro.id,
        conversationIds,
      });
      useTrack(CONVERSATION_EVENTS.EXECUTED_A_MACRO);
      store.dispatch('bulkActions/clearSelectedConversationIds');
      useAlert(
        hasMissingRequiredAttributes
          ? t(
              'BULK_ACTION.MACROS.QUEUED_WITH_MISSING_ATTRIBUTES',
              { count },
              count
            )
          : t('BULK_ACTION.MACROS.QUEUED', { count }, count)
      );
    } catch (err) {
      useAlert(t('MACROS.ERROR'));
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
    onAssignTeamsForBulk,
    onUpdateConversations,
    onExecuteMacro,
  };
}
