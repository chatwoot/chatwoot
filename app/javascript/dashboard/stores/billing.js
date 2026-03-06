import { defineStore } from 'pinia';
import BillingAPI from 'dashboard/api/billing';

export const useBillingStore = defineStore('billing', {
  state: () => ({
    subscription: null,
    plan: null,
    usage: null,
    plans: [],
    onTrial: false,
    trialActiveFlag: false,
    trialCreditsRemaining: 0,
    aiResponsesAllowed: true,
    uiFlags: {
      isFetching: false,
      isCheckingOut: false,
    },
  }),

  getters: {
    isSubscribed: state => state.subscription?.status === 'active',
    isOnTrial: state => state.onTrial,
    trialActive: state => state.trialActiveFlag,
    onGracePeriod: state => state.subscription?.on_grace_period || false,
    planTier: state => state.plan?.tier || null,
    usagePercentage: state => state.usage?.usage_percentage || 0,
    overageCount: state => state.usage?.overage_count || 0,
    inOverage: state => (state.usage?.overage_count || 0) > 0,
    shouldShowPaywall(state) {
      // Show paywall when on trial but trial is no longer active
      // (time expired OR credits exhausted) and not on a paid plan
      if (state.onTrial && !state.trialActiveFlag) return true;
      // Show paywall when no subscription and no trial
      if (!state.subscription && !state.onTrial) return false;
      return !state.aiResponsesAllowed && !state.isSubscribed;
    },
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
        this.onTrial = data.on_trial || false;
        this.trialActiveFlag = data.trial_active || false;
        this.trialCreditsRemaining = data.trial_credits_remaining || 0;
        this.aiResponsesAllowed = data.ai_responses_allowed ?? true;
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
