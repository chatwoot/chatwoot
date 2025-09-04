import { getters } from '../../assignmentPolicies';
import assignmentPoliciesList from './fixtures';

describe('#getters', () => {
  it('getAssignmentPolicies', () => {
    const state = { records: assignmentPoliciesList };
    expect(getters.getAssignmentPolicies(state)).toEqual(
      assignmentPoliciesList
    );
  });

  it('getUIFlags', () => {
    const state = {
      uiFlags: {
        isFetching: true,
        isFetchingItem: false,
        isCreating: false,
        isUpdating: false,
        isDeleting: false,
      },
    };
    expect(getters.getUIFlags(state)).toEqual({
      isFetching: true,
      isFetchingItem: false,
      isCreating: false,
      isUpdating: false,
      isDeleting: false,
    });
  });

  it('getInboxUiFlags', () => {
    const state = {
      inboxUiFlags: {
        isFetching: false,
      },
    };
    expect(getters.getInboxUiFlags(state)).toEqual({
      isFetching: false,
    });
  });

  it('getAssignmentPolicyById', () => {
    const state = { records: assignmentPoliciesList };
    expect(getters.getAssignmentPolicyById(state)(1)).toEqual(
      assignmentPoliciesList[0]
    );
    expect(getters.getAssignmentPolicyById(state)(3)).toEqual({});
  });

  it('getAssignmentPoliciesByOrder', () => {
    const state = { records: assignmentPoliciesList };
    expect(getters.getAssignmentPoliciesByOrder(state)('round_robin')).toEqual([
      assignmentPoliciesList[0],
    ]);
    expect(getters.getAssignmentPoliciesByOrder(state)('balanced')).toEqual([
      assignmentPoliciesList[1],
    ]);
    expect(getters.getAssignmentPoliciesByOrder(state)('nonexistent')).toEqual(
      []
    );
  });

  it('getAssignmentPoliciesByOrder with camelCase properties', () => {
    const camelCaseRecords = [
      {
        ...assignmentPoliciesList[0],
        assignmentOrder: 'round_robin',
      },
      {
        ...assignmentPoliciesList[1],
        assignmentOrder: 'balanced',
      },
    ];
    const state = { records: camelCaseRecords };
    expect(getters.getAssignmentPoliciesByOrder(state)('round_robin')).toEqual([
      camelCaseRecords[0],
    ]);
  });
});
