import { getters } from '../../assignableAgents';
import agentsData from './fixtures';

describe('#getters', () => {
  it('getAssignableAgents', () => {
    const state = {
      records: [agentsData[0]],
    };
    expect(getters.getAssignableAgents(state)).toEqual([agentsData[0]]);
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
