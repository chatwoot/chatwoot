import { getters } from '../../draftMessages';
import { data } from './fixtures';

describe('#getters', () => {
  it('get', () => {
    const state = {
      records: data,
    };
    expect(getters.get(state)).toEqual({
      'draft-32-REPLY': 'Hey how ',
      'draft-31-REPLY': 'Nice',
    });
  });
});
