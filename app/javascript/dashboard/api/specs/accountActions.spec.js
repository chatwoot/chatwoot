import accountActionsAPI from '../accountActions';
import ApiClient from '../ApiClient';

describe('#ContactsAPI', () => {
  it('creates correct instance', () => {
    expect(accountActionsAPI).toBeInstanceOf(ApiClient);
    expect(accountActionsAPI).toHaveProperty('merge');
  });

  describe('API calls', () => {
    const originalAxios = window.axios;
    const axiosMock = {
      post: jest.fn(() => Promise.resolve()),
      get: jest.fn(() => Promise.resolve()),
      patch: jest.fn(() => Promise.resolve()),
      delete: jest.fn(() => Promise.resolve()),
    };

    beforeEach(() => {
      window.axios = axiosMock;
    });

    afterEach(() => {
      window.axios = originalAxios;
    });

    it('#merge', () => {
      accountActionsAPI.merge(1, 2);
      expect(axiosMock.post).toHaveBeenCalledWith(
        '/api/v1/actions/contact_merge',
        {
          base_contact_id: 1,
          mergee_contact_id: 2,
        }
      );
    });
  });
});
