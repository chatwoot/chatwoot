import InboxBotMembers from '../../api/inboxBotMembers';

export const actions = {
  get(_, { inboxId }) {
    return InboxBotMembers.show(inboxId);
  },
  create(_, { inboxId, agentBotList }) {
    return InboxBotMembers.update({ inboxId, agentBotList });
  },
};

export default {
  namespaced: true,
  actions,
};
