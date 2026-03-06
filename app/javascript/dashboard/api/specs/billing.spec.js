import billingAPI from '../billing';
import ApiClient from '../ApiClient';

describe('#billingAPI', () => {
  it('creates correct instance', () => {
    expect(billingAPI).toBeInstanceOf(ApiClient);
    expect(billingAPI).toHaveProperty('getSubscription');
    expect(billingAPI).toHaveProperty('createCheckout');
    expect(billingAPI).toHaveProperty('getPortalUrl');
    expect(billingAPI).toHaveProperty('swapPlan');
    expect(billingAPI).toHaveProperty('cancel');
    expect(billingAPI).toHaveProperty('resume');
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
      expect(axiosMock.get).toHaveBeenCalledWith(billingAPI.url);
    });

    it('#createCheckout', () => {
      billingAPI.createCheckout('pro_monthly');
      expect(axiosMock.post).toHaveBeenCalledWith(
        `${billingAPI.url}/checkout`,
        { plan_key: 'pro_monthly' }
      );
    });

    it('#getPortalUrl', () => {
      billingAPI.getPortalUrl();
      expect(axiosMock.post).toHaveBeenCalledWith(`${billingAPI.url}/portal`);
    });

    it('#swapPlan', () => {
      billingAPI.swapPlan('basic_yearly');
      expect(axiosMock.post).toHaveBeenCalledWith(`${billingAPI.url}/swap`, {
        plan_key: 'basic_yearly',
      });
    });

    it('#cancel', () => {
      billingAPI.cancel();
      expect(axiosMock.post).toHaveBeenCalledWith(`${billingAPI.url}/cancel`);
    });

    it('#resume', () => {
      billingAPI.resume();
      expect(axiosMock.post).toHaveBeenCalledWith(`${billingAPI.url}/resume`);
    });
  });
});
