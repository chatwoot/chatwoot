import { throwErrorMessage } from 'dashboard/store/utils/api';

export const getRecords =
  (mutationTypes, API) =>
  async ({ commit }, params = {}) => {
    commit(mutationTypes.SET_UI_FLAG, { fetchingList: true });
    try {
      const response = await API.get(params);
      commit(mutationTypes.SET, response.data.payload);
      commit(mutationTypes.SET_META, response.data.meta);
      return response.data.payload;
    } catch (error) {
      return throwErrorMessage(error);
    } finally {
      commit(mutationTypes.SET_UI_FLAG, { fetchingList: false });
    }
  };

export const showRecord =
  (mutationTypes, API) =>
  async ({ commit }, id) => {
    commit(mutationTypes.SET_UI_FLAG, { fetchingItem: true });
    try {
      const response = await API.show(id);
      commit(mutationTypes.ADD, response.data);
      return response.data;
    } catch (error) {
      return throwErrorMessage(error);
    } finally {
      commit(mutationTypes.SET_UI_FLAG, { fetchingItem: false });
    }
  };

export const createRecord =
  (mutationTypes, API) =>
  async ({ commit }, dataObj) => {
    commit(mutationTypes.SET_UI_FLAG, { creatingItem: true });
    try {
      const response = await API.create(dataObj);
      commit(mutationTypes.UPSERT, response.data);
      return response.data;
    } catch (error) {
      return throwErrorMessage(error);
    } finally {
      commit(mutationTypes.SET_UI_FLAG, { creatingItem: false });
    }
  };

export const updateRecord =
  (mutationTypes, API) =>
  async ({ commit }, { id, ...updateObj }) => {
    commit(mutationTypes.SET_UI_FLAG, { updatingItem: true });
    try {
      const response = await API.update(id, updateObj);
      commit(mutationTypes.EDIT, response.data);
      return response.data;
    } catch (error) {
      return throwErrorMessage(error);
    } finally {
      commit(mutationTypes.SET_UI_FLAG, { updatingItem: false });
    }
  };

export const deleteRecord =
  (mutationTypes, API) =>
  async ({ commit }, id) => {
    commit(mutationTypes.SET_UI_FLAG, { deletingItem: true });
    try {
      await API.delete(id);
      commit(mutationTypes.DELETE, id);
      return id;
    } catch (error) {
      return throwErrorMessage(error);
    } finally {
      commit(mutationTypes.SET_UI_FLAG, { deletingItem: false });
    }
  };
