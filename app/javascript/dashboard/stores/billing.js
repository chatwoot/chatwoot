import { defineStore } from 'pinia';
import BillingAPI from 'dashboard/api/billing';

export const useBillingStore = defineStore('billing', {
  state: () => ({
    subscription: null,
    plan: null,
    usage: null,
    plans: [],
    uiFlags: {
      isFetching: false,
      isCheckingOut: false,
    },
  }),

  getters: {
    isSubscribed: state => state.subscription?.status === 'active',
    isOnTrial: state =>
      state.subscription?.status === 'active' &&
      !!state.subscription?.trial_ends_at,
    onGracePeriod: state => state.subscription?.on_grace_period || false,
    planTier: state => state.plan?.tier || null,
    usagePercentage: state => state.usage?.usage_percentage || 0,
  },

  actions: {
    async fetch() {
      this.uiFlags.isFetching = true;
      try {
        const { data } = await BillingAPI.getSubscription();
        this.subscription = data.subscription;
        this.plan = data.plan;
        this.usage = data.usage;
        this.plans = data.plans;
      } finally {
        this.uiFlags.isFetching = false;
      }
    },

    async checkout(planKey) {
      this.uiFlags.isCheckingOut = true;
      try {
        const { data } = await BillingAPI.createCheckout(planKey);
        window.location.href = data.checkout_url;
      } finally {
        this.uiFlags.isCheckingOut = false;
      }
    },

    async openPortal() {
      const { data } = await BillingAPI.getPortalUrl();
      window.location.href = data.portal_url;
    },

    async swapPlan(planKey) {
      await BillingAPI.swapPlan(planKey);
      await this.fetch();
    },

    async cancel() {
      await BillingAPI.cancel();
      await this.fetch();
    },

    async resume() {
      await BillingAPI.resume();
      await this.fetch();
    },
  },
});
