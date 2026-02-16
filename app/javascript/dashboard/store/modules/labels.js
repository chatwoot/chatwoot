import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import LabelsAPI from '../../api/labels';
import AnalyticsHelper from '../../helper/AnalyticsHelper';
import { LABEL_EVENTS } from '../../helper/AnalyticsHelper/events';

export const state = {
  records: [],
  pinnedLabelIds: [],
  uiFlags: {
    isFetching: false,
    isFetchingItem: false,
    isCreating: false,
    isDeleting: false,
  },
};

export const getters = {
  getLabels(_state) {
    return _state.records;
  },
  getUIFlags(_state) {
    return _state.uiFlags;
  },
  getLabelsOnSidebar(_state) {
    const pinnedSet = new Set(_state.pinnedLabelIds);
    const pinned = [];
    const unpinned = [];

    _state.records
      .filter(record => record.show_on_sidebar)
      .forEach(label => {
        if (pinnedSet.has(label.id)) {
          pinned.push(label);
        } else {
          unpinned.push(label);
        }
      });

    return [
      ...pinned.sort((a, b) => a.title.localeCompare(b.title)),
      ...unpinned.sort((a, b) => a.title.localeCompare(b.title)),
    ];
  },
  isPinned: _state => labelId => {
    return _state.pinnedLabelIds.includes(labelId);
  },
  getLabelById: _state => id => {
    return _state.records.find(record => record.id === Number(id)) || {};
  },
};

export const actions = {
  revalidate: async function revalidate({ commit }, { newKey }) {
    try {
      const isExistingKeyValid = await LabelsAPI.validateCacheKey(newKey);
      if (!isExistingKeyValid) {
        const response = await LabelsAPI.refetchAndCommit(newKey);
        const labels = response.data.payload;
        commit(types.SET_LABELS, labels);

        const pinnedIds = labels
          .filter(label => label.pinned_by_current_user)
          .map(label => label.id);
        commit(types.SET_PINNED_LABELS, pinnedIds);
      }
    } catch (error) {
      // Ignore error
    }
  },

  togglePin: async function togglePin({ commit, state: _state }, labelId) {
    commit(types.SET_LABEL_UI_FLAG, { isPinning: true });
    try {
      const isPinned = _state.pinnedLabelIds.includes(labelId);

      if (isPinned) {
        await LabelsAPI.unpin(labelId);
        commit(types.UNPIN_LABEL, labelId);
      } else {
        await LabelsAPI.pin(labelId);
        commit(types.PIN_LABEL, labelId);
      }
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_LABEL_UI_FLAG, { isPinning: false });
    }
  },

  get: async function getLabels({ commit }) {
    commit(types.SET_LABEL_UI_FLAG, { isFetching: true });
    try {
      const response = await LabelsAPI.get(true);

      const sortedLabels = response.data.payload.sort((a, b) =>
        a.title.localeCompare(b.title)
      );
      commit(types.SET_LABELS, sortedLabels);

      const pinnedIds = sortedLabels
        .filter(label => label.pinned_by_current_user)
        .map(label => label.id);

      commit(types.SET_PINNED_LABELS, pinnedIds);
    } catch (error) {
      // Ignore error
    } finally {
      commit(types.SET_LABEL_UI_FLAG, { isFetching: false });
    }
  },

  create: async function createLabels({ commit }, cannedObj) {
    commit(types.SET_LABEL_UI_FLAG, { isCreating: true });
    try {
      const response = await LabelsAPI.create(cannedObj);
      AnalyticsHelper.track(LABEL_EVENTS.CREATE);
      commit(types.ADD_LABEL, response.data);
    } catch (error) {
      const errorMessage = error?.response?.data?.message;
      throw new Error(errorMessage);
    } finally {
      commit(types.SET_LABEL_UI_FLAG, { isCreating: false });
    }
  },

  update: async function updateLabels({ commit }, { id, ...updateObj }) {
    commit(types.SET_LABEL_UI_FLAG, { isUpdating: true });
    try {
      const response = await LabelsAPI.update(id, updateObj);
      AnalyticsHelper.track(LABEL_EVENTS.UPDATE);
      commit(types.EDIT_LABEL, response.data);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_LABEL_UI_FLAG, { isUpdating: false });
    }
  },

  delete: async function deleteLabels({ commit }, id) {
    commit(types.SET_LABEL_UI_FLAG, { isDeleting: true });
    try {
      await LabelsAPI.delete(id);
      AnalyticsHelper.track(LABEL_EVENTS.DELETED);
      commit(types.DELETE_LABEL, id);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_LABEL_UI_FLAG, { isDeleting: false });
    }
  },
};

export const mutations = {
  [types.SET_LABEL_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },
  [types.PIN_LABEL](_state, labelId) {
    if (!_state.pinnedLabelIds.includes(labelId)) {
      _state.pinnedLabelIds.push(labelId);
    }
  },

  [types.UNPIN_LABEL](_state, labelId) {
    const index = _state.pinnedLabelIds.indexOf(labelId);
    if (index > -1) {
      _state.pinnedLabelIds.splice(index, 1);
    }
  },

  [types.SET_PINNED_LABELS](_state, labelIds) {
    _state.pinnedLabelIds = labelIds;
  },
  [types.SET_LABELS]: MutationHelpers.set,
  [types.ADD_LABEL]: MutationHelpers.create,
  [types.EDIT_LABEL]: MutationHelpers.update,
  [types.DELETE_LABEL]: MutationHelpers.destroy,
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
