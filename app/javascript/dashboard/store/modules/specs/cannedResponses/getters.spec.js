import CannedResponses from '../../cannedResponse';

const CANNED_RESPONSES = [
  { short_code: 'hello', content: 'Hi ' },
  { short_code: 'ask', content: 'Ask questions' },
  { short_code: 'greet', content: 'Good morning' },
];

const getters = CannedResponses.getters;

describe('#getCannedResponses', () => {
  it('returns canned responses', () => {
    const state = { records: CANNED_RESPONSES };
    expect(getters.getCannedResponses(state)).toEqual(CANNED_RESPONSES);
  });
});

describe('#getSortedCannedResponses', () => {
  it('returns sort canned responses in ascending order', () => {
    const state = { records: CANNED_RESPONSES };
    expect(getters.getSortedCannedResponses(state)('asc')).toEqual([
      CANNED_RESPONSES[1],
      CANNED_RESPONSES[2],
      CANNED_RESPONSES[0],
    ]);
  });

  it('returns sort canned responses in descending order', () => {
    const state = { records: CANNED_RESPONSES };
    expect(getters.getSortedCannedResponses(state)('desc')).toEqual([
      CANNED_RESPONSES[0],
      CANNED_RESPONSES[2],
      CANNED_RESPONSES[1],
    ]);
  });
});

describe('#getUIFlags', () => {
  it('returns uiFlags', () => {
    const state = { uiFlags: { isFetching: true } };
    expect(getters.getUIFlags(state)).toEqual({ isFetching: true });
  });
});
