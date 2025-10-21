import { computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import {
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
  const { t } = useI18n();
  const currentUser = useMapGetter('getCurrentUser');
  const currentChat = useMapGetter('getSelectedChat');
  const currentAccountId = useMapGetter('getCurrentAccountId');
  const assignable = useMapGetter('inboxAssignableAgents/getAssignableAgents');

  const inboxId = computed(() => currentChat.value?.inbox_id);
  const isAgentSelected = computed(() => currentChat.value?.meta?.assignee);

  /**
   * Creates a 'None' agent object
   * @returns {Object} None agent object
   */
  const createNoneAgent = () => ({
    confirmed: true,
    name: t('AGENT_MGMT.MULTI_SELECTOR.LIST.NONE') || 'None',
    id: 0,
    role: 'agent',
    account_id: 0,
    email: 'None',
  });

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

    return [
      ...(includeNoneAgent && isAgentSelected.value ? [createNoneAgent()] : []),
      ...filteredAgentsByAvailability,
    ];
  });

  return {
    agentsList,
    assignableAgents,
  };
}
