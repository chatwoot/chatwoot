import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import * as types from '../mutation-types';
import shopifyAPI from '../../api/shopify';

const state = {
    records: [],
    uiFlags: {
        fetchingList: false,
        creatingItem: false,
        removingItem: false,
        updateItem: false,
    },
    errorMessage: ""
};

export const getters = {
    getShopifyAccounts(_state) {
        return _state.records;
    },
    getUIFlags(_state) {
        return _state.uiFlags;
    },
};

export const actions = {
    async get({commit}) {
        commit(types.default.SET_SHOPIFY_UI_FLAG, {fetchingList: true});
        try {
            const response = await shopifyAPI.get();
            commit(types.default.SET_SHOPIFY, response.data);
            commit(types.default.SET_SHOPIFY_UI_FLAG, {fetchingList: false});
        } catch (error) {
            commit(types.default.SET_SHOPIFY_UI_FLAG, {fetchingList: false});
            throw error;
        }
    },
    async create({commit}, params) {
        commit(types.default.SET_WEBHOOK_UI_FLAG, {creatingItem: true});
        try {
            const response = await shopifyAPI.create(params);
            commit(types.default.ADD_SHOPIFY, response.data);
            commit(types.default.SET_SHOPIFY_UI_FLAG, {creatingItem: false});
        } catch (error) {
            commit(types.default.SET_SHOPIFY_UI_FLAG, {creatingItem: false});
            throw error;
        }
    },
    update: async ({commit}, {id, ...updateObj}) => {
        commit(types.default.SET_SHOPIFY_UI_FLAG, {updateItem: true});
        try {
            const response = await shopifyAPI.update(id, updateObj);
            commit(types.default.UPDATE_SHOPIFY, response.data);
        } catch (error) {
            throw new Error(error);
        } finally {
            commit(types.default.SET_SHOPIFY_UI_FLAG, {updateItem: false});
        }
    },
    async remove({commit}, id) {
        commit(types.default.SET_SHOPIFY_UI_FLAG, {removingItem: true});
        try {
            await shopifyAPI.delete(id);
            commit(types.default.REMOVE_SHOPIFY, {removingItem: true});
        } catch (error) {
            commit(types.default.REMOVE_SHOPIFY, {removingItem: true});
            throw error;
        }
    },
    async refund({commit}, data){
        try{
            var response = await shopifyAPI.refund(data);
            console.log("Response");
            console.log(response);
        }catch(error){
            throw error;
        }
    },
    async setShopifyErrorMessage({commit}, data){
      commit(types.default.SET_SHOPIFY_ERROR_MESSAGE, data);  
    }
};

export const mutations = {
    [types.default.SET_SHOPIFY_UI_FLAG](_state, data) {
        _state.uiFlags = {
            ..._state.uiFlags,
            ...data,
        };
    },
    [types.default.SET_SHOPIFY]: MutationHelpers.set,
    [types.default.ADD_SHOPIFY]: MutationHelpers.create,
    [types.default.REMOVE_SHOPIFY]: MutationHelpers.destroy,
    [types.default.UPDATE_SHOPIFY]: MutationHelpers.update,
    [types.default.SET_SHOPIFY_ERROR_MESSAGE](_state, data) {
        _state.errorMessage = data;
    }
};

export default {
    namespaced: true,
    state,
    getters,
    actions,
    mutations,
};
