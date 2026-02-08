import { getters } from '../../teamMembers';
import teamMembers from './fixtures';

describe('#getters', () => {
  it('getTeamMembers', () => {
    const state = {
      records: {
        1: [teamMembers[0]],
      },
    };
    expect(getters.getTeamMembers(state)(1)).toEqual([teamMembers[0]]);
  });

  it('getUIFlags', () => {
    const state = {
      uiFlags: {
        isFetching: false,
        isCreating: false,
        isUpdating: false,
        isDeleting: false,
      },
    };
    expect(getters.getUIFlags(state)).toEqual({
      isFetching: false,
      isCreating: false,
      isUpdating: false,
      isDeleting: false,
    });
  });
});
