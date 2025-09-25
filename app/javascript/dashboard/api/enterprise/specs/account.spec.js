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
    expect(accountAPI).toHaveProperty('toggleDeletion');
  });

  describe('API calls', () => {
    const originalAxios = window.axios;
    const axiosMock = {
      post: vi.fn(() => Promise.resolve()),
      get: vi.fn(() => Promise.resolve()),
      patch: vi.fn(() => Promise.resolve()),
      delete: vi.fn(() => Promise.resolve()),
    };

    beforeEach(() => {
      window.axios = axiosMock;
    });

    afterEach(() => {
      window.axios = originalAxios;
    });

    it('#checkout', () => {
      accountAPI.checkout();
      expect(axiosMock.post).toHaveBeenCalledWith(
        '/enterprise/api/v1/checkout'
      );
    });

    it('#subscription', () => {
      accountAPI.subscription();
      expect(axiosMock.post).toHaveBeenCalledWith(
        '/enterprise/api/v1/subscription'
      );
    });

    it('#toggleDeletion with delete action', () => {
      accountAPI.toggleDeletion('delete');
      expect(axiosMock.post).toHaveBeenCalledWith(
        '/enterprise/api/v1/toggle_deletion',
        { action_type: 'delete' }
      );
    });

    it('#toggleDeletion with undelete action', () => {
      accountAPI.toggleDeletion('undelete');
      expect(axiosMock.post).toHaveBeenCalledWith(
        '/enterprise/api/v1/toggle_deletion',
        { action_type: 'undelete' }
      );
    });
  });
});
