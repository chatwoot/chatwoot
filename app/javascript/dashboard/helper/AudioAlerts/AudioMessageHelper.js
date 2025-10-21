export const getAssignee = message => message?.conversation?.assignee_id;
export const isConversationUnassigned = message => !getAssignee(message);
export const isConversationAssignedToMe = (message, currentUserId) =>
  getAssignee(message) === currentUserId;
export const isMessageFromCurrentUser = (message, currentUserId) =>
  message?.sender?.id === currentUserId;
