export default [
  {
    id: 1,
    name: 'Standard Capacity Policy',
    description: 'Default capacity policy for agents',
    default_capacity: 10,
    enabled: true,
    account_id: 1,
    assigned_agent_count: 3,
    created_at: '2024-01-01T10:00:00.000Z',
    updated_at: '2024-01-01T10:00:00.000Z',
    users: [],
    inbox_capacity_limits: [
      {
        id: 1,
        inbox_id: 1,
        conversation_limit: 15,
        agent_capacity_policy_id: 1,
      },
      {
        id: 2,
        inbox_id: 2,
        conversation_limit: 8,
        agent_capacity_policy_id: 1,
      },
    ],
  },
  {
    id: 2,
    name: 'High Capacity Policy',
    description: 'High capacity policy for senior agents',
    default_capacity: 20,
    enabled: true,
    account_id: 1,
    assigned_agent_count: 5,
    created_at: '2024-01-01T11:00:00.000Z',
    updated_at: '2024-01-01T11:00:00.000Z',
    users: [
      {
        id: 1,
        name: 'Agent Smith',
        email: 'agent.smith@example.com',
        capacity: 25,
      },
      {
        id: 2,
        name: 'Agent Johnson',
        email: 'agent.johnson@example.com',
        capacity: 18,
      },
    ],
    inbox_capacity_limits: [],
  },
  {
    id: 3,
    name: 'Disabled Policy',
    description: 'Disabled capacity policy',
    default_capacity: 5,
    enabled: false,
    account_id: 1,
    assigned_agent_count: 0,
    created_at: '2024-01-01T12:00:00.000Z',
    updated_at: '2024-01-01T12:00:00.000Z',
    users: [],
    inbox_capacity_limits: [],
  },
];

export const camelCaseFixtures = [
  {
    id: 1,
    name: 'Standard Capacity Policy',
    description: 'Default capacity policy for agents',
    defaultCapacity: 10,
    enabled: true,
    accountId: 1,
    assignedAgentCount: 3,
    createdAt: '2024-01-01T10:00:00.000Z',
    updatedAt: '2024-01-01T10:00:00.000Z',
    users: [],
    inboxCapacityLimits: [
      {
        id: 1,
        inboxId: 1,
        conversationLimit: 15,
        agentCapacityPolicyId: 1,
      },
      {
        id: 2,
        inboxId: 2,
        conversationLimit: 8,
        agentCapacityPolicyId: 1,
      },
    ],
  },
  {
    id: 2,
    name: 'High Capacity Policy',
    description: 'High capacity policy for senior agents',
    defaultCapacity: 20,
    enabled: true,
    accountId: 1,
    assignedAgentCount: 5,
    createdAt: '2024-01-01T11:00:00.000Z',
    updatedAt: '2024-01-01T11:00:00.000Z',
    users: [
      {
        id: 1,
        name: 'Agent Smith',
        email: 'agent.smith@example.com',
        capacity: 25,
      },
      {
        id: 2,
        name: 'Agent Johnson',
        email: 'agent.johnson@example.com',
        capacity: 18,
      },
    ],
    inboxCapacityLimits: [],
  },
  {
    id: 3,
    name: 'Disabled Policy',
    description: 'Disabled capacity policy',
    defaultCapacity: 5,
    enabled: false,
    accountId: 1,
    assignedAgentCount: 0,
    createdAt: '2024-01-01T12:00:00.000Z',
    updatedAt: '2024-01-01T12:00:00.000Z',
    users: [],
    inboxCapacityLimits: [],
  },
];

// Additional test data for user and inbox limit operations
export const mockUsers = [
  {
    id: 1,
    name: 'Agent Smith',
    email: 'agent.smith@example.com',
    capacity: 25,
  },
  {
    id: 2,
    name: 'Agent Johnson',
    email: 'agent.johnson@example.com',
    capacity: 18,
  },
  {
    id: 3,
    name: 'Agent Brown',
    email: 'agent.brown@example.com',
    capacity: 12,
  },
];

export const mockInboxLimits = [
  {
    id: 1,
    inbox_id: 1,
    conversation_limit: 15,
    agent_capacity_policy_id: 1,
  },
  {
    id: 2,
    inbox_id: 2,
    conversation_limit: 8,
    agent_capacity_policy_id: 1,
  },
  {
    id: 3,
    inbox_id: 3,
    conversation_limit: 20,
    agent_capacity_policy_id: 2,
  },
];

export const camelCaseMockInboxLimits = [
  {
    id: 1,
    inboxId: 1,
    conversationLimit: 15,
    agentCapacityPolicyId: 1,
  },
  {
    id: 2,
    inboxId: 2,
    conversationLimit: 8,
    agentCapacityPolicyId: 1,
  },
  {
    id: 3,
    inboxId: 3,
    conversationLimit: 20,
    agentCapacityPolicyId: 2,
  },
];
