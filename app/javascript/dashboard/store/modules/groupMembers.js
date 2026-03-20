import types from '../mutation-types';
import GroupMembersAPI from '../../api/groupMembers';

export const state = {
  records: {},
  meta: {},
  uiFlags: {
    isFetching: false,
    isFetchingMore: false,
    isSyncing: false,
    isUpdating: false,
    isCreating: false,
  },
};

export const getters = {
  getGroupMembers: _state => contactId => {
    return _state.records[contactId] || [];
  },
  getGroupMembersMeta: _state => contactId => {
    return _state.meta[contactId] || {};
  },
  getUIFlags(_state) {
    return _state.uiFlags;
  },
};

export const actions = {
  setGroupMembers(
    { commit },
    { contactId, members, inboxPhoneNumber, isInboxAdmin }
  ) {
    commit(types.SET_GROUP_MEMBERS, { contactId, members });
    commit(types.SET_GROUP_MEMBERS_META, {
      contactId,
      meta: {
        total_count: members.length,
        page: 1,
        per_page: members.length,
        inbox_phone_number: inboxPhoneNumber || null,
        is_inbox_admin: isInboxAdmin ?? null,
      },
    });
  },

  async createGroup({ commit }, params) {
    commit(types.SET_GROUP_MEMBERS_UI_FLAG, { isCreating: true });
    try {
      const { data } = await GroupMembersAPI.createGroup(params);
      return data;
    } finally {
      commit(types.SET_GROUP_MEMBERS_UI_FLAG, { isCreating: false });
    }
  },

  async fetch({ commit }, { contactId, page = 1 }) {
    const isFirstPage = page === 1;
    commit(
      types.SET_GROUP_MEMBERS_UI_FLAG,
      isFirstPage ? { isFetching: true } : { isFetchingMore: true }
    );
    try {
      const { data } = await GroupMembersAPI.getGroupMembers(contactId, page);
      if (isFirstPage) {
        commit(types.SET_GROUP_MEMBERS, { contactId, members: data.payload });
      } else {
        commit(types.APPEND_GROUP_MEMBERS, {
          contactId,
          members: data.payload,
        });
      }
      commit(types.SET_GROUP_MEMBERS_META, { contactId, meta: data.meta });
    } finally {
      commit(
        types.SET_GROUP_MEMBERS_UI_FLAG,
        isFirstPage ? { isFetching: false } : { isFetchingMore: false }
      );
    }
  },

  async sync({ commit }, { contactId }) {
    commit(types.SET_GROUP_MEMBERS_UI_FLAG, { isSyncing: true });
    try {
      await GroupMembersAPI.syncGroup(contactId);
    } catch (error) {
      // fire-and-forget: sync runs in background, results arrive via ActionCable
    } finally {
      commit(types.SET_GROUP_MEMBERS_UI_FLAG, { isSyncing: false });
    }
  },

  async addMembers({ commit, dispatch }, { contactId, participants }) {
    commit(types.SET_GROUP_MEMBERS_UI_FLAG, { isUpdating: true });
    try {
      await GroupMembersAPI.addMembers(contactId, participants);
      await dispatch('fetch', { contactId });
    } finally {
      commit(types.SET_GROUP_MEMBERS_UI_FLAG, { isUpdating: false });
    }
  },

  async removeMembers({ commit, dispatch }, { contactId, memberId }) {
    commit(types.SET_GROUP_MEMBERS_UI_FLAG, { isUpdating: true });
    try {
      await GroupMembersAPI.removeMembers(contactId, memberId);
      await dispatch('fetch', { contactId });
    } finally {
      commit(types.SET_GROUP_MEMBERS_UI_FLAG, { isUpdating: false });
    }
  },

  async updateGroupMetadata({ commit }, { contactId, params }) {
    commit(types.SET_GROUP_MEMBERS_UI_FLAG, { isUpdating: true });
    try {
      await GroupMembersAPI.updateGroupMetadata(contactId, params);
    } finally {
      commit(types.SET_GROUP_MEMBERS_UI_FLAG, { isUpdating: false });
    }
  },

  async updateMemberRole({ commit, dispatch }, { contactId, memberId, role }) {
    commit(types.SET_GROUP_MEMBERS_UI_FLAG, { isUpdating: true });
    try {
      await GroupMembersAPI.updateMemberRole(contactId, memberId, role);
      await dispatch('fetch', { contactId });
    } finally {
      commit(types.SET_GROUP_MEMBERS_UI_FLAG, { isUpdating: false });
    }
  },
};

export const mutations = {
  [types.SET_GROUP_MEMBERS_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },

  [types.SET_GROUP_MEMBERS](_state, { contactId, members }) {
    _state.records = {
      ..._state.records,
      [contactId]: members,
    };
  },

  [types.APPEND_GROUP_MEMBERS](_state, { contactId, members }) {
    const existing = _state.records[contactId] || [];
    _state.records = {
      ..._state.records,
      [contactId]: [...existing, ...members],
    };
  },

  [types.SET_GROUP_MEMBERS_META](_state, { contactId, meta }) {
    _state.meta = {
      ..._state.meta,
      [contactId]: meta,
    };
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
