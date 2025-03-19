import InboxMembersAPI from '../../api/inboxMembers';

export const actions = {
  get(_, { inboxId }) {
    return InboxMembersAPI.show(inboxId);
  },
  create(_, { inboxId, agentList, allowedAgents = [] }) {
    return InboxMembersAPI.update({ inboxId, agentList, allowedAgents });
  },
};

export default {
  namespaced: true,
  actions,
};
