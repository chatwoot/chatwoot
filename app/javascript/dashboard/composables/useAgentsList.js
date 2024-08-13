import { computed } from 'vue';
import { useStoreGetters } from 'dashboard/composables/store';
import {
  createNoneAgent,
  getAgentsByUpdatedPresence,
  getSortedAgentsByAvailability,
} from 'dashboard/helper/agentHelper';

/**
 * A composable function that provides a list of agents for assignment.
 *
 * @param {boolean} [includeNoneAgent=true] - Whether to include a 'None' agent option.
 * @returns {Object} An object containing the agents list and assignable agents.
 */
export function useAgentsList(includeNoneAgent = true) {
  const getters = useStoreGetters();

  const currentUser = computed(() => getters.getCurrentUser.value);

  const currentChat = computed(() => getters.getSelectedChat.value);

  const currentAccountId = computed(() => getters.getCurrentAccountId.value);

  const inboxId = computed(() => currentChat.value?.inbox_id);

  const isAgentSelected = computed(() => currentChat.value?.meta?.assignee);

  /**
   * @type {import('vue').ComputedRef<Array>}
   */
  const assignableAgents = computed(() => {
    return inboxId.value
      ? getters['inboxAssignableAgents/getAssignableAgents'].value(
          inboxId.value
        )
      : [];
  });

  /**
   * @type {import('vue').ComputedRef<Array>}
   */
  const agentsList = computed(() => {
    const agents = assignableAgents.value || [];
    const agentsByUpdatedPresence = getAgentsByUpdatedPresence(
      agents,
      currentUser.value,
      currentAccountId.value
    );
    const filteredAgentsByAvailability = getSortedAgentsByAvailability(
      agentsByUpdatedPresence
    );
    const filteredAgents = [
      ...(includeNoneAgent && isAgentSelected.value ? [createNoneAgent] : []),
      ...filteredAgentsByAvailability,
    ];
    return filteredAgents;
  });

  return {
    agentsList,
    assignableAgents,
  };
}
