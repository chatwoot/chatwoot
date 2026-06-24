import { computed, watch } from 'vue';
import { useStore } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { useAgentsList } from 'dashboard/composables/useAgentsList';
import {
  isClearAssigneeSelection,
  isCurrentUserAssigneeMeta,
  resolveAssigneeType,
} from 'dashboard/helper/assigneeHelper';

export function useConversationAssignee() {
  const store = useStore();
  const { t } = useI18n();
  const { agentsList, inboxBotAgent } = useAgentsList();

  const currentChat = computed(() => store.getters.getSelectedChat);
  const currentUser = computed(() => store.getters.getCurrentUser);

  const assignedAgent = computed(() => {
    const assignee = currentChat.value?.meta?.assignee;
    if (!assignee?.id) return null;

    const assigneeType = currentChat.value?.meta?.assignee_type;
    return assigneeType ? { ...assignee, assignee_type: assigneeType } : assignee;
  });

  // #region agent log
  watch(
    () => currentChat.value?.id,
    () => {
      const chat = currentChat.value;
      if (!chat?.id) return;
      fetch('http://127.0.0.1:7681/ingest/5a14c770-9960-4aff-80cb-467e93b61e93', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Debug-Session-Id': 'b893f4',
        },
        body: JSON.stringify({
          sessionId: 'b893f4',
          hypothesisId: 'B',
          location: 'useConversationAssignee.js:watch',
          message: 'selected chat assignee meta',
          data: {
            conversationId: chat.id,
            assigneeId: chat.meta?.assignee?.id ?? null,
            assigneeName: chat.meta?.assignee?.name ?? null,
            assigneeType: chat.meta?.assignee_type ?? null,
            assigneeEmail: chat.meta?.assignee?.email ?? null,
            botType: chat.meta?.assignee?.bot_type ?? null,
          },
          timestamp: Date.now(),
        }),
      }).catch(() => {});
    },
    { immediate: true }
  );
  // #endregion

  const showSelfAssign = computed(() => {
    if (!assignedAgent.value) return true;
    return !isCurrentUserAssigneeMeta(
      currentChat.value?.meta,
      currentUser.value
    );
  });

  const resolveAssigneeSelection = agent => {
    if (isClearAssigneeSelection(agent)) {
      return inboxBotAgent.value || null;
    }
    return agent;
  };

  const assignAgent = agent => {
    const resolved = resolveAssigneeSelection(agent);
    const conversationId = currentChat.value.id;
    const agentId = resolved ? resolved.id : null;
    const assigneeType = resolveAssigneeType(resolved);

    // #region agent log
    fetch('http://127.0.0.1:7681/ingest/5a14c770-9960-4aff-80cb-467e93b61e93', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Debug-Session-Id': 'b893f4',
      },
      body: JSON.stringify({
        sessionId: 'b893f4',
        runId: 'post-fix-4',
        hypothesisId: 'G',
        location: 'useConversationAssignee.js:assignAgent',
        message: 'dispatch assignAgent',
        data: {
          conversationId,
          agentId,
          assigneeType,
          agentName: resolved?.name ?? null,
        },
        timestamp: Date.now(),
      }),
    }).catch(() => {});
    // #endregion

    return store
      .dispatch('assignAgent', {
        conversationId,
        agentId,
        assigneeType,
      })
      .then(() => {
        useAlert(t('CONVERSATION.CHANGE_AGENT'));
      });
  };

  const onClickAssignAgent = selectedItem => {
    // #region agent log
    fetch('http://127.0.0.1:7681/ingest/5a14c770-9960-4aff-80cb-467e93b61e93', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Debug-Session-Id': 'b893f4',
      },
      body: JSON.stringify({
        sessionId: 'b893f4',
        runId: 'post-fix-4',
        hypothesisId: 'H',
        location: 'useConversationAssignee.js:onClickAssignAgent',
        message: 'assign selected item directly',
        data: {
          selectedId: selectedItem?.id ?? null,
          selectedType: resolveAssigneeType(selectedItem),
          selectedName: selectedItem?.name ?? null,
        },
        timestamp: Date.now(),
      }),
    }).catch(() => {});
    // #endregion

    assignAgent(selectedItem);
  };

  const onSelfAssign = () => {
    const {
      account_id,
      availability_status,
      available_name,
      email,
      id,
      name,
      role,
      avatar_url,
    } = currentUser.value;

    assignAgent({
      account_id,
      availability_status,
      available_name,
      email,
      id,
      name,
      role,
      thumbnail: avatar_url,
      assignee_type: 'User',
    });
  };

  return {
    agentsList,
    inboxBotAgent,
    assignedAgent,
    showSelfAssign,
    onClickAssignAgent,
    onSelfAssign,
  };
}
