import { setActivePinia, createPinia } from 'pinia';
import { useBillingStore } from '../billing';
import BillingAPI from 'dashboard/api/billing';

vi.mock('dashboard/api/billing');

describe('useBillingStore', () => {
  let store;

  beforeEach(() => {
    setActivePinia(createPinia());
    store = useBillingStore();
  });

  describe('initial state', () => {
    it('has correct defaults', () => {
      expect(store.subscription).toBeNull();
      expect(store.plan).toBeNull();
      expect(store.usage).toBeNull();
      expect(store.plans).toEqual([]);
      expect(store.uiFlags.isFetching).toBe(false);
      expect(store.uiFlags.isCheckingOut).toBe(false);
    });
  });

  describe('getters', () => {
    it('#isSubscribed returns true when status is active', () => {
      store.subscription = { status: 'active' };
      expect(store.isSubscribed).toBe(true);
    });

    it('#isSubscribed returns false when no subscription', () => {
      expect(store.isSubscribed).toBe(false);
    });

    it('#isOnTrial returns true when active with trial_ends_at', () => {
      store.subscription = {
        status: 'active',
        trial_ends_at: '2026-04-01T00:00:00Z',
      };
      expect(store.isOnTrial).toBe(true);
    });

    it('#isOnTrial returns false when active without trial_ends_at', () => {
      store.subscription = { status: 'active' };
      expect(store.isOnTrial).toBe(false);
    });

    it('#onGracePeriod returns the grace period flag', () => {
      store.subscription = { on_grace_period: true };
      expect(store.onGracePeriod).toBe(true);
    });

    it('#planTier returns the plan tier', () => {
      store.plan = { tier: 'pro' };
      expect(store.planTier).toBe('pro');
    });

    it('#usagePercentage returns percentage from usage', () => {
      store.usage = { usage_percentage: 72 };
      expect(store.usagePercentage).toBe(72);
    });
  });

  describe('actions', () => {
    describe('#fetch', () => {
      it('fetches subscription data and sets state', async () => {
        const responseData = {
          subscription: { status: 'active', current_period_end: '2026-04-01' },
          plan: { name: 'Pro', key: 'pro_monthly', tier: 'pro' },
          usage: { ai_responses_count: 50, ai_responses_limit: 500 },
          plans: [{ key: 'basic_monthly' }, { key: 'pro_monthly' }],
        };
        BillingAPI.getSubscription.mockResolvedValue({ data: responseData });

        await store.fetch();

        expect(BillingAPI.getSubscription).toHaveBeenCalled();
        expect(store.subscription).toEqual(responseData.subscription);
        expect(store.plan).toEqual(responseData.plan);
        expect(store.usage).toEqual(responseData.usage);
        expect(store.plans).toEqual(responseData.plans);
        expect(store.uiFlags.isFetching).toBe(false);
      });

      it('sets isFetching flag during request', async () => {
        BillingAPI.getSubscription.mockImplementation(
          () =>
            new Promise(resolve => {
              expect(store.uiFlags.isFetching).toBe(true);
              resolve({ data: {} });
            })
        );

        await store.fetch();
        expect(store.uiFlags.isFetching).toBe(false);
      });

      it('resets isFetching on error', async () => {
        BillingAPI.getSubscription.mockRejectedValue(new Error('fail'));

        await expect(store.fetch()).rejects.toThrow('fail');
        expect(store.uiFlags.isFetching).toBe(false);
      });
    });

    describe('#checkout', () => {
      it('redirects to checkout URL', async () => {
        const originalLocation = window.location;
        delete window.location;
        window.location = { href: '' };

        BillingAPI.createCheckout.mockResolvedValue({
          data: { checkout_url: 'https://checkout.stripe.com/session_123' },
        });

        await store.checkout('pro_monthly');

        expect(BillingAPI.createCheckout).toHaveBeenCalledWith('pro_monthly');
        expect(window.location.href).toBe(
          'https://checkout.stripe.com/session_123'
        );

        window.location = originalLocation;
      });

      it('resets isCheckingOut on error', async () => {
        BillingAPI.createCheckout.mockRejectedValue(new Error('fail'));

        await expect(store.checkout('pro_monthly')).rejects.toThrow('fail');
        expect(store.uiFlags.isCheckingOut).toBe(false);
      });
    });

    describe('#openPortal', () => {
      it('redirects to portal URL', async () => {
        const originalLocation = window.location;
        delete window.location;
        window.location = { href: '' };

        BillingAPI.getPortalUrl.mockResolvedValue({
          data: { portal_url: 'https://billing.stripe.com/portal_123' },
        });

        await store.openPortal();

        expect(BillingAPI.getPortalUrl).toHaveBeenCalled();
        expect(window.location.href).toBe(
          'https://billing.stripe.com/portal_123'
        );

        window.location = originalLocation;
      });
    });

    describe('#swapPlan', () => {
      it('swaps plan and refetches', async () => {
        BillingAPI.swapPlan.mockResolvedValue({});
        BillingAPI.getSubscription.mockResolvedValue({
          data: {
            subscription: { status: 'active' },
            plan: { key: 'basic_monthly' },
            usage: {},
            plans: [],
          },
        });

        await store.swapPlan('basic_monthly');

        expect(BillingAPI.swapPlan).toHaveBeenCalledWith('basic_monthly');
        expect(BillingAPI.getSubscription).toHaveBeenCalled();
      });
    });

    describe('#cancel', () => {
      it('cancels and refetches', async () => {
        BillingAPI.cancel.mockResolvedValue({});
        BillingAPI.getSubscription.mockResolvedValue({
          data: {
            subscription: { status: 'canceled' },
            plan: null,
            usage: null,
            plans: [],
          },
        });

        await store.cancel();

        expect(BillingAPI.cancel).toHaveBeenCalled();
        expect(BillingAPI.getSubscription).toHaveBeenCalled();
      });
    });

    describe('#resume', () => {
      it('resumes and refetches', async () => {
        BillingAPI.resume.mockResolvedValue({});
        BillingAPI.getSubscription.mockResolvedValue({
          data: {
            subscription: { status: 'active' },
            plan: { key: 'pro_monthly' },
            usage: {},
            plans: [],
          },
        });

        await store.resume();

        expect(BillingAPI.resume).toHaveBeenCalled();
        expect(BillingAPI.getSubscription).toHaveBeenCalled();
      });
    });
  });
});
