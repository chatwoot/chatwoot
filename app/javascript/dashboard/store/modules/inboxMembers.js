import InboxMembersAPI from '../../api/inboxMembers';

export const actions = {
  get(_, { inboxId }) {
    return InboxMembersAPI.show(inboxId);
  },
  create(_, { inboxId, agentList }) {
    return InboxMembersAPI.update({ inboxId, agentList });
  },
};

export default {
  namespaced: true,
  actions,
};
