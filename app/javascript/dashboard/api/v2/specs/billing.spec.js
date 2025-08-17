import billingAPI from '../billing';
import ApiClient from '../../ApiClient';

describe('#billingAPI', () => {
  it('creates correct instance', () => {
    expect(billingAPI).toBeInstanceOf(ApiClient);
    expect(billingAPI).toHaveProperty('getSubscription');
    expect(billingAPI).toHaveProperty('createSubscription');
    expect(billingAPI).toHaveProperty('getBillingPortal');
    expect(billingAPI).toHaveProperty('getLimits');
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
      vi.clearAllMocks();
    });

    afterEach(() => {
      window.axios = originalAxios;
    });

    it('#getSubscription', () => {
      billingAPI.getSubscription();
      expect(axiosMock.get).toHaveBeenCalledWith('/api/v2/subscription');
    });

    it('#createSubscription with default plan', () => {
      billingAPI.createSubscription();
      expect(axiosMock.post).toHaveBeenCalledWith('/api/v2/subscription', {
        subscription: { plan_name: 'free' },
      });
    });

    it('#createSubscription with custom plan', () => {
      billingAPI.createSubscription('professional');
      expect(axiosMock.post).toHaveBeenCalledWith('/api/v2/subscription', {
        subscription: { plan_name: 'professional' },
      });
    });

    it('#getBillingPortal without return URL', () => {
      billingAPI.getBillingPortal();
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v2/subscription/portal',
        { params: {} }
      );
    });

    it('#getBillingPortal with return URL', () => {
      const returnUrl = 'https://example.com/billing';
      billingAPI.getBillingPortal(returnUrl);
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v2/subscription/portal',
        { params: { return_url: returnUrl } }
      );
    });

    it('#getLimits', () => {
      billingAPI.getLimits();
      expect(axiosMock.get).toHaveBeenCalledWith('/api/v2/subscription/limits');
    });
  });
});
