import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import CustomViewsAPI from '../../api/customViews';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';

const VIEW_TYPES = {
  CONVERSATION: 'conversation',
  CONTACT: 'contact',
};
const FILTERED_UNREAD_COUNTS_REFRESH_RETRY_MS = 30000;
const FILTERED_UNREAD_COUNTS_REFRESH_RETRY_JITTER_MS = 15000;
const getFilteredUnreadCountsRefreshRetryDelay = () =>
  FILTERED_UNREAD_COUNTS_REFRESH_RETRY_MS +
  Math.random() * FILTERED_UNREAD_COUNTS_REFRESH_RETRY_JITTER_MS;

// use to normalize the filter type
const FILTER_KEYS = {
  0: VIEW_TYPES.CONVERSATION,
  1: VIEW_TYPES.CONTACT,
  [VIEW_TYPES.CONVERSATION]: VIEW_TYPES.CONVERSATION,
  [VIEW_TYPES.CONTACT]: VIEW_TYPES.CONTACT,
};

// a folder's contact_id filter stores only the id, extract it so the
// contact can be fetched and its name shown in the edit folder modal
const getFolderContactId = folder =>
  folder?.query?.payload?.find(filter => filter.attribute_key === 'contact_id')
    ?.values?.[0];

const hasFeatureEnabled = (rootGetters, featureFlag) => {
  const accountId = rootGetters?.getCurrentAccountId;
  const isFeatureEnabled = rootGetters?.['accounts/isFeatureEnabledonAccount'];

  return Boolean(accountId && isFeatureEnabled?.(accountId, featureFlag));
};

const shouldRefreshConversationUnreadCounts = (filterType, rootGetters) => {
  return (
    FILTER_KEYS[filterType] === VIEW_TYPES.CONVERSATION &&
    hasFeatureEnabled(rootGetters, FEATURE_FLAGS.CONVERSATION_UNREAD_COUNTS) &&
    hasFeatureEnabled(rootGetters, FEATURE_FLAGS.UNREAD_COUNT_FOR_FILTERS)
  );
};

const dispatchConversationUnreadCounts = dispatch => {
  dispatch('conversationUnreadCounts/get', {}, { root: true });
};

const refreshConversationUnreadCounts = (
  { dispatch, rootGetters },
  filterType
) => {
  if (!shouldRefreshConversationUnreadCounts(filterType, rootGetters)) return;

  dispatchConversationUnreadCounts(dispatch);
  setTimeout(
    () => dispatchConversationUnreadCounts(dispatch),
    getFilteredUnreadCountsRefreshRetryDelay()
  );
};

export const state = {
  [VIEW_TYPES.CONVERSATION]: {
    records: [],
  },
  [VIEW_TYPES.CONTACT]: {
    records: [],
  },
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isDeleting: false,
  },
  activeConversationFolder: null,
};

export const getters = {
  getUIFlags(_state) {
    return _state.uiFlags;
  },
  getCustomViewsByFilterType: _state => key => {
    const filterType = FILTER_KEYS[key];
    return _state[filterType].records;
  },
  getConversationCustomViews(_state) {
    return _state[VIEW_TYPES.CONVERSATION].records;
  },
  getContactCustomViews(_state) {
    return _state[VIEW_TYPES.CONTACT].records;
  },
  getActiveConversationFolder(_state) {
    return _state.activeConversationFolder;
  },
  getActiveFolderContactId(_state) {
    return getFolderContactId(_state.activeConversationFolder);
  },
};

export const actions = {
  get: async function getCustomViews({ commit }, filterType) {
    commit(types.SET_CUSTOM_VIEW_UI_FLAG, { isFetching: true });
    try {
      const response =
        await CustomViewsAPI.getCustomViewsByFilterType(filterType);
      commit(types.SET_CUSTOM_VIEW, { data: response.data, filterType });
    } catch (error) {
      // Ignore error
    } finally {
      commit(types.SET_CUSTOM_VIEW_UI_FLAG, { isFetching: false });
    }
  },
  create: async function createCustomViews(
    { commit, dispatch, rootGetters },
    obj
  ) {
    commit(types.SET_CUSTOM_VIEW_UI_FLAG, { isCreating: true });
    try {
      const response = await CustomViewsAPI.create(obj);
      const filterType = FILTER_KEYS[obj.filter_type];
      commit(types.ADD_CUSTOM_VIEW, {
        data: response.data,
        filterType,
      });
      refreshConversationUnreadCounts({ dispatch, rootGetters }, filterType);
      return response;
    } catch (error) {
      const errorMessage = error?.response?.data?.message;
      throw new Error(errorMessage);
    } finally {
      commit(types.SET_CUSTOM_VIEW_UI_FLAG, { isCreating: false });
    }
  },
  update: async function updateCustomViews(
    { commit, dispatch, rootGetters },
    obj
  ) {
    commit(types.SET_CUSTOM_VIEW_UI_FLAG, { isCreating: true });
    try {
      const response = await CustomViewsAPI.update(obj.id, obj);
      const filterType = FILTER_KEYS[obj.filter_type];
      commit(types.UPDATE_CUSTOM_VIEW, {
        data: response.data,
        filterType,
      });
      refreshConversationUnreadCounts({ dispatch, rootGetters }, filterType);
    } catch (error) {
      const errorMessage = error?.response?.data?.message;
      throw new Error(errorMessage);
    } finally {
      commit(types.SET_CUSTOM_VIEW_UI_FLAG, { isCreating: false });
    }
  },
  delete: async ({ commit, dispatch, rootGetters }, { id, filterType }) => {
    commit(types.SET_CUSTOM_VIEW_UI_FLAG, { isDeleting: true });
    try {
      await CustomViewsAPI.deleteCustomViews(id, filterType);
      commit(types.DELETE_CUSTOM_VIEW, { data: id, filterType });
      refreshConversationUnreadCounts({ dispatch, rootGetters }, filterType);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_CUSTOM_VIEW_UI_FLAG, { isDeleting: false });
    }
  },
  setActiveConversationFolder({ commit, dispatch }, data) {
    commit(types.SET_ACTIVE_CONVERSATION_FOLDER, data);
    // prefetch the contact of a contact filter so the UI can show its name
    const contactId = getFolderContactId(data);
    if (contactId) dispatch('contacts/show', { id: contactId }, { root: true });
  },
};

export const mutations = {
  [types.SET_CUSTOM_VIEW_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },

  [types.ADD_CUSTOM_VIEW]: (_state, { data, filterType }) => {
    MutationHelpers.create(_state[filterType], data);
  },
  [types.SET_CUSTOM_VIEW]: (_state, { data, filterType }) => {
    MutationHelpers.set(_state[filterType], data);
  },
  [types.UPDATE_CUSTOM_VIEW]: (_state, { data, filterType }) => {
    MutationHelpers.update(_state[filterType], data);
  },
  [types.DELETE_CUSTOM_VIEW]: (_state, { data, filterType }) => {
    MutationHelpers.destroy(_state[filterType], data);
  },

  [types.SET_ACTIVE_CONVERSATION_FOLDER](_state, folder) {
    _state.activeConversationFolder = folder;
  },
};

export default {
  namespaced: true,
  actions,
  state,
  getters,
  mutations,
};
