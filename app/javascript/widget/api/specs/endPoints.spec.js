import endPoints from '../endPoints';

jest.mock('vue', () => ({ config: { lang: 'ar' } }));

describe('#sendMessage', () => {
  it('returns correct payload', () => {
    const spy = jest.spyOn(global, 'Date').mockImplementation(() => ({
      toString: () => 'mock date',
    }));
    expect(endPoints.sendMessage('hello')).toEqual({
      url: `/api/v1/widget/messages?locale=ar`,
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
    expect(endPoints.getConversation({ before: 123 })).toEqual({
      url: `/api/v1/widget/messages`,
      params: {
        before: 123,
      },
    });
  });
});
