import accountAPI from '../account';
import ApiClient from '../ApiClient';

describe('#accountAPI', () => {
  it('creates correct instance', () => {
    expect(accountAPI).toBeInstanceOf(ApiClient);
    expect(accountAPI).toHaveProperty('get');
    expect(accountAPI).toHaveProperty('show');
    expect(accountAPI).toHaveProperty('create');
    expect(accountAPI).toHaveProperty('update');
    expect(accountAPI).toHaveProperty('delete');
    expect(accountAPI).toHaveProperty('createAccount');
  });

  describe('API calls', context => {
    it('#createAccount', () => {
      accountAPI.createAccount({
        name: 'Chatwoot',
      });
      expect(axios.post).toHaveBeenCalledWith('/api/v1/accounts', {
        name: 'Chatwoot',
      });
    });
  });
});
