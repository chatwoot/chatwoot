import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import KbResourcesAPI from '../../api/kbResources';

export const state = {
  records: [],
  folders: [],
  currentFolder: '/',
  meta: {
    current_page: 1,
    total_pages: 1,
    total_count: 0,
    per_page: 50,
    current_folder: '/',
    storage_used: 0,
    storage_limit: 2 * 1024 * 1024 * 1024, // 2GB default
  },
  tree: {
    folders: [],
    resources: [],
  },
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isUpdating: false,
    isDeleting: false,
    isMoving: false,
    isFetchingTree: false,
  },
};

export const getters = {
  getUIFlags: _state => _state.uiFlags,
  getKbResources: _state => _state.records,
  getKbResource: _state => id => _state.records.find(r => r.id === id),
  getFolders: _state => _state.folders,
  getCurrentFolder: _state => _state.currentFolder,
  getMeta: _state => _state.meta,
  getStorageUsed: _state => _state.meta.storage_used,
  getStorageLimit: _state => _state.meta.storage_limit,
  getStorageRemaining: _state =>
    _state.meta.storage_limit - _state.meta.storage_used,
  getTree: _state => _state.tree,
};

export const actions = {
  get: async ({ commit }, params = {}) => {
    commit(types.SET_KB_RESOURCE_UI_FLAG, { isFetching: true });
    try {
      const response = await KbResourcesAPI.get(params);
      commit(types.SET_KB_RESOURCES, response.data.data);
      commit(types.SET_KB_RESOURCE_FOLDERS, response.data.folders || []);
      commit(types.SET_KB_RESOURCE_META, response.data.meta);
      commit(types.SET_KB_RESOURCE_CURRENT_FOLDER, params.folder_path || '/');
    } finally {
      commit(types.SET_KB_RESOURCE_UI_FLAG, { isFetching: false });
    }
  },

  create: async ({ commit }, formData) => {
    commit(types.SET_KB_RESOURCE_UI_FLAG, { isCreating: true });
    try {
      const response = await KbResourcesAPI.create(formData);
      commit(types.ADD_KB_RESOURCE, response.data);
      return response.data;
    } finally {
      commit(types.SET_KB_RESOURCE_UI_FLAG, { isCreating: false });
    }
  },

  update: async ({ commit }, { id, ...data }) => {
    commit(types.SET_KB_RESOURCE_UI_FLAG, { isUpdating: true });
    try {
      const response = await KbResourcesAPI.update(id, data);
      commit(types.EDIT_KB_RESOURCE, response.data);
      return response.data;
    } finally {
      commit(types.SET_KB_RESOURCE_UI_FLAG, { isUpdating: false });
    }
  },

  delete: async ({ commit }, id) => {
    commit(types.SET_KB_RESOURCE_UI_FLAG, { isDeleting: true });
    try {
      await KbResourcesAPI.delete(id);
      commit(types.DELETE_KB_RESOURCE, id);
    } finally {
      commit(types.SET_KB_RESOURCE_UI_FLAG, { isDeleting: false });
    }
  },

  toggleVisibility: async ({ commit }, id) => {
    commit(types.SET_KB_RESOURCE_UI_FLAG, { isUpdating: true });
    try {
      const response = await KbResourcesAPI.toggleVisibility(id);
      commit(types.EDIT_KB_RESOURCE, response.data);
    } finally {
      commit(types.SET_KB_RESOURCE_UI_FLAG, { isUpdating: false });
    }
  },

  fetchStorageInfo: async ({ commit }) => {
    try {
      const response = await KbResourcesAPI.getStorageInfo();
      commit(types.SET_KB_RESOURCE_META, {
        storage_used: response.data.storage_used,
        storage_limit: response.data.storage_limit,
      });
    } catch (error) {
      // silently fail
    }
  },

  move: async ({ commit }, { id, folderPath }) => {
    commit(types.SET_KB_RESOURCE_UI_FLAG, { isMoving: true });
    try {
      const response = await KbResourcesAPI.move(id, folderPath);
      commit(types.DELETE_KB_RESOURCE, id); // Remove from current view
      return response.data;
    } finally {
      commit(types.SET_KB_RESOURCE_UI_FLAG, { isMoving: false });
    }
  },

  bulkMove: async ({ commit }, { resourceIds, folderPath }) => {
    commit(types.SET_KB_RESOURCE_UI_FLAG, { isMoving: true });
    try {
      await KbResourcesAPI.bulkMove(resourceIds, folderPath);
      resourceIds.forEach(id => commit(types.DELETE_KB_RESOURCE, id));
    } finally {
      commit(types.SET_KB_RESOURCE_UI_FLAG, { isMoving: false });
    }
  },

  createFolder: async ({ commit }, { name, parentPath }) => {
    commit(types.SET_KB_RESOURCE_UI_FLAG, { isCreating: true });
    try {
      const response = await KbResourcesAPI.createFolder(name, parentPath);
      // Add the new folder to the list
      commit(types.ADD_KB_RESOURCE_FOLDER, response.data);
      // Update storage used
      if (response.data.storage_used !== undefined) {
        commit(types.SET_KB_RESOURCE_META, { storage_used: response.data.storage_used });
      }
      return response.data;
    } finally {
      commit(types.SET_KB_RESOURCE_UI_FLAG, { isCreating: false });
    }
  },

  deleteFolder: async ({ commit }, payload) => {
    // Support both string (path only) and object { path, force }
    const folderPath = typeof payload === 'string' ? payload : payload.path;
    const force = typeof payload === 'object' ? payload.force : false;

    commit(types.SET_KB_RESOURCE_UI_FLAG, { isDeleting: true });
    try {
      const response = await KbResourcesAPI.deleteFolder(folderPath, force);
      commit(types.DELETE_KB_RESOURCE_FOLDER, folderPath);
      // Update storage used
      if (response.data.storage_used !== undefined) {
        commit(types.SET_KB_RESOURCE_META, { storage_used: response.data.storage_used });
      }
    } finally {
      commit(types.SET_KB_RESOURCE_UI_FLAG, { isDeleting: false });
    }
  },

  fetchTree: async ({ commit }) => {
    commit(types.SET_KB_RESOURCE_UI_FLAG, { isFetchingTree: true });
    try {
      const response = await KbResourcesAPI.getTree();
      commit(types.SET_KB_RESOURCE_TREE, {
        folders: response.data.folders,
        resources: response.data.resources,
      });
      commit(types.SET_KB_RESOURCE_META, {
        storage_used: response.data.storage_used,
        storage_limit: response.data.storage_limit,
      });
    } finally {
      commit(types.SET_KB_RESOURCE_UI_FLAG, { isFetchingTree: false });
    }
  },
};

export const mutations = {
  [types.SET_KB_RESOURCE_UI_FLAG](_state, data) {
    _state.uiFlags = { ..._state.uiFlags, ...data };
  },
  [types.SET_KB_RESOURCE_META](_state, meta) {
    _state.meta = { ..._state.meta, ...meta };
  },
  [types.SET_KB_RESOURCE_FOLDERS](_state, folders) {
    _state.folders = folders;
  },
  [types.SET_KB_RESOURCE_CURRENT_FOLDER](_state, folder) {
    _state.currentFolder = folder;
  },
  [types.SET_KB_RESOURCES]: MutationHelpers.set,
  [types.ADD_KB_RESOURCE]: MutationHelpers.create,
  [types.EDIT_KB_RESOURCE]: MutationHelpers.update,
  [types.DELETE_KB_RESOURCE]: MutationHelpers.destroy,
  [types.ADD_KB_RESOURCE_FOLDER](_state, folder) {
    // Add folder object { name, path } to the folders array
    _state.folders = [..._state.folders, folder];
  },
  [types.DELETE_KB_RESOURCE_FOLDER](_state, folderPath) {
    // Remove folder by path
    _state.folders = _state.folders.filter(f => f.path !== folderPath);
  },
  [types.SET_KB_RESOURCE_TREE](_state, { folders, resources }) {
    _state.tree = { folders, resources };
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
