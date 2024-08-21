import { computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
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
  const currentUser = useMapGetter('getCurrentUser');
  const currentChat = useMapGetter('getSelectedChat');
  const currentAccountId = useMapGetter('getCurrentAccountId');
  const assignable = useMapGetter('inboxAssignableAgents/getAssignableAgents');

  const inboxId = computed(() => currentChat.value?.inbox_id);
  const isAgentSelected = computed(() => currentChat.value?.meta?.assignee);

  /**
   * @type {import('vue').ComputedRef<Array>}
   */
  const assignableAgents = computed(() => {
    return inboxId.value ? assignable.value(inboxId.value) : [];
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
