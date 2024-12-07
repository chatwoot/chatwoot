/**
 * Default agent object representing 'None'
 * @type {Object}
 */
export const createNoneAgent = {
  confirmed: true,
  name: 'None',
  id: 0,
  role: 'agent',
  account_id: 0,
  email: 'None',
};

/**
 * Filters and sorts agents by availability status
 * @param {Array} agents - List of agents
 * @param {string} availability - Availability status to filter by
 * @returns {Array} Filtered and sorted list of agents
 */
export const getAgentsByAvailability = (agents, availability) => {
  return agents
    .filter(agent => agent.availability_status === availability)
    .sort((a, b) => a.name.localeCompare(b.name));
};

/**
 * Sorts agents by availability status: online, busy, then offline
 * @param {Array} agents - List of agents
 * @returns {Array} Sorted list of agents
 */
export const getSortedAgentsByAvailability = agents => {
  const onlineAgents = getAgentsByAvailability(agents, 'online');
  const busyAgents = getAgentsByAvailability(agents, 'busy');
  const offlineAgents = getAgentsByAvailability(agents, 'offline');
  const filteredAgents = [...onlineAgents, ...busyAgents, ...offlineAgents];
  return filteredAgents;
};

/**
 * Updates the availability status of the current user based on the current account
 * @param {Array} agents - List of agents
 * @param {Object} currentUser - Current user object
 * @param {number} currentAccountId - ID of the current account
 * @returns {Array} Updated list of agents with dynamic presence
 */
// Here we are updating the availability status of the current user dynamically
// based on the current account availability status
export const getAgentsByUpdatedPresence = (
  agents,
  currentUser,
  currentAccountId
) => {
  const agentsWithDynamicPresenceUpdate = agents.map(item =>
    item.id === currentUser.id
      ? {
          ...item,
          availability_status: currentUser.accounts.find(
            account => account.id === currentAccountId
          ).availability_status,
        }
      : item
  );
  return agentsWithDynamicPresenceUpdate;
};

/**
 * Combines the filtered agents with the 'None' agent option if applicable.
 *
 * @param {Array} filteredAgentsByAvailability - The list of agents sorted by availability.
 * @param {boolean} includeNoneAgent - Whether to include the 'None' agent option.
 * @param {boolean} isAgentSelected - Whether an agent is currently selected.
 * @returns {Array} The combined list of agents, potentially including the 'None' agent.
 */
export const getCombinedAgents = (
  filteredAgentsByAvailability,
  includeNoneAgent,
  isAgentSelected
) => {
  return [
    ...(includeNoneAgent && isAgentSelected ? [createNoneAgent] : []),
    ...filteredAgentsByAvailability,
  ];
};
