import accountAPI from '../account';
import ApiClient from '../ApiClient';
import describeWithAPIMock from './apiSpecHelper';

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

  describeWithAPIMock('API calls', context => {
    it('#createAccount', () => {
      accountAPI.createAccount({
        name: 'Chatwoot',
      });
      expect(context.axiosMock.post).toHaveBeenCalledWith('/api/v1/accounts', {
        name: 'Chatwoot',
      });
    });
  });
});
