import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import * as types from '../mutation-types';
import AccountAPI from '../../api/account';
import { differenceInDays } from 'date-fns';
import EnterpriseAccountAPI from '../../api/enterprise/account';
import BillingAPI from '../../api/v2/billing';
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
};

export const getters = {
  getAccount: $state => id => {
    return findRecordById($state, id);
  },
  getUIFlags($state) {
    return $state.uiFlags;
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
  isOnboardingCompleted: $state => id => {
    const account = findRecordById($state, id);
    return account.custom_attributes.onboarding_completed || false;
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
      const response = await BillingAPI.getBillingPortal();
      if (response.data.success && response.data.data.session_url) {
        window.location = response.data.data.session_url;
      } else {
        throw new Error(
          response.data.error || 'Failed to create billing portal session'
        );
      }
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.default.SET_ACCOUNT_UI_FLAG, { isCheckoutInProcess: false });
    }
  },

  subscription: async ({ commit, getters: storeGetters }) => {
    commit(types.default.SET_ACCOUNT_UI_FLAG, { isCheckoutInProcess: true });
    try {
      const response = await BillingAPI.getSubscription();
      if (response.data.success) {
        // Update account attributes while preserving existing data including features
        const accountId = response.data.data.account_id;
        const existingAccount = storeGetters.getAccount(accountId);
        const updatedAccount = {
          ...existingAccount,
          custom_attributes: {
            ...existingAccount.custom_attributes,
            plan_name: response.data.data.plan_name,
            subscription_status: response.data.data.subscription_status,
            subscription_ends_on: response.data.data.subscription_ends_on,
            stripe_customer_id: response.data.data.customer_id,
            plan_limits: response.data.data.plan_limits,
            cancel_at_period_end: response.data.data.cancel_at_period_end,
            canceled_at: response.data.data.canceled_at,
            ended_at: response.data.data.ended_at,
          },
        };
        commit(types.default.EDIT_ACCOUNT, updatedAccount);
      }
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.default.SET_ACCOUNT_UI_FLAG, { isCheckoutInProcess: false });
    }
  },

  createSubscription: async (
    { commit, getters: storeGetters },
    { planName = 'free_trial' } = {}
  ) => {
    commit(types.default.SET_ACCOUNT_UI_FLAG, { isCheckoutInProcess: true });
    try {
      const response = await BillingAPI.createSubscription(planName);

      if (response.data.success) {
        // If the backend sends a checkout URL, redirect the user immediately
        if (response.data.data.checkout_url) {
          window.location = response.data.data.checkout_url;
          return; // Stop execution to allow for redirect
        }

        // Otherwise, update the account data with the new subscription information while preserving existing data
        const accountId = response.data.data.account_id;
        const existingAccount = storeGetters.getAccount(accountId);
        const updatedAccount = {
          ...existingAccount,
          custom_attributes: {
            ...existingAccount.custom_attributes,
            plan_name: response.data.data.plan_name,
            subscription_status: response.data.data.subscription_status,
            stripe_customer_id: response.data.data.customer_id,
          },
        };
        commit(types.default.EDIT_ACCOUNT, updatedAccount);
        return;
      }
      throw new Error(response.data.error || 'Failed to create subscription');
    } catch (error) {
      throwErrorMessage(error);
      throw error; // Re-throw to be caught by the component
    } finally {
      commit(types.default.SET_ACCOUNT_UI_FLAG, { isCheckoutInProcess: false });
    }
  },

  limits: async ({ commit }) => {
    try {
      const response = await BillingAPI.getLimits();
      if (response.data.success) {
        commit(types.default.SET_ACCOUNT_LIMITS, response.data.data);
      }
    } catch (error) {
      // silent error
    }
  },

  getCacheKeys: async () => {
    return AccountAPI.getCacheKeys();
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
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
