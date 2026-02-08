import { getters } from '../../campaigns';
import campaigns from './fixtures';

describe('#getters', () => {
  it('get ongoing campaigns', () => {
    const state = { records: campaigns };
    expect(getters.getCampaigns(state)('ongoing')).toEqual([
      campaigns[0],
      campaigns[2],
    ]);
  });

  it('get one_off campaigns', () => {
    const state = { records: campaigns };
    expect(getters.getCampaigns(state)('one_off')).toEqual([
      {
        id: 2,
        title: 'Onboarding Campaign',
        description: null,
        account_id: 1,
        campaign_type: 'one_off',

        trigger_rules: {
          url: 'https://chatwoot.com',
          time_on_page: '20',
        },
        created_at: '2021-05-03T08:15:35.828Z',
        updated_at: '2021-05-03T08:15:35.828Z',
      },
    ]);
  });

  it('get all campaigns', () => {
    const state = { records: campaigns };
    expect(getters.getAllCampaigns(state)).toEqual(campaigns);
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
