import endPoints from '../endPoints';

describe('#sendMessage', () => {
  it('returns correct payload', () => {
    expect(endPoints.sendMessage('hello')).toEqual({
      url: `/api/v1/widget/messages`,
      params: {
        message: {
          content: 'hello',
        },
      },
    });
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
