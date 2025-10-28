import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import * as types from '../mutation-types';
import AccountAPI from '../../api/account';
import { differenceInDays } from 'date-fns';
import EnterpriseAccountAPI from '../../api/enterprise/account';
import { throwErrorMessage } from '../utils/api';
import { getLanguageDirection } from 'dashboard/components/widgets/conversation/advancedFilterItems/languages';

const findRecordById = ($state, id) =>
  $state.records.find(record => record.id === Number(id)) || {};

const TRIAL_PERIOD_DAYS = 15;

const state = {
  records: [],
  uiFlags: {
    isFetching: false,
    isFetchingItem: false,
    isUpdating: false,
    isCheckoutInProcess: false,
  },
  v2Billing: {
    creditsBalance: null,
    creditGrants: [],
    pricingPlans: [],
    topupOptions: [],
    uiFlags: {
      isFetchingBalance: false,
      isFetchingGrants: false,
      isFetchingPlans: false,
      isFetchingTopupOptions: false,
      isTopupInProcess: false,
      isSubscribeInProcess: false,
      isCancelInProcess: false,
    },
  },
};

export const getters = {
  getAccount: $state => id => {
    return findRecordById($state, id);
  },
  getUIFlags($state) {
    return $state.uiFlags;
  },
  getV2BillingData($state) {
    return $state.v2Billing;
  },
  getV2BillingUIFlags($state) {
    return $state.v2Billing.uiFlags;
  },
  isRTL: ($state, _getters, rootState, rootGetters) => {
    const accountId = Number(rootState.route?.params?.accountId);
    const userLocale = rootGetters?.getUISettings?.locale;
    const accountLocale =
      accountId && findRecordById($state, accountId)?.locale;

    // Prefer user locale; fallback to account locale
    const effectiveLocale = userLocale ?? accountLocale;

    return effectiveLocale ? getLanguageDirection(effectiveLocale) : false;
  },
  isTrialAccount: $state => id => {
    const account = findRecordById($state, id);
    const createdAt = new Date(account.created_at);
    const diffDays = differenceInDays(new Date(), createdAt);

    return diffDays <= TRIAL_PERIOD_DAYS;
  },
  isFeatureEnabledonAccount: $state => (id, featureName) => {
    const { features = {} } = findRecordById($state, id);
    return features[featureName] || false;
  },
};

export const actions = {
  get: async ({ commit }) => {
    commit(types.default.SET_ACCOUNT_UI_FLAG, { isFetchingItem: true });
    try {
      const response = await AccountAPI.get();
      commit(types.default.ADD_ACCOUNT, response.data);
      commit(types.default.SET_ACCOUNT_UI_FLAG, {
        isFetchingItem: false,
      });
    } catch (error) {
      commit(types.default.SET_ACCOUNT_UI_FLAG, {
        isFetchingItem: false,
      });
    }
  },
  update: async ({ commit }, { options, ...updateObj }) => {
    if (options?.silent !== true) {
      commit(types.default.SET_ACCOUNT_UI_FLAG, { isUpdating: true });
    }

    try {
      const response = await AccountAPI.update('', updateObj);
      commit(types.default.EDIT_ACCOUNT, response.data);
      commit(types.default.SET_ACCOUNT_UI_FLAG, { isUpdating: false });
    } catch (error) {
      commit(types.default.SET_ACCOUNT_UI_FLAG, { isUpdating: false });
      throw new Error(error);
    }
  },
  delete: async ({ commit }, { id }) => {
    commit(types.default.SET_ACCOUNT_UI_FLAG, { isUpdating: true });
    try {
      await AccountAPI.delete(id);
      commit(types.default.SET_ACCOUNT_UI_FLAG, { isUpdating: false });
    } catch (error) {
      commit(types.default.SET_ACCOUNT_UI_FLAG, { isUpdating: false });
      throw new Error(error);
    }
  },
  toggleDeletion: async (
    { commit },
    { action_type } = { action_type: 'delete' }
  ) => {
    commit(types.default.SET_ACCOUNT_UI_FLAG, { isUpdating: true });
    try {
      await EnterpriseAccountAPI.toggleDeletion(action_type);
      commit(types.default.SET_ACCOUNT_UI_FLAG, { isUpdating: false });
    } catch (error) {
      commit(types.default.SET_ACCOUNT_UI_FLAG, { isUpdating: false });
      throw new Error(error);
    }
  },
  create: async ({ commit }, accountInfo) => {
    commit(types.default.SET_ACCOUNT_UI_FLAG, { isCreating: true });
    try {
      const response = await AccountAPI.createAccount(accountInfo);
      const account_id = response.data.data.account_id;
      commit(types.default.SET_ACCOUNT_UI_FLAG, { isCreating: false });
      return account_id;
    } catch (error) {
      commit(types.default.SET_ACCOUNT_UI_FLAG, { isCreating: false });
      throw error;
    }
  },

  checkout: async ({ commit }) => {
    commit(types.default.SET_ACCOUNT_UI_FLAG, { isCheckoutInProcess: true });
    try {
      const response = await EnterpriseAccountAPI.checkout();
      window.location = response.data.redirect_url;
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.default.SET_ACCOUNT_UI_FLAG, { isCheckoutInProcess: false });
    }
  },

  subscription: async ({ commit }) => {
    commit(types.default.SET_ACCOUNT_UI_FLAG, { isCheckoutInProcess: true });
    try {
      await EnterpriseAccountAPI.subscription();
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.default.SET_ACCOUNT_UI_FLAG, { isCheckoutInProcess: false });
    }
  },

  limits: async ({ commit }) => {
    try {
      const response = await EnterpriseAccountAPI.getLimits();
      commit(types.default.SET_ACCOUNT_LIMITS, response.data);
    } catch (error) {
      // silent error
    }
  },

  getCacheKeys: async () => {
    return AccountAPI.getCacheKeys();
  },

  // V2 Billing actions
  fetchCreditsBalance: async ({ commit }) => {
    commit(types.default.SET_V2_BILLING_UI_FLAG, { isFetchingBalance: true });
    try {
      const response = await EnterpriseAccountAPI.creditsBalance();
      commit(types.default.SET_CREDITS_BALANCE, response.data);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.default.SET_V2_BILLING_UI_FLAG, {
        isFetchingBalance: false,
      });
    }
  },

  fetchCreditGrants: async ({ commit }) => {
    commit(types.default.SET_V2_BILLING_UI_FLAG, { isFetchingGrants: true });
    try {
      const response = await EnterpriseAccountAPI.creditGrants();
      commit(types.default.SET_CREDIT_GRANTS, response.data.credit_grants);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.default.SET_V2_BILLING_UI_FLAG, {
        isFetchingGrants: false,
      });
    }
  },

  fetchV2PricingPlans: async ({ commit }) => {
    commit(types.default.SET_V2_BILLING_UI_FLAG, { isFetchingPlans: true });
    try {
      const response = await EnterpriseAccountAPI.v2PricingPlans();
      commit(types.default.SET_V2_PRICING_PLANS, response.data.pricing_plans);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.default.SET_V2_BILLING_UI_FLAG, { isFetchingPlans: false });
    }
  },

  fetchV2TopupOptions: async ({ commit }) => {
    commit(types.default.SET_V2_BILLING_UI_FLAG, {
      isFetchingTopupOptions: true,
    });
    try {
      const response = await EnterpriseAccountAPI.v2TopupOptions();
      // Transform backend structure: rename 'amount' to 'price'
      const transformedOptions = response.data.topup_options.map(option => ({
        ...option,
        price: option.amount,
        id: `topup-${option.credits}`,
      }));
      commit(types.default.SET_V2_TOPUP_OPTIONS, transformedOptions);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.default.SET_V2_BILLING_UI_FLAG, {
        isFetchingTopupOptions: false,
      });
    }
  },

  v2Topup: async ({ commit, dispatch }, data) => {
    commit(types.default.SET_V2_BILLING_UI_FLAG, { isTopupInProcess: true });
    try {
      await EnterpriseAccountAPI.v2Topup(data);
      // Refresh balance and ledger after successful topup
      await dispatch('fetchCreditsBalance');
      return { success: true };
    } catch (error) {
      const errorMessage = error.response?.data?.error || error.message;
      return { success: false, error: errorMessage };
    } finally {
      commit(types.default.SET_V2_BILLING_UI_FLAG, { isTopupInProcess: false });
    }
  },

  v2Subscribe: async ({ commit, dispatch }, data) => {
    commit(types.default.SET_V2_BILLING_UI_FLAG, {
      isSubscribeInProcess: true,
    });
    try {
      const response = await EnterpriseAccountAPI.v2Subscribe(data);
      // If backend returns redirect_url, redirect to Stripe checkout
      if (response.data.redirect_url) {
        window.location.href = response.data.redirect_url;
        return { success: true, redirecting: true };
      }
      // Otherwise refresh data (for non-Stripe flows)
      await Promise.all([
        dispatch('fetchCreditsBalance'),
        dispatch('fetchV2PricingPlans'),
        dispatch('subscription'),
      ]);
      return { success: true };
    } catch (error) {
      throwErrorMessage(error);
      return { success: false };
    } finally {
      commit(types.default.SET_V2_BILLING_UI_FLAG, {
        isSubscribeInProcess: false,
      });
    }
  },

  v2CancelSubscription: async ({ commit, dispatch }, data) => {
    commit(types.default.SET_V2_BILLING_UI_FLAG, { isCancelInProcess: true });
    try {
      const response = await EnterpriseAccountAPI.cancelSubscription(data);
      // Update account with new subscription status
      if (response.data.id && response.data.custom_attributes) {
        commit(types.default.SET_ACCOUNT_LIMITS, response.data);
      }
      // Refresh balance and plans after cancellation
      await Promise.all([
        dispatch('fetchCreditsBalance'),
        dispatch('fetchV2PricingPlans'),
      ]);
      return { success: true };
    } catch (error) {
      const errorMessage = error.response?.data?.error || error.message;
      return { success: false, error: errorMessage };
    } finally {
      commit(types.default.SET_V2_BILLING_UI_FLAG, {
        isCancelInProcess: false,
      });
    }
  },

  v2UpdateQuantity: async ({ commit, dispatch }, { quantity }) => {
    commit(types.default.SET_V2_BILLING_UI_FLAG, {
      isSubscribeInProcess: true,
    });
    try {
      const response =
        await EnterpriseAccountAPI.updateSubscriptionQuantity(quantity);
      // Update account with new quantity
      if (response.data.id && response.data.custom_attributes) {
        commit(types.default.SET_ACCOUNT_LIMITS, response.data);
      }
      // Refresh balance after quantity update
      await dispatch('fetchCreditsBalance');
      return { success: true };
    } catch (error) {
      const errorMessage = error.response?.data?.error || error.message;
      return { success: false, error: errorMessage };
    } finally {
      commit(types.default.SET_V2_BILLING_UI_FLAG, {
        isSubscribeInProcess: false,
      });
    }
  },

  v2ChangePlan: async ({ commit, dispatch }, data) => {
    commit(types.default.SET_V2_BILLING_UI_FLAG, {
      isSubscribeInProcess: true,
    });
    try {
      const response = await EnterpriseAccountAPI.changePricingPlan(data);
      // Update account with new plan
      if (response.data.id && response.data.custom_attributes) {
        commit(types.default.SET_ACCOUNT_LIMITS, response.data);
      }
      // Refresh balance and plans after change
      await Promise.all([
        dispatch('fetchCreditsBalance'),
        dispatch('fetchV2PricingPlans'),
      ]);
      return { success: true };
    } catch (error) {
      const errorMessage = error.response?.data?.error || error.message;
      return { success: false, error: errorMessage };
    } finally {
      commit(types.default.SET_V2_BILLING_UI_FLAG, {
        isSubscribeInProcess: false,
      });
    }
  },
};

export const mutations = {
  [types.default.SET_ACCOUNT_UI_FLAG]($state, data) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...data,
    };
  },
  [types.default.ADD_ACCOUNT]: MutationHelpers.setSingleRecord,
  [types.default.EDIT_ACCOUNT]: MutationHelpers.update,
  [types.default.SET_ACCOUNT_LIMITS]: MutationHelpers.updateAttributes,

  // V2 Billing mutations
  [types.default.SET_V2_BILLING_UI_FLAG]($state, data) {
    $state.v2Billing.uiFlags = {
      ...$state.v2Billing.uiFlags,
      ...data,
    };
  },
  [types.default.SET_CREDITS_BALANCE]($state, data) {
    $state.v2Billing.creditsBalance = data;
  },
  [types.default.SET_CREDIT_GRANTS]($state, data) {
    $state.v2Billing.creditGrants = data;
  },
  [types.default.SET_V2_PRICING_PLANS]($state, data) {
    $state.v2Billing.pricingPlans = data;
  },
  [types.default.SET_V2_TOPUP_OPTIONS]($state, data) {
    $state.v2Billing.topupOptions = data;
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
