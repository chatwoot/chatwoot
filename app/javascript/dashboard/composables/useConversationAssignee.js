import { computed, ref } from 'vue';
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
  const isAssigning = ref(false);

  const currentChat = computed(() => store.getters.getSelectedChat);
  const currentUser = computed(() => store.getters.getCurrentUser);

  const assignedAgent = computed(() => {
    const assignee = currentChat.value?.meta?.assignee;
    if (!assignee?.id) return null;

    const assigneeType = currentChat.value?.meta?.assignee_type;
    return assigneeType
      ? { ...assignee, assignee_type: assigneeType }
      : assignee;
  });

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

  const assignAgent = async agent => {
    const resolved = resolveAssigneeSelection(agent);
    const conversationId = currentChat.value.id;
    const agentId = resolved ? resolved.id : null;
    const assigneeType = resolveAssigneeType(resolved);

    isAssigning.value = true;
    try {
      await store.dispatch('assignAgent', {
        conversationId,
        agentId,
        assigneeType,
      });
      useAlert(t('CONVERSATION.CHANGE_AGENT'));
    } catch {
      useAlert(t('CONVERSATION.CHANGE_AGENT_FAILED'));
    } finally {
      isAssigning.value = false;
    }
  };

  const onClickAssignAgent = selectedItem => {
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
    isAssigning,
    onClickAssignAgent,
    onSelfAssign,
  };
}
