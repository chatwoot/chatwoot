import {
  getAgentsByAvailability,
  getSortedAgentsByAvailability,
  getAgentsByUpdatedPresence,
  generateAgentsList,
} from '../agentHelper';
import {
  allAgentsData,
  onlineAgentsData,
  busyAgentsData,
  offlineAgentsData,
  sortedByAvailability,
  formattedAgentsData,
  formattedAgentsByPresenceOnline,
  formattedAgentsByPresenceOffline,
} from './fixtures/agentFixtures';

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

  describe('generateAgentsList', () => {
    const currentUser = {
      id: 1,
      accounts: [{ id: 1, availability_status: 'online' }],
    };
    const currentAccountId = 1;

    it('generates agents list with "None" when an agent is selected', () => {
      const isAgentSelected = true;
      expect(
        generateAgentsList(
          allAgentsData,
          currentUser,
          currentAccountId,
          isAgentSelected
        )
      ).toEqual(formattedAgentsData);
    });

    it('generates agents list without "None" when no agent is selected', () => {
      const isAgentSelected = false;
      const result = generateAgentsList(
        allAgentsData,
        currentUser,
        currentAccountId,
        isAgentSelected
      );
      expect(result[0].name).not.toBe('None');
      expect(result).toEqual(formattedAgentsData.slice(1));
    });

    it('handles empty assignable agents list', () => {
      const result = generateAgentsList(
        [],
        currentUser,
        currentAccountId,
        true
      );
      expect(result).toEqual([
        {
          confirmed: true,
          name: 'None',
          id: 0,
          role: 'agent',
          account_id: 0,
          email: 'None',
        },
      ]);
    });

    it('handles undefined assignable agents', () => {
      const result = generateAgentsList(
        undefined,
        currentUser,
        currentAccountId,
        false
      );
      expect(result).toEqual([]);
    });

    it('updates current user presence in the generated list', () => {
      const customCurrentUser = {
        id: 1,
        accounts: [{ id: 1, availability_status: 'busy' }],
      };
      const result = generateAgentsList(
        allAgentsData,
        customCurrentUser,
        currentAccountId,
        false
      );
      const updatedAgent = result.find(agent => agent.id === 1);
      expect(updatedAgent.availability_status).toBe('busy');
    });
  });
});
