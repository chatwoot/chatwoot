import endPoints from '../endPoints';

describe('#sendMessage', () => {
  it('returns correct payload', () => {
    const spy = vi.spyOn(global, 'Date').mockImplementation(() => ({
      toString: () => 'mock date',
    }));
    vi.spyOn(window, 'location', 'get').mockReturnValue({
      ...window.location,
      search: '?param=1',
    });

    window.WOOT_WIDGET = {
      $root: {
        $i18n: {
          locale: 'ar',
        },
      },
    };

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
    spy.mockRestore();
  });
});

describe('#getConversation', () => {
  it('returns correct payload', () => {
    vi.spyOn(window, 'location', 'get').mockReturnValue({
      ...window.location,
      search: '',
    });
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
    const spy = vi.spyOn(global, 'Date').mockImplementation(() => ({
      toString: () => 'mock date',
    }));
    vi.spyOn(window, 'location', 'get').mockReturnValue({
      ...window.location,
      search: '',
    });
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

    spy.mockRestore();
  });
});

describe('#getConversation', () => {
  it('should returns correct payload', () => {
    const spy = vi.spyOn(global, 'Date').mockImplementation(() => ({
      toString: () => 'mock date',
    }));
    vi.spyOn(window, 'location', 'get').mockReturnValue({
      ...window.location,
      search: '',
    });
    expect(
      endPoints.getConversation({
        after: 123,
      })
    ).toEqual({
      url: `/api/v1/widget/messages`,
      params: {
        after: 123,
        before: undefined,
      },
    });

    spy.mockRestore();
  });
});
