import { useMapGetter } from 'dashboard/composables/store';
import * as agentHelper from 'dashboard/helper/agentHelper';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { ref } from 'vue';
import { useAgentsList } from '../useAgentsList';
import { allAgentsData, formattedAgentsData } from './fixtures/agentFixtures';

// Mock vue-i18n
vi.mock('vue-i18n', () => ({
  useI18n: () => ({
    t: key => (key === 'AGENT_MGMT.MULTI_SELECTOR.LIST.NONE' ? 'None' : key),
  }),
}));

vi.mock('dashboard/composables/store');
vi.mock('dashboard/helper/agentHelper');

// Create a mock None agent
const mockNoneAgent = {
  confirmed: true,
  name: 'None',
  id: 0,
  role: 'agent',
  account_id: 0,
  email: 'None',
};

const mockUseMapGetter = (overrides = {}) => {
  const getAssignableAgents = vi.fn(() => allAgentsData);
  const defaultGetters = {
    getCurrentUser: ref(allAgentsData[0]),
    getSelectedChat: ref({ inbox_id: 1, meta: { assignee: true } }),
    getCurrentAccountId: ref(1),
    'inboxAssignableAgents/getAssignableAgents': ref(getAssignableAgents),
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

    mockUseMapGetter();
  });

  it('returns agentsList and assignableAgents', () => {
    const { agentsList, assignableAgents } = useAgentsList();

    expect(assignableAgents.value).toEqual(allAgentsData);
    expect(
      useMapGetter('inboxAssignableAgents/getAssignableAgents').value
    ).toHaveBeenCalledWith(1, { includeAgentBots: false });
    expect(agentsList.value[0]).toEqual(mockNoneAgent);
    expect(agentsList.value.length).toBe(
      formattedAgentsData.slice(1).length + 1
    );
  });

  it('requests agent bots when explicitly included', () => {
    const { agentsList, assignableAgents } = useAgentsList(true, {
      includeAgentBots: true,
    });

    expect(assignableAgents.value).toEqual(allAgentsData);
    expect(
      useMapGetter('inboxAssignableAgents/getAssignableAgents').value
    ).toHaveBeenCalledWith(1, { includeAgentBots: true });
    expect(agentsList.value[0]).toEqual(mockNoneAgent);
    expect(agentsList.value.length).toBe(
      formattedAgentsData.slice(1).length + 1
    );
  });

  it('includes None agent when includeNoneAgent is true', () => {
    const { agentsList } = useAgentsList(true);

    expect(agentsList.value[0]).toEqual(mockNoneAgent);
    expect(agentsList.value.length).toBe(
      formattedAgentsData.slice(1).length + 1
    );
  });

  it('excludes None agent when includeNoneAgent is false', () => {
    const { agentsList } = useAgentsList(false);

    expect(agentsList.value[0].id).not.toBe(0);
    expect(agentsList.value.length).toBe(formattedAgentsData.slice(1).length);
  });

  it('keeps nameless agent bots and applies a fallback label', () => {
    const namelessBot = {
      id: 91,
      name: null,
      assignee_type: 'AgentBot',
      availability_status: 'offline',
    };
    mockUseMapGetter({
      'inboxAssignableAgents/getAssignableAgents': ref(() => [
        ...allAgentsData,
        namelessBot,
      ]),
    });

    const { agentsList } = useAgentsList();
    // access the computed to trigger evaluation
    expect(agentsList.value).toBeDefined();

    const passedAgents =
      agentHelper.getAgentsByUpdatedPresence.mock.calls[0][0];
    expect(passedAgents).toContainEqual({
      ...namelessBot,
      name: '-',
    });
  });

  it('handles empty assignable agents', () => {
    mockUseMapGetter({
      'inboxAssignableAgents/getAssignableAgents': ref(() => []),
    });
    agentHelper.getSortedAgentsByAvailability.mockReturnValue([]);

    const { agentsList, assignableAgents } = useAgentsList();

    expect(assignableAgents.value).toEqual([]);
    expect(agentsList.value).toEqual([mockNoneAgent]);
  });

  it('handles missing inbox_id', () => {
    mockUseMapGetter({
      getSelectedChat: ref({ meta: { assignee: true } }),
      'inboxAssignableAgents/getAssignableAgents': ref(() => []),
    });
    agentHelper.getSortedAgentsByAvailability.mockReturnValue([]);

    const { agentsList, assignableAgents } = useAgentsList();

    expect(assignableAgents.value).toEqual([]);
    expect(agentsList.value).toEqual([mockNoneAgent]);
  });
});
