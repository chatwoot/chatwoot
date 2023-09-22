import accountActionsAPI from '../accountActions';
import ApiClient from '../ApiClient';

describe('#ContactsAPI', () => {
  it('creates correct instance', () => {
    expect(accountActionsAPI).toBeInstanceOf(ApiClient);
    expect(accountActionsAPI).toHaveProperty('merge');
  });

  describe('API calls', context => {
    it('#merge', () => {
      accountActionsAPI.merge(1, 2);
      expect(axios.post).toHaveBeenCalledWith('/api/v1/actions/contact_merge', {
        base_contact_id: 1,
        mergee_contact_id: 2,
      });
    });
  });
});
