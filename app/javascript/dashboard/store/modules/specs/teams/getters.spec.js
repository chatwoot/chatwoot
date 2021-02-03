import { getters } from '../../teams/getters';
import teamsList from './fixtures';

describe('#getters', () => {
  it('getTeams', () => {
    const state = {
      records: teamsList,
    };
    expect(getters.getTeams(state)).toEqual([teamsList[1]]);
  });

  it('getTeam', () => {
    const state = {
      records: teamsList,
    };
    expect(getters.getTeam(state)(1)).toEqual({
      id: 1,
      account_id: 1,
      name: 'Test',
      description: 'Some team',
    });
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
