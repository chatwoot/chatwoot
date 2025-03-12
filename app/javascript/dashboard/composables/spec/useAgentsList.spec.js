import { ref } from 'vue';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { useAgentsList } from '../useAgentsList';
import { useMapGetter } from 'dashboard/composables/store';
import { allAgentsData, formattedAgentsData } from './fixtures/agentFixtures';
import * as agentHelper from 'dashboard/helper/agentHelper';

vi.mock('dashboard/composables/store');
vi.mock('dashboard/helper/agentHelper');

const mockUseMapGetter = (overrides = {}) => {
  const defaultGetters = {
    getCurrentUser: ref(allAgentsData[0]),
    getSelectedChat: ref({ inbox_id: 1, meta: { assignee: true } }),
    getCurrentAccountId: ref(1),
    'inboxAssignableAgents/getAssignableAgents': ref(() => allAgentsData),
  };

  const mergedGetters = { ...defaultGetters, ...overrides };

  useMapGetter.mockImplementation(getter => mergedGetters[getter]);
};

describe('useAgentsList', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    agentHelper.getAgentsByUpdatedPresence.mockImplementation(agents => agents);
    agentHelper.getSortedAgentsByAvailability.mockReturnValue(
      formattedAgentsData.slice(1)
    );
    agentHelper.getCombinedAgents.mockImplementation(
      (agents, includeNone, isAgentSelected) => {
        if (includeNone && isAgentSelected) {
          return [agentHelper.createNoneAgent, ...agents];
        }
        return agents;
      }
    );

    mockUseMapGetter();
  });

  it('returns agentsList and assignableAgents', () => {
    const { agentsList, assignableAgents } = useAgentsList();

    expect(assignableAgents.value).toEqual(allAgentsData);
    expect(agentsList.value).toEqual([
      agentHelper.createNoneAgent,
      ...formattedAgentsData.slice(1),
    ]);
  });

  it('includes None agent when includeNoneAgent is true', () => {
    const { agentsList } = useAgentsList(true);

    expect(agentsList.value[0]).toEqual(agentHelper.createNoneAgent);
    expect(agentsList.value.length).toBe(formattedAgentsData.length);
  });

  it('excludes None agent when includeNoneAgent is false', () => {
    const { agentsList } = useAgentsList(false);

    expect(agentsList.value[0]).not.toEqual(agentHelper.createNoneAgent);
    expect(agentsList.value.length).toBe(formattedAgentsData.length - 1);
  });

  it('handles empty assignable agents', () => {
    mockUseMapGetter({
      'inboxAssignableAgents/getAssignableAgents': ref(() => []),
    });
    agentHelper.getSortedAgentsByAvailability.mockReturnValue([]);

    const { agentsList, assignableAgents } = useAgentsList();

    expect(assignableAgents.value).toEqual([]);
    expect(agentsList.value).toEqual([agentHelper.createNoneAgent]);
  });

  it('handles missing inbox_id', () => {
    mockUseMapGetter({
      getSelectedChat: ref({ meta: { assignee: true } }),
      'inboxAssignableAgents/getAssignableAgents': ref(() => []),
    });
    agentHelper.getSortedAgentsByAvailability.mockReturnValue([]);

    const { agentsList, assignableAgents } = useAgentsList();

    expect(assignableAgents.value).toEqual([]);
    expect(agentsList.value).toEqual([agentHelper.createNoneAgent]);
  });
});
