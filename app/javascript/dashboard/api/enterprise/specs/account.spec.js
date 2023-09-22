import accountAPI from '../account';
import ApiClient from '../../ApiClient';

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

  describe('API calls', context => {
    it('#checkout', () => {
      accountAPI.checkout();
      expect(axios.post).toHaveBeenCalledWith('/enterprise/api/v1/checkout');
    });

    it('#subscription', () => {
      accountAPI.subscription();
      expect(axios.post).toHaveBeenCalledWith(
        '/enterprise/api/v1/subscription'
      );
    });
  });
});
