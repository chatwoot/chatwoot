import { getters } from '../../campaign';
import { campaigns } from './data';
jest.mock('widget/store/index.js');

describe('#getters', () => {
  it('getCampaigns', () => {
    const state = {
      records: campaigns,
    };
    expect(getters.getCampaigns(state)).toEqual([
      {
        id: 1,
        title: 'Welcome',
        description: null,
        account_id: 1,
        inbox: {
          id: 37,
          channel_id: 1,
          name: 'Chatwoot',
          channel_type: 'Channel::WebWidget',
        },
        sender: {
          account_id: 1,
          availability_status: 'offline',
          confirmed: true,
          email: 'sojan@chatwoot.com',
          available_name: 'Sojan',
          id: 10,
          name: 'Sojan',
        },
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
        id: 11,
        title: 'Onboarding Campaign',
        description: null,
        account_id: 1,
        inbox: {
          id: 37,
          channel_id: 1,
          name: 'GitX',
          channel_type: 'Channel::WebWidget',
        },
        sender: {
          account_id: 1,
          availability_status: 'offline',
          confirmed: true,
          email: 'sojan@chatwoot.com',
          available_name: 'Sojan',
          id: 10,
        },
        message: 'Begin your onboarding campaign with a welcome message',
        enabled: true,
        trigger_rules: {
          url: 'https://chatwoot.com',
          time_on_page: '20',
        },
        created_at: '2021-05-03T08:15:35.828Z',
        updated_at: '2021-05-03T08:15:35.828Z',
      },
      {
        id: 12,
        title: 'Thanks',
        description: null,
        account_id: 1,
        inbox: {
          id: 37,
          channel_id: 1,
          name: 'Chatwoot',
          channel_type: 'Channel::WebWidget',
        },
        sender: {
          account_id: 1,
          availability_status: 'offline',
          confirmed: true,
          email: 'nithin@chatwoot.com',
          available_name: 'Nithin',
        },
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

  it('getActiveCampaign', () => {
    const state = {
      records: campaigns[0],
    };
    expect(getters.getCampaigns(state)).toEqual({
      id: 1,
      title: 'Welcome',
      description: null,
      account_id: 1,
      inbox: {
        id: 37,
        channel_id: 1,
        name: 'Chatwoot',
        channel_type: 'Channel::WebWidget',
      },
      sender: {
        account_id: 1,
        availability_status: 'offline',
        confirmed: true,
        email: 'sojan@chatwoot.com',
        available_name: 'Sojan',
        id: 10,
        name: 'Sojan',
      },
      message: 'Hey, What brings you today',
      enabled: true,
      trigger_rules: {
        url: 'https://github.com',
        time_on_page: 10,
      },
      created_at: '2021-05-03T04:53:36.354Z',
      updated_at: '2021-05-03T04:53:36.354Z',
    });
  });
  it('getCampaignHasExecuted', () => {
    const state = {
      records: [],
      uiFlags: {
        isError: false,
        hasFetched: false,
      },
      activeCampaign: {},
      campaignHasExecuted: false,
    };

    expect(getters.getCampaignHasExecuted(state)).toEqual(false);
  });
});
