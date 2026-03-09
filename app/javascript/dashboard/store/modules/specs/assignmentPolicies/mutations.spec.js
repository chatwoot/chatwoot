import { mutations } from '../../assignmentPolicies';
import types from '../../../mutation-types';
import assignmentPoliciesList from './fixtures';

describe('#mutations', () => {
  describe('#SET_ASSIGNMENT_POLICIES_UI_FLAG', () => {
    it('sets single ui flag', () => {
      const state = {
        uiFlags: {
          isFetching: false,
          isCreating: false,
        },
      };

      mutations[types.SET_ASSIGNMENT_POLICIES_UI_FLAG](state, {
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

      mutations[types.SET_ASSIGNMENT_POLICIES_UI_FLAG](state, {
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

  describe('#SET_ASSIGNMENT_POLICIES', () => {
    it('sets assignment policies records', () => {
      const state = { records: [] };

      mutations[types.SET_ASSIGNMENT_POLICIES](state, assignmentPoliciesList);

      expect(state.records).toEqual(assignmentPoliciesList);
    });

    it('replaces existing records', () => {
      const state = { records: [{ id: 999, name: 'Old Policy' }] };

      mutations[types.SET_ASSIGNMENT_POLICIES](state, assignmentPoliciesList);

      expect(state.records).toEqual(assignmentPoliciesList);
    });
  });

  describe('#SET_ASSIGNMENT_POLICY', () => {
    it('sets single assignment policy record', () => {
      const state = { records: [] };

      mutations[types.SET_ASSIGNMENT_POLICY](state, assignmentPoliciesList[0]);

      expect(state.records).toEqual([assignmentPoliciesList[0]]);
    });

    it('replaces existing record', () => {
      const state = { records: [{ id: 1, name: 'Old Policy' }] };

      mutations[types.SET_ASSIGNMENT_POLICY](state, assignmentPoliciesList[0]);

      expect(state.records).toEqual([assignmentPoliciesList[0]]);
    });
  });

  describe('#ADD_ASSIGNMENT_POLICY', () => {
    it('adds new policy to empty records', () => {
      const state = { records: [] };

      mutations[types.ADD_ASSIGNMENT_POLICY](state, assignmentPoliciesList[0]);

      expect(state.records).toEqual([assignmentPoliciesList[0]]);
    });

    it('adds new policy to existing records', () => {
      const state = { records: [assignmentPoliciesList[0]] };

      mutations[types.ADD_ASSIGNMENT_POLICY](state, assignmentPoliciesList[1]);

      expect(state.records).toEqual([
        assignmentPoliciesList[0],
        assignmentPoliciesList[1],
      ]);
    });
  });

  describe('#EDIT_ASSIGNMENT_POLICY', () => {
    it('updates existing policy by id', () => {
      const state = {
        records: [
          { ...assignmentPoliciesList[0] },
          { ...assignmentPoliciesList[1] },
        ],
      };

      const updatedPolicy = {
        ...assignmentPoliciesList[0],
        name: 'Updated Policy Name',
        description: 'Updated Description',
      };

      mutations[types.EDIT_ASSIGNMENT_POLICY](state, updatedPolicy);

      expect(state.records[0]).toEqual(updatedPolicy);
      expect(state.records[1]).toEqual(assignmentPoliciesList[1]);
    });

    it('updates policy with camelCase properties', () => {
      const camelCasePolicy = {
        id: 1,
        name: 'Camel Case Policy',
        assignmentOrder: 'round_robin',
        conversationPriority: 'earliest_created',
      };

      const state = {
        records: [camelCasePolicy],
      };

      const updatedPolicy = {
        ...camelCasePolicy,
        name: 'Updated Camel Case',
        assignmentOrder: 'balanced',
      };

      mutations[types.EDIT_ASSIGNMENT_POLICY](state, updatedPolicy);

      expect(state.records[0]).toEqual(updatedPolicy);
    });

    it('does nothing if policy id not found', () => {
      const state = {
        records: [assignmentPoliciesList[0]],
      };

      const nonExistentPolicy = {
        id: 999,
        name: 'Non-existent',
      };

      const originalRecords = [...state.records];
      mutations[types.EDIT_ASSIGNMENT_POLICY](state, nonExistentPolicy);

      expect(state.records).toEqual(originalRecords);
    });
  });

  describe('#DELETE_ASSIGNMENT_POLICY', () => {
    it('deletes policy by id', () => {
      const state = {
        records: [assignmentPoliciesList[0], assignmentPoliciesList[1]],
      };

      mutations[types.DELETE_ASSIGNMENT_POLICY](state, 1);

      expect(state.records).toEqual([assignmentPoliciesList[1]]);
    });

    it('does nothing if id not found', () => {
      const state = {
        records: [assignmentPoliciesList[0]],
      };

      mutations[types.DELETE_ASSIGNMENT_POLICY](state, 999);

      expect(state.records).toEqual([assignmentPoliciesList[0]]);
    });

    it('handles empty records', () => {
      const state = { records: [] };

      mutations[types.DELETE_ASSIGNMENT_POLICY](state, 1);

      expect(state.records).toEqual([]);
    });
  });

  describe('#SET_ASSIGNMENT_POLICIES_INBOXES_UI_FLAG', () => {
    it('sets inbox ui flags', () => {
      const state = {
        inboxUiFlags: {
          isFetching: false,
        },
      };

      mutations[types.SET_ASSIGNMENT_POLICIES_INBOXES_UI_FLAG](state, {
        isFetching: true,
      });

      expect(state.inboxUiFlags).toEqual({
        isFetching: true,
      });
    });

    it('merges with existing flags', () => {
      const state = {
        inboxUiFlags: {
          isFetching: false,
          isLoading: true,
        },
      };

      mutations[types.SET_ASSIGNMENT_POLICIES_INBOXES_UI_FLAG](state, {
        isFetching: true,
      });

      expect(state.inboxUiFlags).toEqual({
        isFetching: true,
        isLoading: true,
      });
    });
  });

  describe('#SET_ASSIGNMENT_POLICIES_INBOXES', () => {
    it('sets inboxes for existing policy', () => {
      const mockInboxes = [
        { id: 1, name: 'Support Inbox' },
        { id: 2, name: 'Sales Inbox' },
      ];

      const state = {
        records: [
          { id: 1, name: 'Policy 1', inboxes: [] },
          { id: 2, name: 'Policy 2', inboxes: [] },
        ],
      };

      mutations[types.SET_ASSIGNMENT_POLICIES_INBOXES](state, {
        policyId: 1,
        inboxes: mockInboxes,
      });

      expect(state.records[0].inboxes).toEqual(mockInboxes);
      expect(state.records[1].inboxes).toEqual([]);
    });

    it('replaces existing inboxes', () => {
      const oldInboxes = [{ id: 99, name: 'Old Inbox' }];
      const newInboxes = [{ id: 1, name: 'New Inbox' }];

      const state = {
        records: [{ id: 1, name: 'Policy 1', inboxes: oldInboxes }],
      };

      mutations[types.SET_ASSIGNMENT_POLICIES_INBOXES](state, {
        policyId: 1,
        inboxes: newInboxes,
      });

      expect(state.records[0].inboxes).toEqual(newInboxes);
    });

    it('does nothing if policy not found', () => {
      const state = {
        records: [{ id: 1, name: 'Policy 1', inboxes: [] }],
      };

      const originalState = JSON.parse(JSON.stringify(state));

      mutations[types.SET_ASSIGNMENT_POLICIES_INBOXES](state, {
        policyId: 999,
        inboxes: [{ id: 1, name: 'Test' }],
      });

      expect(state).toEqual(originalState);
    });
  });

  describe('#DELETE_ASSIGNMENT_POLICIES_INBOXES', () => {
    it('removes inbox from policy', () => {
      const mockInboxes = [
        { id: 1, name: 'Support Inbox' },
        { id: 2, name: 'Sales Inbox' },
        { id: 3, name: 'Marketing Inbox' },
      ];

      const state = {
        records: [
          { id: 1, name: 'Policy 1', inboxes: mockInboxes },
          { id: 2, name: 'Policy 2', inboxes: [] },
        ],
      };

      mutations[types.DELETE_ASSIGNMENT_POLICIES_INBOXES](state, {
        policyId: 1,
        inboxId: 2,
      });

      expect(state.records[0].inboxes).toEqual([
        { id: 1, name: 'Support Inbox' },
        { id: 3, name: 'Marketing Inbox' },
      ]);
      expect(state.records[1].inboxes).toEqual([]);
    });

    it('does nothing if policy not found', () => {
      const state = {
        records: [
          { id: 1, name: 'Policy 1', inboxes: [{ id: 1, name: 'Test' }] },
        ],
      };

      const originalState = JSON.parse(JSON.stringify(state));

      mutations[types.DELETE_ASSIGNMENT_POLICIES_INBOXES](state, {
        policyId: 999,
        inboxId: 1,
      });

      expect(state).toEqual(originalState);
    });

    it('does nothing if inbox not found in policy', () => {
      const mockInboxes = [{ id: 1, name: 'Support Inbox' }];

      const state = {
        records: [{ id: 1, name: 'Policy 1', inboxes: mockInboxes }],
      };

      mutations[types.DELETE_ASSIGNMENT_POLICIES_INBOXES](state, {
        policyId: 1,
        inboxId: 999,
      });

      expect(state.records[0].inboxes).toEqual(mockInboxes);
    });

    it('handles policy with no inboxes', () => {
      const state = {
        records: [{ id: 1, name: 'Policy 1' }],
      };

      mutations[types.DELETE_ASSIGNMENT_POLICIES_INBOXES](state, {
        policyId: 1,
        inboxId: 1,
      });

      expect(state.records[0]).toEqual({ id: 1, name: 'Policy 1' });
    });
  });

  describe('#ADD_ASSIGNMENT_POLICIES_INBOXES', () => {
    it('updates policy attributes using MutationHelpers.updateAttributes', () => {
      const state = {
        records: [
          { id: 1, name: 'Policy 1', assignedInboxCount: 2 },
          { id: 2, name: 'Policy 2', assignedInboxCount: 1 },
        ],
      };

      const updatedPolicy = {
        id: 1,
        name: 'Policy 1',
        assignedInboxCount: 3,
        inboxes: [{ id: 1, name: 'New Inbox' }],
      };

      mutations[types.ADD_ASSIGNMENT_POLICIES_INBOXES](state, updatedPolicy);

      expect(state.records[0]).toEqual(updatedPolicy);
      expect(state.records[1]).toEqual({
        id: 2,
        name: 'Policy 2',
        assignedInboxCount: 1,
      });
    });
  });
});
