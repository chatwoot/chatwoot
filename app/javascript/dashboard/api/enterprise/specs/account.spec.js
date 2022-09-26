import accountAPI from '../account';
import ApiClient from '../../ApiClient';
import describeWithAPIMock from '../../specs/apiSpecHelper';

describe('#enterpriseAccountAPI', () => {
  it('creates correct instance', () => {
    expect(accountAPI).toBeInstanceOf(ApiClient);
    expect(accountAPI).toHaveProperty('get');
    expect(accountAPI).toHaveProperty('show');
    expect(accountAPI).toHaveProperty('create');
    expect(accountAPI).toHaveProperty('update');
    expect(accountAPI).toHaveProperty('delete');
    expect(accountAPI).toHaveProperty('checkout');
  });

  describeWithAPIMock('API calls', context => {
    it('#checkout', () => {
      accountAPI.checkout();
      expect(context.axiosMock.post).toHaveBeenCalledWith(
        '/enterprise/api/v1/checkout'
      );
    });

    it('#subscription', () => {
      accountAPI.subscription();
      expect(context.axiosMock.post).toHaveBeenCalledWith(
        '/enterprise/api/v1/subscription'
      );
    });
  });
});
