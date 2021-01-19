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
