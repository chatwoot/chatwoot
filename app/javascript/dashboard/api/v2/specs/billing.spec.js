import billingAPI from '../billing';
import ApiClient from '../../ApiClient';

describe('#billingAPI', () => {
  it('creates correct instance', () => {
    expect(billingAPI).toBeInstanceOf(ApiClient);
    expect(billingAPI).toHaveProperty('get');
    expect(billingAPI).toHaveProperty('show');
    expect(billingAPI).toHaveProperty('create');
    expect(billingAPI).toHaveProperty('update');
    expect(billingAPI).toHaveProperty('delete');
    expect(billingAPI).toHaveProperty('getSubscription');
    expect(billingAPI).toHaveProperty('createSubscription');
    expect(billingAPI).toHaveProperty('getBillingPortal');
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

    it('#getSubscription', () => {
      billingAPI.getSubscription();
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v2/accounts/subscription'
      );
    });

    it('#createSubscription with default plan', () => {
      billingAPI.createSubscription();
      expect(axiosMock.post).toHaveBeenCalledWith(
        '/api/v2/accounts/subscription',
        { subscription: { plan_name: 'free_trial' } }
      );
    });

    it('#createSubscription with custom plan', () => {
      billingAPI.createSubscription('professional');
      expect(axiosMock.post).toHaveBeenCalledWith(
        '/api/v2/accounts/subscription',
        { subscription: { plan_name: 'professional' } }
      );
    });

    it('#getBillingPortal without return URL', () => {
      billingAPI.getBillingPortal();
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v2/accounts/subscription/portal',
        { params: {} }
      );
    });

    it('#getBillingPortal with return URL', () => {
      const returnUrl = 'https://example.com/billing';
      billingAPI.getBillingPortal(returnUrl);
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v2/accounts/subscription/portal',
        { params: { return_url: returnUrl } }
      );
    });
  });
});
