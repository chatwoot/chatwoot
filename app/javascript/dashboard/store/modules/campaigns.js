import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import CampaignsAPI from '../../api/campaigns';
import AnalyticsHelper from '../../helper/AnalyticsHelper';
import { CAMPAIGNS_EVENTS } from '../../helper/AnalyticsHelper/events';

export const state = {
  records: [],
  campaignContacts: {},
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isFetchingContacts: false,
  },
};

export const getters = {
  getUIFlags(_state) {
    return _state.uiFlags;
  },
  getCampaigns: _state => campaignType => {
    return _state.records
      .filter(record => record.campaign_type === campaignType)
      .sort((a1, a2) => a1.id - a2.id);
  },
  getAllCampaigns: _state => {
    return _state.records;
  },
  getContactsForCampaign: _state => campaignId => {
    return _state.campaignContacts[campaignId] || [];
  },
};

export const actions = {
  get: async function getCampaigns({ commit, dispatch, getters, rootGetters }) {
    commit(types.SET_CAMPAIGN_UI_FLAG, { isFetching: true });
    try {
      const response = await CampaignsAPI.get();

      await Promise.all(
        response.data.map(campaign =>
          dispatch('fetchCampaignContacts', campaign.id)
        )
      );

      const contactsForCampaigns = response.data.map(campaign => ({
        ...campaign,
        contacts: getters.getContactsForCampaign(campaign.id).pending_contacts,
      }));

      commit(types.SET_CAMPAIGNS, contactsForCampaigns);
    } catch (error) {
      // Ignore error
    } finally {
      commit(types.SET_CAMPAIGN_UI_FLAG, { isFetching: false });
    }
  },
  create: async function createCampaign(
    { commit, dispatch, rootGetters },
    campaignObj
  ) {
    commit(types.SET_CAMPAIGN_UI_FLAG, { isCreating: true });
    try {
      const response = await CampaignsAPI.create(campaignObj);

      const campaign = campaignObj.campaign;

      const result = await Promise.all(
        campaign.contacts.map(async function (id) {
          await dispatch('contacts/show', { id }, { root: true });
          const contact = rootGetters['contacts/getContact'](id);
          return contact;
        })
      );

      console.log('Got contacts');
      console.log(result);

      const contactsForCampaigns = {
        ...response.data,
        contacts: result,
      };

      commit(types.ADD_CAMPAIGN, contactsForCampaigns);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_CAMPAIGN_UI_FLAG, { isCreating: false });
    }
  },
  update: async ({ commit }, { id, ...updateObj }) => {
    commit(types.SET_CAMPAIGN_UI_FLAG, { isUpdating: true });
    try {
      const response = await CampaignsAPI.update(id, updateObj);
      AnalyticsHelper.track(CAMPAIGNS_EVENTS.UPDATE_CAMPAIGN);
      commit(types.EDIT_CAMPAIGN, response.data);
      return response.data;
    } finally {
      commit(types.SET_CAMPAIGN_UI_FLAG, { isUpdating: false });
    }
  },
  delete: async ({ commit }, id) => {
    commit(types.SET_CAMPAIGN_UI_FLAG, { isDeleting: true });
    try {
      await CampaignsAPI.delete(id);
      AnalyticsHelper.track(CAMPAIGNS_EVENTS.DELETE_CAMPAIGN);
      commit(types.DELETE_CAMPAIGN, id);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_CAMPAIGN_UI_FLAG, { isDeleting: false });
    }
  },
  fetchCampaignContacts: async ({ commit }, campaignId) => {
    commit(types.SET_CAMPAIGN_UI_FLAG, { isFetchingContacts: true });
    try {
      const response = await CampaignsAPI.fetchCampaignContacts(campaignId);

      console.log('Campaign Contacts');
      console.log(response.data);

      commit(types.SET_CAMPAIGN_CONTACTS, {
        campaignId,
        contacts: response.data,
      });
      return response.data;
    } catch (error) {
      console.error('Failed to fetch campaign contacts', error);
      throw error;
    } finally {
      commit(types.SET_CAMPAIGN_UI_FLAG, { isFetchingContacts: false });
    }
  },
};

export const mutations = {
  [types.SET_CAMPAIGN_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },
  [types.ADD_CAMPAIGN]: MutationHelpers.create,
  [types.SET_CAMPAIGNS]: MutationHelpers.set,
  [types.EDIT_CAMPAIGN]: MutationHelpers.update,
  [types.DELETE_CAMPAIGN]: MutationHelpers.destroy,
  [types.SET_CAMPAIGN_CONTACTS](state, { campaignId, contacts }) {
    state.campaignContacts = {
      ...state.campaignContacts,
      [campaignId]: contacts,
    };
  },
};

export default {
  namespaced: true,
  actions,
  state,
  getters,
  mutations,
};
