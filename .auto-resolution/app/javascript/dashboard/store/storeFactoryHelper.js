import { throwErrorMessage } from 'dashboard/store/utils/api';

// ============================================================================
// VUEX HELPERS
// ============================================================================

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
      commit(mutationTypes.UPSERT, response.data);
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

// ============================================================================
// PINIA HELPERS
// ============================================================================

/**
 * Get records from API and update Pinia store
 * @param {Object} store - Pinia store instance (this context)
 * @param {Object} API - API client
 * @param {Object} params - Query parameters
 */
export const piniaGetRecords = async (store, API, params = {}) => {
  store.setUIFlag({ fetchingList: true });
  try {
    const response = await API.get(params);
    const { data } = response;
    store.records = data.payload || data;
    if (data.meta) {
      store.setMeta(data.meta);
    }
    return data.payload || data;
  } catch (error) {
    return throwErrorMessage(error);
  } finally {
    store.setUIFlag({ fetchingList: false });
  }
};

/**
 * Show single record from API and upsert to Pinia store
 * @param {Object} store - Pinia store instance (this context)
 * @param {Object} API - API client
 * @param {Number|String} id - Record ID
 */
export const piniaShowRecord = async (store, API, id) => {
  store.setUIFlag({ fetchingItem: true });
  try {
    const response = await API.show(id);
    const { data } = response;
    const record = data.payload || data;

    // Upsert logic
    const index = store.records.findIndex(r => r.id === record.id);
    if (index !== -1) {
      store.records[index] = record;
    } else {
      store.records.push(record);
    }

    return record;
  } catch (error) {
    return throwErrorMessage(error);
  } finally {
    store.setUIFlag({ fetchingItem: false });
  }
};

/**
 * Create new record via API and add to Pinia store
 * @param {Object} store - Pinia store instance (this context)
 * @param {Object} API - API client
 * @param {Object} dataObj - Data to create
 */
export const piniaCreateRecord = async (store, API, dataObj) => {
  store.setUIFlag({ creatingItem: true });
  try {
    const response = await API.create(dataObj);
    const { data } = response;
    const record = data.payload || data;
    store.records.push(record);
    return record;
  } catch (error) {
    return throwErrorMessage(error);
  } finally {
    store.setUIFlag({ creatingItem: false });
  }
};

/**
 * Update existing record via API and update in Pinia store
 * @param {Object} store - Pinia store instance (this context)
 * @param {Object} API - API client
 * @param {Object} payload - Update payload with id
 */
export const piniaUpdateRecord = async (store, API, { id, ...updateObj }) => {
  store.setUIFlag({ updatingItem: true });
  try {
    const response = await API.update(id, updateObj);
    const { data } = response;
    const record = data.payload || data;

    const index = store.records.findIndex(r => r.id === record.id);
    if (index !== -1) {
      store.records[index] = record;
    }

    return record;
  } catch (error) {
    return throwErrorMessage(error);
  } finally {
    store.setUIFlag({ updatingItem: false });
  }
};

/**
 * Delete record via API and remove from Pinia store
 * @param {Object} store - Pinia store instance (this context)
 * @param {Object} API - API client
 * @param {Number|String} id - Record ID to delete
 */
export const piniaDeleteRecord = async (store, API, id) => {
  store.setUIFlag({ deletingItem: true });
  try {
    await API.delete(id);
    store.records = store.records.filter(record => record.id !== id);
    return id;
  } catch (error) {
    return throwErrorMessage(error);
  } finally {
    store.setUIFlag({ deletingItem: false });
  }
};
