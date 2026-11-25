import types from '../mutation-types';
import GroupMembersAPI from '../../api/groupMembers';

// The roster belongs to the group, so it is shared: the same members whoever is looking.
// The meta does not. `inbox_phone_number`, `own_member_id` and `is_inbox_admin` answer
// "who are we in this group", and a group contact is account-scoped, so the same group
// can be open in two inboxes of one account with a different answer in each. Keyed by
// contact alone, whichever fetch or sync event landed last decided what the panel
// offered, for both of them.
const metaKey = (contactId, inboxId) => `${contactId}:${inboxId ?? ''}`;

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
  getGroupMembersMeta: _state => (contactId, inboxId) => {
    return _state.meta[metaKey(contactId, inboxId)] || {};
  },
  getUIFlags(_state) {
    return _state.uiFlags;
  },
};

export const actions = {
  setGroupMembers(
    { commit },
    { contactId, members, inboxPhoneNumber, ownMemberId, isInboxAdmin, inboxId }
  ) {
    commit(types.SET_GROUP_MEMBERS, { contactId, members });
    commit(types.SET_GROUP_MEMBERS_META, {
      contactId,
      inboxId,
      meta: {
        total_count: members.length,
        page: 1,
        per_page: members.length,
        inbox_phone_number: inboxPhoneNumber || null,
        // Which row is the connected account. Dropping it here is what made a sync event
        // undo what the fetch had established on a provider that names that account by
        // LID alone: no "You" badge, and its own demote and remove menu offered.
        own_member_id: ownMemberId ?? null,
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

  async fetch({ commit }, { contactId, page = 1, inboxId }) {
    const isFirstPage = page === 1;
    commit(
      types.SET_GROUP_MEMBERS_UI_FLAG,
      isFirstPage ? { isFetching: true } : { isFetchingMore: true }
    );
    try {
      const { data } = await GroupMembersAPI.getGroupMembers(
        contactId,
        inboxId,
        page
      );
      if (isFirstPage) {
        commit(types.SET_GROUP_MEMBERS, { contactId, members: data.payload });
      } else {
        commit(types.APPEND_GROUP_MEMBERS, {
          contactId,
          members: data.payload,
        });
      }
      commit(types.SET_GROUP_MEMBERS_META, {
        contactId,
        inboxId,
        meta: data.meta,
      });
    } finally {
      commit(
        types.SET_GROUP_MEMBERS_UI_FLAG,
        isFirstPage ? { isFetching: false } : { isFetchingMore: false }
      );
    }
  },

  async sync({ commit }, { contactId, inboxId }) {
    commit(types.SET_GROUP_MEMBERS_UI_FLAG, { isSyncing: true });
    try {
      await GroupMembersAPI.syncGroup(contactId, inboxId);
    } catch (error) {
      // fire-and-forget: sync runs in background, results arrive via ActionCable
    } finally {
      commit(types.SET_GROUP_MEMBERS_UI_FLAG, { isSyncing: false });
    }
  },

  async addMembers({ commit, dispatch }, { contactId, participants, inboxId }) {
    commit(types.SET_GROUP_MEMBERS_UI_FLAG, { isUpdating: true });
    try {
      await GroupMembersAPI.addMembers(contactId, participants, inboxId);
      await dispatch('fetch', { contactId, inboxId });
    } finally {
      commit(types.SET_GROUP_MEMBERS_UI_FLAG, { isUpdating: false });
    }
  },

  async removeMembers({ commit, dispatch }, { contactId, memberId, inboxId }) {
    commit(types.SET_GROUP_MEMBERS_UI_FLAG, { isUpdating: true });
    try {
      await GroupMembersAPI.removeMembers(contactId, memberId, inboxId);
      await dispatch('fetch', { contactId, inboxId });
    } finally {
      commit(types.SET_GROUP_MEMBERS_UI_FLAG, { isUpdating: false });
    }
  },

  async updateGroupMetadata({ commit }, { contactId, params, inboxId }) {
    commit(types.SET_GROUP_MEMBERS_UI_FLAG, { isUpdating: true });
    try {
      await GroupMembersAPI.updateGroupMetadata(contactId, params, inboxId);
    } finally {
      commit(types.SET_GROUP_MEMBERS_UI_FLAG, { isUpdating: false });
    }
  },

  async updateMemberRole(
    { commit, dispatch },
    { contactId, memberId, role, inboxId }
  ) {
    commit(types.SET_GROUP_MEMBERS_UI_FLAG, { isUpdating: true });
    try {
      await GroupMembersAPI.updateMemberRole(
        contactId,
        memberId,
        role,
        inboxId
      );
      await dispatch('fetch', { contactId, inboxId });
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

  [types.SET_GROUP_MEMBERS_META](_state, { contactId, inboxId, meta }) {
    _state.meta = {
      ..._state.meta,
      [metaKey(contactId, inboxId)]: meta,
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
