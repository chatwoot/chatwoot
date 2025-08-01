import CaptainAssistantAPI from 'dashboard/api/captain/assistant';
import { createStore } from './storeFactory';
import { throwErrorMessage } from 'dashboard/store/utils/api';

export default createStore({
  name: 'CaptainAssistant',
  API: CaptainAssistantAPI,
  actions: mutations => ({
    get: async function get({ commit }, params = {}) {
      commit(mutations.SET_UI_FLAG, { fetchingList: true });
      try {
        const response = await CaptainAssistantAPI.get(params);
        const result = response.data;
        const dataArray = Array.isArray(result) ? result : (result.data || []);
        commit(mutations.SET, dataArray);
        commit(mutations.SET_META, {
          totalCount: result.total_count || dataArray.length,
          page: params.page || 1,
        });
        commit(mutations.SET_UI_FLAG, { fetchingList: false });
        return dataArray;
      } catch (error) {
        commit(mutations.SET_UI_FLAG, { fetchingList: false });
        return throwErrorMessage(error);
      }
    },

    create: async function create({ commit }, data) {
      commit(mutations.SET_UI_FLAG, { creatingItem: true });
      try {
        const response = await CaptainAssistantAPI.create(data);
        const result = response.data;
        const payload = result.data || result;
        commit(mutations.ADD, payload);
        commit(mutations.SET_UI_FLAG, { creatingItem: false });
        return payload;
      } catch (error) {
        commit(mutations.SET_UI_FLAG, { creatingItem: false });
        return throwErrorMessage(error);
      }
    },

    update: async function update({ commit, dispatch }, { id, ...data }) {
      commit(mutations.SET_UI_FLAG, { updatingItem: true });
      try {
        const response = await CaptainAssistantAPI.update({ id, ...data });
        const result = response.data;
        const payload = result.data || result;
        commit(mutations.EDIT, payload);
        commit(mutations.SET_UI_FLAG, { updatingItem: false });
        await dispatch('get');
        return payload;
      } catch (error) {
        commit(mutations.SET_UI_FLAG, { updatingItem: false });
        return throwErrorMessage(error);
      }
    },

    delete: async function remove({ commit }, id) {
      commit(mutations.SET_UI_FLAG, { deletingItem: true });
      try {
        await CaptainAssistantAPI.delete(id);
        commit(mutations.DELETE, id);
        commit(mutations.SET_UI_FLAG, { deletingItem: false });
        return id;
      } catch (error) {
        commit(mutations.SET_UI_FLAG, { deletingItem: false });
        return throwErrorMessage(error);
      }
    },
  }),
});
