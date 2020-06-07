export const hasAssignee = ({ meta: { assignee } }) => !!assignee;
export const isAssignedToMe = (chat, userId) => {
  return hasAssignee(chat) && chat.meta.assignee.id === userId;
};

export const isAPrivateMessage = message => !!message.private;
export const isIncoming = message => message.message_type === 0;
export const isCreatedAfterLastAgentVisit = (message, lastSeen) =>
  message.created_at * 1000 > lastSeen * 1000;
export const canBeCountedForUnread = (message, conversation) =>
  isCreatedAfterLastAgentVisit(message, conversation.agent_last_seen_at) &&
  isIncoming(message) &&
  isAPrivateMessage(message);
