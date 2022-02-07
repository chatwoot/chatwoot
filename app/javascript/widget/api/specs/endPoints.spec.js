import endPoints from '../endPoints';

describe('#sendMessage', () => {
  it('returns correct payload', () => {
    const spy = jest.spyOn(global, 'Date').mockImplementation(() => ({
      toString: () => 'mock date',
    }));
    const windowSpy = jest.spyOn(window, 'window', 'get');
    windowSpy.mockImplementation(() => ({
      WOOT_WIDGET: {
        $root: {
          $i18n: {
            locale: 'ar',
          },
        },
      },
      location: {
        search: '?param=1',
      },
    }));

    expect(endPoints.sendMessage('hello')).toEqual({
      url: `/api/v1/widget/messages?param=1&locale=ar`,
      params: {
        message: {
          content: 'hello',
          referer_url: '',
          timestamp: 'mock date',
        },
      },
    });
    windowSpy.mockRestore();
    spy.mockRestore();
  });
});

describe('#getConversation', () => {
  it('returns correct payload', () => {
    expect(endPoints.getConversation({ before: 123 })).toEqual({
      url: `/api/v1/widget/messages`,
      params: {
        before: 123,
      },
    });
  });
});

describe('#triggerCampaign', () => {
  it('should returns correct payload', () => {
    const spy = jest.spyOn(global, 'Date').mockImplementation(() => ({
      toString: () => 'mock date',
    }));
    const windowSpy = jest.spyOn(window, 'window', 'get');
    const websiteToken = 'ADSDJ2323MSDSDFMMMASDM';
    const campaignId = 12;
    expect(
      endPoints.triggerCampaign({
        websiteToken,
        campaignId,
      })
    ).toEqual({
      url: `/api/v1/widget/events`,
      data: {
        name: 'campaign.triggered',
        event_info: {
          campaign_id: campaignId,
          referer: '',
          initiated_at: {
            timestamp: 'mock date',
          },
        },
      },
      params: {
        website_token: websiteToken,
      },
    });
    windowSpy.mockRestore();

    spy.mockRestore();
  });
});
