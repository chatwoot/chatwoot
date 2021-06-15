import endPoints from '../endPoints';

describe('#endPoints', () => {
  it('it should return register url details if register page passed  ', () => {
    expect(endPoints('register')).toEqual({ url: 'api/v1/accounts.json' });
  });
  it('it should inbox url details if getInbox page passed', () => {
    expect(endPoints('getInbox')).toEqual({
      url: 'api/v1/conversations.json',
      params: { inbox_id: null },
    });
  });
});
