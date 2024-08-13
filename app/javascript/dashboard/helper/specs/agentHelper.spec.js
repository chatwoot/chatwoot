import {
  getAgentsByAvailability,
  getSortedAgentsByAvailability,
  getAgentsByUpdatedPresence,
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
});
