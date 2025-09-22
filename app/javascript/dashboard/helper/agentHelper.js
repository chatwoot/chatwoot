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
