import { getters } from '../../agentCapacityPolicies';
import agentCapacityPoliciesList from './fixtures';

describe('#getters', () => {
  it('getAgentCapacityPolicies', () => {
    const state = { records: agentCapacityPoliciesList };
    expect(getters.getAgentCapacityPolicies(state)).toEqual(
      agentCapacityPoliciesList
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

  it('getUsersUIFlags', () => {
    const state = {
      usersUiFlags: {
        isFetching: false,
        isDeleting: false,
      },
    };
    expect(getters.getUsersUIFlags(state)).toEqual({
      isFetching: false,
      isDeleting: false,
    });
  });

  it('getAgentCapacityPolicyById', () => {
    const state = { records: agentCapacityPoliciesList };
    expect(getters.getAgentCapacityPolicyById(state)(1)).toEqual(
      agentCapacityPoliciesList[0]
    );
    expect(getters.getAgentCapacityPolicyById(state)(4)).toEqual({});
  });
});
