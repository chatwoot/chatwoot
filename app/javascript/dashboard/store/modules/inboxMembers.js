import InboxMembersAPI from '../../api/inboxMembers';

export const actions = {
  get(_, { inboxId }) {
    return InboxMembersAPI.show(inboxId);
  },
  create(_, { inboxId, agentList, teamId }) {
    return InboxMembersAPI.update({ inboxId, agentList, teamId });
  },
};

export default {
  namespaced: true,
  actions,
};
