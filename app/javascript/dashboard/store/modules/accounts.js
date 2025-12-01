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
    isFetchingPricingPlans: false,
    isFetchingTopupOptions: false,
    isFetchingCreditGrants: false,
    isChangingPlan: false,
    isCancellingSubscription: false,
    isPurchasingCredits: false,
    isSubscribing: false,
  },
  pricingPlans: [],
  topupOptions: [],
  creditGrants: [],
};

export const getters = {
  getAccount: $state => id => {
    return findRecordById($state, id);
  },
  getUIFlags($state) {
    return $state.uiFlags;
  },
  getPricingPlans($state) {
    return $state.pricingPlans;
  },
  getTopupOptions($state) {
    return $state.topupOptions;
  },
  getCreditGrants($state) {
    return $state.creditGrants;
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

  // V2 Billing Actions
  fetchPricingPlans: async ({ commit }) => {
    commit(types.default.SET_ACCOUNT_UI_FLAG, { isFetchingPricingPlans: true });
    try {
      const response = await EnterpriseAccountAPI.getPricingPlans();
      commit(types.default.SET_PRICING_PLANS, response.data.pricing_plans);
    } catch (error) {
      // silent error
    } finally {
      commit(types.default.SET_ACCOUNT_UI_FLAG, {
        isFetchingPricingPlans: false,
      });
    }
  },

  fetchTopupOptions: async ({ commit }) => {
    commit(types.default.SET_ACCOUNT_UI_FLAG, { isFetchingTopupOptions: true });
    try {
      const response = await EnterpriseAccountAPI.getTopupOptions();
      commit(types.default.SET_TOPUP_OPTIONS, response.data.topup_options);
    } catch (error) {
      // silent error
    } finally {
      commit(types.default.SET_ACCOUNT_UI_FLAG, {
        isFetchingTopupOptions: false,
      });
    }
  },

  fetchCreditGrants: async ({ commit }) => {
    commit(types.default.SET_ACCOUNT_UI_FLAG, { isFetchingCreditGrants: true });
    try {
      const response = await EnterpriseAccountAPI.getCreditGrants();
      commit(types.default.SET_CREDIT_GRANTS, response.data.credit_grants);
    } catch (error) {
      // silent error
    } finally {
      commit(types.default.SET_ACCOUNT_UI_FLAG, {
        isFetchingCreditGrants: false,
      });
    }
  },

  changePricingPlan: async ({ commit }, { pricingPlanId, quantity }) => {
    commit(types.default.SET_ACCOUNT_UI_FLAG, { isChangingPlan: true });
    try {
      const response = await EnterpriseAccountAPI.changePricingPlan(
        pricingPlanId,
        quantity
      );
      commit(types.default.EDIT_ACCOUNT, response.data);
      return response.data;
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    } finally {
      commit(types.default.SET_ACCOUNT_UI_FLAG, { isChangingPlan: false });
    }
  },

  cancelAccountSubscription: async ({ commit }, { reason, feedback }) => {
    commit(types.default.SET_ACCOUNT_UI_FLAG, {
      isCancellingSubscription: true,
    });
    try {
      const response = await EnterpriseAccountAPI.cancelSubscription(
        reason,
        feedback
      );
      commit(types.default.EDIT_ACCOUNT, response.data);
      return response.data;
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    } finally {
      commit(types.default.SET_ACCOUNT_UI_FLAG, {
        isCancellingSubscription: false,
      });
    }
  },

  purchaseCredits: async ({ commit }, { credits }) => {
    commit(types.default.SET_ACCOUNT_UI_FLAG, { isPurchasingCredits: true });
    try {
      const response = await EnterpriseAccountAPI.topupCredits(credits);
      return response.data;
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    } finally {
      commit(types.default.SET_ACCOUNT_UI_FLAG, { isPurchasingCredits: false });
    }
  },

  subscribeToPlan: async ({ commit }, { pricingPlanId, quantity }) => {
    commit(types.default.SET_ACCOUNT_UI_FLAG, { isSubscribing: true });
    try {
      const response = await EnterpriseAccountAPI.subscribeToPlan(
        pricingPlanId,
        quantity
      );
      // Redirect to Stripe checkout
      if (response.data.redirect_url) {
        window.location = response.data.redirect_url;
      }
      return response.data;
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    } finally {
      commit(types.default.SET_ACCOUNT_UI_FLAG, { isSubscribing: false });
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
  [types.default.SET_PRICING_PLANS]($state, data) {
    $state.pricingPlans = data;
  },
  [types.default.SET_TOPUP_OPTIONS]($state, data) {
    $state.topupOptions = data;
  },
  [types.default.SET_CREDIT_GRANTS]($state, data) {
    $state.creditGrants = data;
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
