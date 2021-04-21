import { getters } from '../../teamMembers';
import agentsData from './fixtures';

describe('#getters', () => {
  it('getAssignableAgents', () => {
    const state = {
      records: {
        1: [agentsData[0]],
      },
    };
    expect(getters.getTeamMembers(state)(1)).toEqual([agentsData[0]]);
  });

  it('getUIFlags', () => {
    const state = {
      uiFlags: {
        isFetching: false,
      },
    };
    expect(getters.getUIFlags(state)).toEqual({
      isFetching: false,
    });
  });
});
