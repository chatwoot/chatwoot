import {
  getAgentsByAvailability,
  getSortedAgentsByAvailability,
  getAgentsByUpdatedPresence,
  getCombinedAgents,
  createNoneAgent,
} from '../agentHelper';
import {
  allAgentsData,
  onlineAgentsData,
  busyAgentsData,
  offlineAgentsData,
  sortedByAvailability,
  formattedAgentsByPresenceOnline,
  formattedAgentsByPresenceOffline,
} from 'dashboard/helper/specs/fixtures/agentFixtures';

describe('agentHelper', () => {
  describe('getAgentsByAvailability', () => {
    it('returns agents by availability', () => {
      expect(getAgentsByAvailability(allAgentsData, 'online')).toEqual(
        onlineAgentsData
      );
      expect(getAgentsByAvailability(allAgentsData, 'busy')).toEqual(
        busyAgentsData
      );
      expect(getAgentsByAvailability(allAgentsData, 'offline')).toEqual(
        offlineAgentsData
      );
    });
  });

  describe('getSortedAgentsByAvailability', () => {
    it('returns sorted agents by availability', () => {
      expect(getSortedAgentsByAvailability(allAgentsData)).toEqual(
        sortedByAvailability
      );
    });

    it('returns an empty array when given an empty input', () => {
      expect(getSortedAgentsByAvailability([])).toEqual([]);
    });

    it('maintains the order of agents with the same availability status', () => {
      const result = getSortedAgentsByAvailability(allAgentsData);
      expect(result[2].name).toBe('Honey Bee');
      expect(result[3].name).toBe('Samuel Keta');
    });
  });

  describe('getAgentsByUpdatedPresence', () => {
    it('returns agents with updated presence', () => {
      const currentUser = {
        id: 1,
        accounts: [{ id: 1, availability_status: 'offline' }],
      };
      const currentAccountId = 1;

      expect(
        getAgentsByUpdatedPresence(
          formattedAgentsByPresenceOnline,
          currentUser,
          currentAccountId
        )
      ).toEqual(formattedAgentsByPresenceOffline);
    });

    it('does not modify other agents presence', () => {
      const currentUser = {
        id: 2,
        accounts: [{ id: 1, availability_status: 'offline' }],
      };
      const currentAccountId = 1;

      expect(
        getAgentsByUpdatedPresence(
          formattedAgentsByPresenceOnline,
          currentUser,
          currentAccountId
        )
      ).toEqual(formattedAgentsByPresenceOnline);
    });

    it('handles empty agent list', () => {
      const currentUser = {
        id: 1,
        accounts: [{ id: 1, availability_status: 'offline' }],
      };
      const currentAccountId = 1;

      expect(
        getAgentsByUpdatedPresence([], currentUser, currentAccountId)
      ).toEqual([]);
    });
  });

  describe('getCombinedAgents', () => {
    it('includes None agent when includeNoneAgent is true and isAgentSelected is true', () => {
      const result = getCombinedAgents(sortedByAvailability, true, true);
      expect(result).toEqual([createNoneAgent, ...sortedByAvailability]);
      expect(result.length).toBe(sortedByAvailability.length + 1);
      expect(result[0]).toEqual(createNoneAgent);
    });

    it('excludes None agent when includeNoneAgent is false', () => {
      const result = getCombinedAgents(sortedByAvailability, false, true);
      expect(result).toEqual(sortedByAvailability);
      expect(result.length).toBe(sortedByAvailability.length);
      expect(result[0]).not.toEqual(createNoneAgent);
    });

    it('excludes None agent when isAgentSelected is false', () => {
      const result = getCombinedAgents(sortedByAvailability, true, false);
      expect(result).toEqual(sortedByAvailability);
      expect(result.length).toBe(sortedByAvailability.length);
      expect(result[0]).not.toEqual(createNoneAgent);
    });

    it('returns only filtered agents when both includeNoneAgent and isAgentSelected are false', () => {
      const result = getCombinedAgents(sortedByAvailability, false, false);
      expect(result).toEqual(sortedByAvailability);
      expect(result.length).toBe(sortedByAvailability.length);
    });

    it('handles empty filteredAgentsByAvailability array', () => {
      const result = getCombinedAgents([], true, true);
      expect(result).toEqual([createNoneAgent]);
      expect(result.length).toBe(1);
    });
  });
});
