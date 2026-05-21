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
        isDeleting: false,
      },
    };
    expect(getters.getInboxUiFlags(state)).toEqual({
      isFetching: false,
      isDeleting: false,
    });
  });

  it('getAssignmentPolicyById', () => {
    const state = { records: assignmentPoliciesList };
    expect(getters.getAssignmentPolicyById(state)(1)).toEqual(
      assignmentPoliciesList[0]
    );
    expect(getters.getAssignmentPolicyById(state)(3)).toEqual({});
  });
});
