import { mutations } from '../../agentCapacityPolicies';
import types from '../../../mutation-types';
import agentCapacityPoliciesList, { mockUsers } from './fixtures';

describe('#mutations', () => {
  describe('#SET_AGENT_CAPACITY_POLICIES_UI_FLAG', () => {
    it('sets single ui flag', () => {
      const state = {
        uiFlags: {
          isFetching: false,
          isCreating: false,
        },
      };

      mutations[types.SET_AGENT_CAPACITY_POLICIES_UI_FLAG](state, {
        isFetching: true,
      });

      expect(state.uiFlags).toEqual({
        isFetching: true,
        isCreating: false,
      });
    });

    it('sets multiple ui flags', () => {
      const state = {
        uiFlags: {
          isFetching: false,
          isCreating: false,
          isUpdating: false,
        },
      };

      mutations[types.SET_AGENT_CAPACITY_POLICIES_UI_FLAG](state, {
        isFetching: true,
        isCreating: true,
      });

      expect(state.uiFlags).toEqual({
        isFetching: true,
        isCreating: true,
        isUpdating: false,
      });
    });
  });

  describe('#SET_AGENT_CAPACITY_POLICIES', () => {
    it('sets agent capacity policies records', () => {
      const state = { records: [] };

      mutations[types.SET_AGENT_CAPACITY_POLICIES](
        state,
        agentCapacityPoliciesList
      );

      expect(state.records).toEqual(agentCapacityPoliciesList);
    });

    it('replaces existing records', () => {
      const state = { records: [{ id: 999, name: 'Old Policy' }] };

      mutations[types.SET_AGENT_CAPACITY_POLICIES](
        state,
        agentCapacityPoliciesList
      );

      expect(state.records).toEqual(agentCapacityPoliciesList);
    });
  });

  describe('#SET_AGENT_CAPACITY_POLICY', () => {
    it('sets single agent capacity policy record', () => {
      const state = { records: [] };

      mutations[types.SET_AGENT_CAPACITY_POLICY](
        state,
        agentCapacityPoliciesList[0]
      );

      expect(state.records).toEqual([agentCapacityPoliciesList[0]]);
    });

    it('replaces existing record', () => {
      const state = { records: [{ id: 1, name: 'Old Policy' }] };

      mutations[types.SET_AGENT_CAPACITY_POLICY](
        state,
        agentCapacityPoliciesList[0]
      );

      expect(state.records).toEqual([agentCapacityPoliciesList[0]]);
    });
  });

  describe('#ADD_AGENT_CAPACITY_POLICY', () => {
    it('adds new policy to empty records', () => {
      const state = { records: [] };

      mutations[types.ADD_AGENT_CAPACITY_POLICY](
        state,
        agentCapacityPoliciesList[0]
      );

      expect(state.records).toEqual([agentCapacityPoliciesList[0]]);
    });

    it('adds new policy to existing records', () => {
      const state = { records: [agentCapacityPoliciesList[0]] };

      mutations[types.ADD_AGENT_CAPACITY_POLICY](
        state,
        agentCapacityPoliciesList[1]
      );

      expect(state.records).toEqual([
        agentCapacityPoliciesList[0],
        agentCapacityPoliciesList[1],
      ]);
    });
  });

  describe('#EDIT_AGENT_CAPACITY_POLICY', () => {
    it('updates existing policy by id', () => {
      const state = {
        records: [
          { ...agentCapacityPoliciesList[0] },
          { ...agentCapacityPoliciesList[1] },
        ],
      };

      const updatedPolicy = {
        ...agentCapacityPoliciesList[0],
        name: 'Updated Policy Name',
        description: 'Updated Description',
      };

      mutations[types.EDIT_AGENT_CAPACITY_POLICY](state, updatedPolicy);

      expect(state.records[0]).toEqual(updatedPolicy);
      expect(state.records[1]).toEqual(agentCapacityPoliciesList[1]);
    });

    it('updates policy with camelCase properties', () => {
      const camelCasePolicy = {
        id: 1,
        name: 'Camel Case Policy',
        defaultCapacity: 15,
        enabled: true,
      };

      const state = {
        records: [camelCasePolicy],
      };

      const updatedPolicy = {
        ...camelCasePolicy,
        name: 'Updated Camel Case',
        defaultCapacity: 25,
      };

      mutations[types.EDIT_AGENT_CAPACITY_POLICY](state, updatedPolicy);

      expect(state.records[0]).toEqual(updatedPolicy);
    });

    it('does nothing if policy id not found', () => {
      const state = {
        records: [agentCapacityPoliciesList[0]],
      };

      const nonExistentPolicy = {
        id: 999,
        name: 'Non-existent',
      };

      const originalRecords = [...state.records];
      mutations[types.EDIT_AGENT_CAPACITY_POLICY](state, nonExistentPolicy);

      expect(state.records).toEqual(originalRecords);
    });
  });

  describe('#DELETE_AGENT_CAPACITY_POLICY', () => {
    it('deletes policy by id', () => {
      const state = {
        records: [agentCapacityPoliciesList[0], agentCapacityPoliciesList[1]],
      };

      mutations[types.DELETE_AGENT_CAPACITY_POLICY](state, 1);

      expect(state.records).toEqual([agentCapacityPoliciesList[1]]);
    });

    it('does nothing if id not found', () => {
      const state = {
        records: [agentCapacityPoliciesList[0]],
      };

      mutations[types.DELETE_AGENT_CAPACITY_POLICY](state, 999);

      expect(state.records).toEqual([agentCapacityPoliciesList[0]]);
    });

    it('handles empty records', () => {
      const state = { records: [] };

      mutations[types.DELETE_AGENT_CAPACITY_POLICY](state, 1);

      expect(state.records).toEqual([]);
    });
  });

  describe('#SET_AGENT_CAPACITY_POLICIES_USERS_UI_FLAG', () => {
    it('sets users ui flags', () => {
      const state = {
        usersUiFlags: {
          isFetching: false,
        },
      };

      mutations[types.SET_AGENT_CAPACITY_POLICIES_USERS_UI_FLAG](state, {
        isFetching: true,
      });

      expect(state.usersUiFlags).toEqual({
        isFetching: true,
      });
    });

    it('merges with existing flags', () => {
      const state = {
        usersUiFlags: {
          isFetching: false,
          isDeleting: true,
        },
      };

      mutations[types.SET_AGENT_CAPACITY_POLICIES_USERS_UI_FLAG](state, {
        isFetching: true,
      });

      expect(state.usersUiFlags).toEqual({
        isFetching: true,
        isDeleting: true,
      });
    });
  });

  describe('#SET_AGENT_CAPACITY_POLICIES_USERS', () => {
    it('sets users for existing policy', () => {
      const testUsers = [
        { id: 1, name: 'Agent 1', email: 'agent1@example.com', capacity: 15 },
        { id: 2, name: 'Agent 2', email: 'agent2@example.com', capacity: 20 },
      ];

      const state = {
        records: [
          { id: 1, name: 'Policy 1', users: [] },
          { id: 2, name: 'Policy 2', users: [] },
        ],
      };

      mutations[types.SET_AGENT_CAPACITY_POLICIES_USERS](state, {
        policyId: 1,
        users: testUsers,
      });

      expect(state.records[0].users).toEqual(testUsers);
      expect(state.records[1].users).toEqual([]);
    });

    it('replaces existing users', () => {
      const oldUsers = [{ id: 99, name: 'Old Agent', capacity: 5 }];
      const newUsers = [{ id: 1, name: 'New Agent', capacity: 15 }];

      const state = {
        records: [{ id: 1, name: 'Policy 1', users: oldUsers }],
      };

      mutations[types.SET_AGENT_CAPACITY_POLICIES_USERS](state, {
        policyId: 1,
        users: newUsers,
      });

      expect(state.records[0].users).toEqual(newUsers);
    });

    it('does nothing if policy not found', () => {
      const state = {
        records: [{ id: 1, name: 'Policy 1', users: [] }],
      };

      const originalState = JSON.parse(JSON.stringify(state));

      mutations[types.SET_AGENT_CAPACITY_POLICIES_USERS](state, {
        policyId: 999,
        users: [{ id: 1, name: 'Test' }],
      });

      expect(state).toEqual(originalState);
    });
  });

  describe('#ADD_AGENT_CAPACITY_POLICIES_USERS', () => {
    it('adds user to existing policy', () => {
      const state = {
        records: [
          { id: 1, name: 'Policy 1', users: [] },
          { id: 2, name: 'Policy 2', users: [] },
        ],
      };

      mutations[types.ADD_AGENT_CAPACITY_POLICIES_USERS](state, {
        policyId: 1,
        user: mockUsers[0],
      });

      expect(state.records[0].users).toEqual([mockUsers[0]]);
      expect(state.records[1].users).toEqual([]);
    });

    it('adds user to policy with existing users', () => {
      const state = {
        records: [{ id: 1, name: 'Policy 1', users: [mockUsers[0]] }],
      };

      mutations[types.ADD_AGENT_CAPACITY_POLICIES_USERS](state, {
        policyId: 1,
        user: mockUsers[1],
      });

      expect(state.records[0].users).toEqual([mockUsers[0], mockUsers[1]]);
    });

    it('initializes users array if undefined', () => {
      const state = {
        records: [{ id: 1, name: 'Policy 1' }],
      };

      mutations[types.ADD_AGENT_CAPACITY_POLICIES_USERS](state, {
        policyId: 1,
        user: mockUsers[0],
      });

      expect(state.records[0].users).toEqual([mockUsers[0]]);
    });

    it('updates assigned agent count', () => {
      const state = {
        records: [{ id: 1, name: 'Policy 1', users: [] }],
      };

      mutations[types.ADD_AGENT_CAPACITY_POLICIES_USERS](state, {
        policyId: 1,
        user: mockUsers[0],
      });

      expect(state.records[0].assignedAgentCount).toEqual(1);
    });
  });

  describe('#DELETE_AGENT_CAPACITY_POLICIES_USERS', () => {
    it('removes user from policy', () => {
      const state = {
        records: [
          {
            id: 1,
            name: 'Policy 1',
            users: [mockUsers[0], mockUsers[1], mockUsers[2]],
          },
        ],
      };

      mutations[types.DELETE_AGENT_CAPACITY_POLICIES_USERS](state, {
        policyId: 1,
        userId: 2,
      });

      expect(state.records[0].users).toEqual([mockUsers[0], mockUsers[2]]);
    });

    it('handles removing non-existent user', () => {
      const state = {
        records: [
          {
            id: 1,
            name: 'Policy 1',
            users: [mockUsers[0]],
          },
        ],
      };

      mutations[types.DELETE_AGENT_CAPACITY_POLICIES_USERS](state, {
        policyId: 1,
        userId: 999,
      });

      expect(state.records[0].users).toEqual([mockUsers[0]]);
    });

    it('updates assigned agent count', () => {
      const state = {
        records: [{ id: 1, name: 'Policy 1', users: [mockUsers[0]] }],
      };

      mutations[types.DELETE_AGENT_CAPACITY_POLICIES_USERS](state, {
        policyId: 1,
        userId: 1,
      });

      expect(state.records[0].assignedAgentCount).toEqual(0);
    });
  });

  describe('#SET_AGENT_CAPACITY_POLICIES_INBOXES', () => {
    it('adds inbox limit to policy', () => {
      const state = {
        records: [
          {
            id: 1,
            name: 'Policy 1',
            inboxCapacityLimits: [],
          },
        ],
      };

      const inboxLimitData = {
        id: 1,
        inboxId: 1,
        conversationLimit: 15,
        agentCapacityPolicyId: 1,
      };

      mutations[types.SET_AGENT_CAPACITY_POLICIES_INBOXES](
        state,
        inboxLimitData
      );

      expect(state.records[0].inboxCapacityLimits).toEqual([
        {
          id: 1,
          inboxId: 1,
          conversationLimit: 15,
        },
      ]);
    });

    it('does nothing if policy not found', () => {
      const state = {
        records: [{ id: 1, name: 'Policy 1', inboxCapacityLimits: [] }],
      };

      const originalState = JSON.parse(JSON.stringify(state));

      mutations[types.SET_AGENT_CAPACITY_POLICIES_INBOXES](state, {
        id: 1,
        inboxId: 1,
        conversationLimit: 15,
        agentCapacityPolicyId: 999,
      });

      expect(state).toEqual(originalState);
    });
  });

  describe('#EDIT_AGENT_CAPACITY_POLICIES_INBOXES', () => {
    it('updates existing inbox limit', () => {
      const state = {
        records: [
          {
            id: 1,
            name: 'Policy 1',
            inboxCapacityLimits: [
              {
                id: 1,
                inboxId: 1,
                conversationLimit: 15,
              },
              {
                id: 2,
                inboxId: 2,
                conversationLimit: 8,
              },
            ],
          },
        ],
      };

      mutations[types.EDIT_AGENT_CAPACITY_POLICIES_INBOXES](state, {
        id: 1,
        inboxId: 1,
        conversationLimit: 25,
        agentCapacityPolicyId: 1,
      });

      expect(state.records[0].inboxCapacityLimits[0]).toEqual({
        id: 1,
        inboxId: 1,
        conversationLimit: 25,
      });
      expect(state.records[0].inboxCapacityLimits[1]).toEqual({
        id: 2,
        inboxId: 2,
        conversationLimit: 8,
      });
    });

    it('does nothing if limit not found', () => {
      const state = {
        records: [
          {
            id: 1,
            name: 'Policy 1',
            inboxCapacityLimits: [
              {
                id: 1,
                inboxId: 1,
                conversationLimit: 15,
              },
            ],
          },
        ],
      };

      const originalLimits = [...state.records[0].inboxCapacityLimits];

      mutations[types.EDIT_AGENT_CAPACITY_POLICIES_INBOXES](state, {
        id: 999,
        inboxId: 1,
        conversationLimit: 25,
        agentCapacityPolicyId: 1,
      });

      expect(state.records[0].inboxCapacityLimits).toEqual(originalLimits);
    });

    it('does nothing if policy not found', () => {
      const state = {
        records: [{ id: 1, name: 'Policy 1', inboxCapacityLimits: [] }],
      };

      const originalState = JSON.parse(JSON.stringify(state));

      mutations[types.EDIT_AGENT_CAPACITY_POLICIES_INBOXES](state, {
        id: 1,
        inboxId: 1,
        conversationLimit: 25,
        agentCapacityPolicyId: 999,
      });

      expect(state).toEqual(originalState);
    });
  });

  describe('#DELETE_AGENT_CAPACITY_POLICIES_INBOXES', () => {
    it('removes inbox limit from policy', () => {
      const state = {
        records: [
          {
            id: 1,
            name: 'Policy 1',
            inboxCapacityLimits: [
              {
                id: 1,
                inboxId: 1,
                conversationLimit: 15,
              },
              {
                id: 2,
                inboxId: 2,
                conversationLimit: 8,
              },
            ],
          },
        ],
      };

      mutations[types.DELETE_AGENT_CAPACITY_POLICIES_INBOXES](state, {
        policyId: 1,
        limitId: 1,
      });

      expect(state.records[0].inboxCapacityLimits).toEqual([
        {
          id: 2,
          inboxId: 2,
          conversationLimit: 8,
        },
      ]);
    });

    it('handles removing non-existent limit', () => {
      const state = {
        records: [
          {
            id: 1,
            name: 'Policy 1',
            inboxCapacityLimits: [
              {
                id: 1,
                inboxId: 1,
                conversationLimit: 15,
              },
            ],
          },
        ],
      };

      const originalLimits = [...state.records[0].inboxCapacityLimits];

      mutations[types.DELETE_AGENT_CAPACITY_POLICIES_INBOXES](state, {
        policyId: 1,
        limitId: 999,
      });

      expect(state.records[0].inboxCapacityLimits).toEqual(originalLimits);
    });
  });
});
