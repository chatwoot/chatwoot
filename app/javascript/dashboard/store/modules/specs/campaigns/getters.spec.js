import { getters } from '../../campaigns';
import campaigns from './fixtures';

describe('#getters', () => {
  it('getCampaigns', () => {
    const state = { records: campaigns };
    expect(getters.getCampaigns(state)).toEqual(campaigns);
  });

  it('getUIFlags', () => {
    const state = {
      uiFlags: {
        isFetching: true,
        isCreating: false,
      },
    };
    expect(getters.getUIFlags(state)).toEqual({
      isFetching: true,
      isCreating: false,
    });
  });
});
