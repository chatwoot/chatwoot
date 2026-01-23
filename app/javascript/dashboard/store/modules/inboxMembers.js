import InboxMembersAPI from '../../api/inboxMembers';

export const state = {
  records: {}, // { inboxId: [{ id, name, email, assignment_eligible, ... }] }
};

export const getters = {
  getMembersByInboxId: _state => inboxId => {
    return _state.records[inboxId] || [];
  },
  isCurrentUserAssignmentEligible: _state => (inboxId, currentUserId) => {
    const members = _state.records[inboxId] || [];
    const currentUserMember = members.find(
      member => member.id === currentUserId
    );
    // If user is not a member or assignment_eligible is not set, default to true
    if (!currentUserMember) {
      return true;
    }
    return currentUserMember.assignment_eligible !== false;
  },
};

export const mutations = {
  SET_INBOX_MEMBERS(_state, { inboxId, members }) {
    _state.records = {
      ..._state.records,
      [inboxId]: members,
    };
  },
};

export const actions = {
  async get({ commit }, { inboxId }) {
    const response = await InboxMembersAPI.show(inboxId);
    const {
      data: { payload: members },
    } = response;
    commit('SET_INBOX_MEMBERS', { inboxId, members });
    return response;
  },
  async create({ commit }, { inboxId, agentList }) {
    const response = await InboxMembersAPI.update({ inboxId, agentList });
    const {
      data: { payload: members },
    } = response;
    commit('SET_INBOX_MEMBERS', { inboxId, members });
    return response;
  },
};

export default {
  namespaced: true,
  state,
  getters,
  mutations,
  actions,
};
