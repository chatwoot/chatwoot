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

    it('#createAccount', () => {
      accountAPI.createAccount({
        name: 'Chatwoot',
      });
      expect(axiosMock.post).toHaveBeenCalledWith('/api/v1/accounts', {
        name: 'Chatwoot',
      });
    });
  });
});
