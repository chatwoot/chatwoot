import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import MacrosAPI from '../../api/macros';
import ChatwootExtraAPI from '../../api/chatwootExtra';
import { throwErrorMessage } from '../utils/api';

export const state = {
  records: [],
  sourceMappings: {}, // Cache: { macroId: [channelId1, channelId2, ...] }
  extraUUIDs: {}, // Cache: { macroId: 'uuid-from-chatwoot-extra' }
  uiFlags: {
    isFetchingItem: false,
    isFetching: false,
    isCreating: false,
    isDeleting: false,
    isUpdating: false,
    isExecuting: false,
    isFetchingSources: false,
  },
};

export const getters = {
  getMacros($state) {
    return $state.records;
  },
  getMacro: $state => id => {
    return $state.records.find(record => record.id === Number(id));
  },
  getMacroSourceChannels: $state => macroId => {
    return $state.sourceMappings[macroId] || [];
  },
  getMacroExtraUUID: $state => macroId => {
    return $state.extraUUIDs[macroId] || null;
  },
  getMacrosByChannel: $state => channelId => {
    // Return macro IDs that are available for this channel
    const macroIds = [];

    // If sourceMappings is empty, we haven't loaded yet - return all macros
    if (Object.keys($state.sourceMappings).length === 0) {
      return $state.records.map(m => m.id);
    }

    // Check each macro in the records
    $state.records.forEach(macro => {
      const sources = $state.sourceMappings[macro.id];

      // If macro is not in sourceMappings, it's available everywhere (old macro or not synced)
      if (sources === undefined) {
        macroIds.push(macro.id);
      }
      // If no sources (empty array), macro is available everywhere
      else if (sources.length === 0 || sources.includes(Number(channelId))) {
        macroIds.push(macro.id);
      }
    });

    return macroIds;
  },
  getUIFlags($state) {
    return $state.uiFlags;
  },
};

export const actions = {
  get: async function getMacros({ commit, dispatch }) {
    commit(types.SET_MACROS_UI_FLAG, { isFetching: true });
    try {
      const response = await MacrosAPI.get();
      commit(types.SET_MACROS, response.data.payload);
      // Also fetch source mappings from chatwoot-extra
      await dispatch('fetchMacroSources');
    } catch (error) {
      // Ignore error
    } finally {
      commit(types.SET_MACROS_UI_FLAG, { isFetching: false });
    }
  },
  fetchMacroSources: async function fetchMacroSources({ commit }) {
    commit(types.SET_MACROS_UI_FLAG, { isFetchingSources: true });
    try {
      // Get ALL macros (including public macros created by other users)
      const macros = await ChatwootExtraAPI.getAllMacros();

      if (macros && Array.isArray(macros)) {
        // Build mappings: { macroId: [channelId1, channelId2, ...] }
        const mappings = {};
        const uuids = {};
        macros.forEach(macro => {
          mappings[macro.chatwootMacrosId] = macro.sources.map(
            s => s.chatwootChannelId
          );
          uuids[macro.chatwootMacrosId] = macro.id; // Store the UUID
        });
        commit(types.SET_MACRO_SOURCE_MAPPINGS, mappings);
        commit(types.SET_MACRO_EXTRA_UUIDS, uuids);
      }
    } catch (error) {
      // Ignore error
    } finally {
      commit(types.SET_MACROS_UI_FLAG, { isFetchingSources: false });
    }
  },
  getSingleMacro: async function getMacroById({ commit }, macroId) {
    commit(types.SET_MACROS_UI_FLAG, { isFetchingItem: true });
    try {
      const response = await MacrosAPI.show(macroId);
      commit(types.ADD_MACRO, response.data.payload);
    } catch (error) {
      // Ignore error
    } finally {
      commit(types.SET_MACROS_UI_FLAG, { isFetchingItem: false });
    }
  },
  create: async function createMacro({ commit }, macrosObj) {
    commit(types.SET_MACROS_UI_FLAG, { isCreating: true });
    try {
      const response = await MacrosAPI.create(macrosObj);
      commit(types.ADD_MACRO, response.data.payload);
      return response.data.payload;
    } catch (error) {
      throwErrorMessage(error);
      return null;
    } finally {
      commit(types.SET_MACROS_UI_FLAG, { isCreating: false });
    }
  },
  execute: async function executeMacro({ commit }, macrosObj) {
    commit(types.SET_MACROS_UI_FLAG, { isExecuting: true });
    try {
      await MacrosAPI.executeMacro(macrosObj);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_MACROS_UI_FLAG, { isExecuting: false });
    }
  },
  update: async ({ commit }, { id, ...updateObj }) => {
    commit(types.SET_MACROS_UI_FLAG, { isUpdating: true });
    try {
      const response = await MacrosAPI.update(id, updateObj);
      commit(types.EDIT_MACRO, response.data.payload);
      return response.data.payload;
    } catch (error) {
      throwErrorMessage(error);
      return null;
    } finally {
      commit(types.SET_MACROS_UI_FLAG, { isUpdating: false });
    }
  },
  delete: async ({ commit }, id) => {
    commit(types.SET_MACROS_UI_FLAG, { isDeleting: true });
    try {
      await MacrosAPI.delete(id);
      commit(types.DELETE_MACRO, id);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_MACROS_UI_FLAG, { isDeleting: false });
    }
  },
};

export const mutations = {
  [types.SET_MACROS_UI_FLAG]($state, data) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...data,
    };
  },
  [types.ADD_MACRO]: MutationHelpers.setSingleRecord,
  [types.SET_MACROS]: MutationHelpers.set,
  [types.EDIT_MACRO]: MutationHelpers.update,
  [types.DELETE_MACRO]: MutationHelpers.destroy,
  [types.SET_MACRO_SOURCE_MAPPINGS]($state, mappings) {
    $state.sourceMappings = mappings;
  },
  [types.UPDATE_MACRO_SOURCES]($state, { macroId, sourceChannelIds }) {
    $state.sourceMappings = {
      ...$state.sourceMappings,
      [macroId]: sourceChannelIds,
    };
  },
  [types.SET_MACRO_EXTRA_UUIDS]($state, uuids) {
    $state.extraUUIDs = uuids;
  },
  [types.UPDATE_MACRO_EXTRA_UUID]($state, { macroId, uuid }) {
    $state.extraUUIDs = {
      ...$state.extraUUIDs,
      [macroId]: uuid,
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
