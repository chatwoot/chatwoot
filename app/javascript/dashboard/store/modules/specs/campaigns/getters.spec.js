import { getters } from '../../campaigns';
import campaigns from './fixtures';

describe('#getters', () => {
  it('get ongoing campaigns', () => {
    const state = { records: campaigns };
    expect(getters.getCampaigns(state)('ongoing')).toEqual([
      {
        id: 1,
        title: 'Welcome',
        description: null,
        account_id: 1,
        campaign_type: 'ongoing',
        message: 'Hey, What brings you today',
        enabled: true,
        trigger_rules: {
          url: 'https://github.com',
          time_on_page: 10,
        },
        created_at: '2021-05-03T04:53:36.354Z',
        updated_at: '2021-05-03T04:53:36.354Z',
      },
      {
        id: 3,
        title: 'Thanks',
        description: null,
        account_id: 1,
        campaign_type: 'ongoing',
        message: 'Thanks for coming to the show. How may I help you?',
        enabled: false,
        trigger_rules: {
          url: 'https://noshow.com',
          time_on_page: 10,
        },
        created_at: '2021-05-03T10:22:51.025Z',
        updated_at: '2021-05-03T10:22:51.025Z',
      },
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
