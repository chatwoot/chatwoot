import { getters } from '../../SLAReports';
import appliedSlas from './fixtures';

describe('#getters', () => {
  it('getAppliedSlas', () => {
    const state = {
      records: [appliedSlas[0]],
    };
    expect(getters.getAll(state)).toEqual([appliedSlas[0]]);
  });

  it('getUIFlags', () => {
    const state = {
      uiFlags: {
        isFetching: false,
        isFetchingMetrics: false,
      },
    };
    expect(getters.getUIFlags(state)).toEqual({
      isFetching: false,
      isFetchingMetrics: false,
    });
  });
});
