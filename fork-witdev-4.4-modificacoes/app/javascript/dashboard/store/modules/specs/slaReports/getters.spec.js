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

  it('getMeta', () => {
    const state = {
      meta: {
        count: 0,
        currentPage: 1,
      },
    };
    expect(getters.getMeta(state)).toEqual({
      count: 0,
      currentPage: 1,
    });
  });

  it('getMetrics', () => {
    const state = {
      metrics: {
        numberOfConversations: 27,
        numberOfSLAMisses: 25,
        hitRate: '7.41%',
      },
    };

    expect(getters.getMetrics(state)).toEqual({
      numberOfConversations: 27,
      numberOfSLAMisses: 25,
      hitRate: '7.41%',
    });
  });
});
