import types from '../../mutation-types';
import LibraryResourcesAPI from '../../../api/libraryResources';

export const actions = {
  get: async function getLibraryResources({ commit }) {
    commit(types.SET_LIBRARY_RESOURCE_UI_FLAG, { isFetching: true });
    try {
      const response = await LibraryResourcesAPI.get();
      commit(types.SET_LIBRARY_RESOURCES, response.data.payload);
      commit(types.SET_LIBRARY_RESOURCES_META, response.data.meta);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_LIBRARY_RESOURCE_UI_FLAG, { isFetching: false });
    }
  },

  show: async function showLibraryResource({ commit }, { id }) {
    commit(types.SET_LIBRARY_RESOURCE_UI_FLAG, { isFetchingItem: true });
    try {
      const response = await LibraryResourcesAPI.show(id);
      commit(types.SET_LIBRARY_RESOURCE_ITEM, response.data.payload);
      return response.data.payload;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_LIBRARY_RESOURCE_UI_FLAG, { isFetchingItem: false });
    }
  },

  create: async function createLibraryResource({ commit }, resourceData) {
    commit(types.SET_LIBRARY_RESOURCE_UI_FLAG, { isCreating: true });
    try {
      const response = await LibraryResourcesAPI.create(resourceData);
      commit(types.SET_LIBRARY_RESOURCE_ITEM, response.data.payload);
      return response.data.payload;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_LIBRARY_RESOURCE_UI_FLAG, { isCreating: false });
    }
  },

  update: async function updateLibraryResource(
    { commit },
    { id, resourceData }
  ) {
    commit(types.SET_LIBRARY_RESOURCE_UI_FLAG, { isUpdating: true });
    try {
      const response = await LibraryResourcesAPI.update(id, resourceData);
      commit(types.EDIT_LIBRARY_RESOURCE, response.data.payload);
      return response.data.payload;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_LIBRARY_RESOURCE_UI_FLAG, { isUpdating: false });
    }
  },

  delete: async function deleteLibraryResource({ commit }, id) {
    commit(types.SET_LIBRARY_RESOURCE_UI_FLAG, { isDeleting: true });
    try {
      await LibraryResourcesAPI.delete(id);
      commit(types.DELETE_LIBRARY_RESOURCE, id);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_LIBRARY_RESOURCE_UI_FLAG, { isDeleting: false });
    }
  },
};
