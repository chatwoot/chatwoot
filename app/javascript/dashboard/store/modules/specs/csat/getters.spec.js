import { getters } from '../../csat';

describe('#getters', () => {
  it('getUIFlags', () => {
    const state = { uiFlags: { isFetching: false } };
    expect(getters.getUIFlags(state)).toEqual({ isFetching: false });
  });

  it('getCSATResponses', () => {
    const state = { records: [{ id: 1, raring: 1, feedback_text: 'Bad' }] };
    expect(getters.getCSATResponses(state)).toEqual([
      { id: 1, raring: 1, feedback_text: 'Bad' },
    ]);
  });

  it('getMetrics', () => {
    const state = {
      metrics: {
        totalResponseCount: 0,
        ratingsCount: { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 },
      },
    };
    expect(getters.getMetrics(state)).toEqual(state.metrics);
  });

  it('getRatingPercentage', () => {
    let state = {
      metrics: {
        totalResponseCount: 0,
        ratingsCount: { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 },
      },
    };
    expect(getters.getRatingPercentage(state)).toEqual({
      1: 0,
      2: 0,
      3: 0,
      4: 0,
      5: 0,
    });

    state = {
      metrics: {
        totalResponseCount: 50,
        ratingsCount: { 1: 10, 2: 20, 3: 15, 4: 3, 5: 2 },
      },
    };
    expect(getters.getRatingPercentage(state)).toEqual({
      1: '20.00',
      2: '40.00',
      3: '30.00',
      4: '6.00',
      5: '4.00',
    });
  });

  it('getResponseRate', () => {
    expect(
      getters.getResponseRate({
        metrics: { totalResponseCount: 0, totalSentMessagesCount: 0 },
      })
    ).toEqual(0);

    expect(
      getters.getResponseRate({
        metrics: { totalResponseCount: 20, totalSentMessagesCount: 50 },
      })
    ).toEqual('40.00');
  });

  it('getSatisfactionScore', () => {
    expect(
      getters.getSatisfactionScore({
        metrics: {
          totalResponseCount: 0,
          ratingsCount: { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 },
        },
      })
    ).toEqual(0);

    expect(
      getters.getSatisfactionScore({
        metrics: {
          totalResponseCount: 54,
          ratingsCount: { 1: 0, 2: 0, 3: 0, 4: 12, 5: 15 },
        },
      })
    ).toEqual('50.00');
  });
});
